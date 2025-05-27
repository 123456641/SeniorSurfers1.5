import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../tutorial/pdf_viewer_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddTutorialPage extends StatefulWidget {
  const AddTutorialPage({super.key});

  @override
  State<AddTutorialPage> createState() => _AddTutorialPageState();
}

class _AddTutorialPageState extends State<AddTutorialPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorialFiles = [];
  bool isLoading = true;
  bool isUploading = false;
  String? selectedPlatform;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _fileDescriptionController =
      TextEditingController();

  // File upload related variables
  PlatformFile? _selectedFileInfo;
  String? _fileName;
  bool isPreviewingFile = false;

  // Thumbnail image related variables
  PlatformFile? _selectedThumbnailInfo;
  String? _thumbnailName;
  String? _thumbnailUrl;
  bool isUploadingThumbnail = false;

  // Flutter Local Notifications instance
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  String _formatPlatformName(String platform) {
    return platform
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    fetchTutorialFiles();
  }

  // Initialize Flutter Local Notifications
  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // Request permissions for iOS
    if (!kIsWeb && Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _fileDescriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchTutorialFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all files from tutorial_files table
      final files = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false);

      setState(() {
        tutorialFiles = List<Map<String, dynamic>>.from(files);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tutorials: $e')));
      }
    }
  }

  Future<void> _addNewTutorial() async {
    if (selectedPlatform == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title and select a platform'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      isUploading = true;
    });

    try {
      // Upload thumbnail if selected
      if (_selectedThumbnailInfo != null) {
        await _uploadThumbnail();
      }

      // If we have a selected file, upload it
      if (_selectedFileInfo != null) {
        await _uploadFile();
      } else if (_linkController.text.isNotEmpty) {
        // If no file, just create an entry in tutorial_files with link
        await _supabase.from('tutorial_files').insert({
          'file_name': _titleController.text,
          'file_type': 'link',
          'file_size': 0,
          'file_url': _linkController.text,
          'description': _fileDescriptionController.text,
          'platform': selectedPlatform,
          'uploaded_at': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
          'thumbnail_url': _thumbnailUrl,
          'title': _titleController.text,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide either a file or a link'),
          ),
        );
        setState(() {
          isLoading = false;
          isUploading = false;
        });
        return;
      }

      // Create notification
      final String notificationTitle = 'New Tutorial Available';
      final String notificationBody =
          _selectedFileInfo != null
              ? 'A new tutorial "${_titleController.text}" has been uploaded with file "${_selectedFileInfo!.name}".'
              : 'A new tutorial "${_titleController.text}" has been added.';

      // Send local notification
      await _sendNotification(notificationTitle, notificationBody);

      // Save to database for all users to see
      await _saveNotificationToDatabase(notificationTitle, notificationBody);

      _titleController.clear();
      _linkController.clear();

      setState(() {
        selectedPlatform = null;
        _selectedFileInfo = null;
        _fileName = null;
        _selectedThumbnailInfo = null;
        _thumbnailName = null;
        _thumbnailUrl = null;
        isUploading = false;
        isLoading = false;
        isPreviewingFile = false;
      });

      _fileDescriptionController.clear();

      await fetchTutorialFiles(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial added successfully')),
        );
      }
    } catch (e) {
      print('Error adding tutorial: $e');
      setState(() {
        isLoading = false;
        isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding tutorial: $e')));
      }
    }
  }

  // Function to pick files directly from the device
  Future<void> _pickFile() async {
    if (!mounted) return;

    try {
      // Wait for the next frame to ensure the widget is fully built
      await Future.delayed(Duration.zero);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        withData: true, // Important for web and handling file data directly
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _selectedFileInfo = result.files.first;
          _fileName = _selectedFileInfo!.name;
          isPreviewingFile = false; // Reset preview state
        });

        print('Selected file: ${_selectedFileInfo!.name}');
        print('File size: ${_selectedFileInfo!.size} bytes');

        // Don't try to log the path on web as it will be null
        if (!kIsWeb && _selectedFileInfo!.path != null) {
          print('File path: ${_selectedFileInfo!.path}');
        } else if (kIsWeb) {
          print(
            'Running on web platform - path is null, bytes available: ${_selectedFileInfo!.bytes != null}',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: ${_selectedFileInfo!.name}')),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File picking error: $e')));
      }
    }
  }

  // Function to preview the selected file
  Future<void> _previewFile() async {
    if (_selectedFileInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected to preview')),
      );
      return;
    }

    try {
      setState(() {
        isPreviewingFile = true;
      });

      // For PDF preview on web
      if (kIsWeb &&
          _selectedFileInfo!.extension?.toLowerCase() == 'pdf' &&
          _selectedFileInfo!.bytes != null) {
        final blobUrl =
            Uri.dataFromBytes(
              _selectedFileInfo!.bytes!,
              mimeType: 'application/pdf',
            ).toString();

        await launchUrl(Uri.parse(blobUrl));
      }
      // For native platforms (if file is a PDF)
      else if (!kIsWeb &&
          _selectedFileInfo!.path != null &&
          _selectedFileInfo!.extension?.toLowerCase() == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PDFViewerPage(
                  title: _selectedFileInfo!.name,
                  fileUrl: _selectedFileInfo!.path!,
                  requiresAuth: false,
                ),
          ),
        );
      }
      // For other file types or when PDF viewing is not possible
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preview not available for ${_selectedFileInfo!.extension} files or on this platform.',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error previewing file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error previewing file: $e')));
    } finally {
      setState(() {
        isPreviewingFile = false;
      });
    }
  }

  // Function to pick thumbnail image
  Future<void> _pickThumbnail() async {
    if (!mounted) return;

    try {
      await Future.delayed(Duration.zero);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _selectedThumbnailInfo = result.files.first;
          _thumbnailName = _selectedThumbnailInfo!.name;
        });

        print('Selected thumbnail: ${_selectedThumbnailInfo!.name}');
        print('Thumbnail size: ${_selectedThumbnailInfo!.size} bytes');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thumbnail selected: ${_selectedThumbnailInfo!.name}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking thumbnail: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thumbnail picking error: $e')));
      }
    }
  }

  // Function to upload thumbnail to Supabase storage
  Future<void> _uploadThumbnail() async {
    if (_selectedThumbnailInfo == null) {
      print('No thumbnail selected');
      return;
    }

    setState(() {
      isUploadingThumbnail = true;
    });

    try {
      final fileExtension =
          _selectedThumbnailInfo!.name.split('.').last.toLowerCase();
      final fileName =
          'thumbnail_${DateTime.now().millisecondsSinceEpoch}_${_selectedThumbnailInfo!.name}';
      final filePath = 'tutorial-thumbnails/$fileName';

      print('Starting upload of thumbnail: ${_selectedThumbnailInfo!.name}');
      print('Uploading thumbnail to: $filePath');

      // Determine proper content type based on file extension
      String contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      String uploadResponse;

      // Upload logic based on platform
      if (kIsWeb) {
        // Web platform - always use bytes
        if (_selectedThumbnailInfo!.bytes != null) {
          uploadResponse = await _supabase.storage
              .from('tutorial-thumbnails')
              .uploadBinary(
                filePath,
                _selectedThumbnailInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception('Thumbnail bytes are null for web upload');
        }
      } else {
        // Native platforms - try path first, fallback to bytes
        if (_selectedThumbnailInfo!.path != null) {
          final file = File(_selectedThumbnailInfo!.path!);
          if (await file.exists()) {
            uploadResponse = await _supabase.storage
                .from('tutorial-thumbnails')
                .upload(
                  filePath,
                  file,
                  fileOptions: FileOptions(
                    contentType: contentType,
                    upsert: true,
                  ),
                );
          } else {
            throw Exception(
              'Thumbnail file does not exist at the specified path',
            );
          }
        } else if (_selectedThumbnailInfo!.bytes != null) {
          // Fallback to bytes if path is not available
          uploadResponse = await _supabase.storage
              .from('tutorial-thumbnails')
              .uploadBinary(
                filePath,
                _selectedThumbnailInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception(
            'Neither thumbnail path nor bytes are available for upload',
          );
        }
      }

      print('Thumbnail upload response: $uploadResponse');

      // Get the public URL for the uploaded thumbnail
      _thumbnailUrl = _supabase.storage
          .from('tutorial-thumbnails')
          .getPublicUrl(filePath);

      print('Thumbnail uploaded successfully. URL: $_thumbnailUrl');

      setState(() {
        isUploadingThumbnail = false;
      });
    } catch (e) {
      print('Error during thumbnail upload: $e');
      setState(() {
        isUploadingThumbnail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading thumbnail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to upload file to Supabase storage
  Future<void> _uploadFile() async {
    if (_selectedFileInfo == null) {
      print('No file selected');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final fileExtension = _selectedFileInfo!.name.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFileInfo!.name}';
      final filePath = 'tutorial-files/$fileName';

      print('Starting upload of file: ${_selectedFileInfo!.name}');
      print('Uploading file to: $filePath');
      print('File size: ${_selectedFileInfo!.size} bytes');

      // For larger files, show progress
      if (_selectedFileInfo!.size > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading large file, please wait...')),
        );
      }

      // Determine proper content type based on file extension
      String contentType;
      switch (fileExtension.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        case 'pptx':
          contentType =
              'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      String uploadResponse;

      // Simplified upload logic - use bytes for web, path for native platforms when available
      if (kIsWeb) {
        // Web platform - always use bytes
        if (_selectedFileInfo!.bytes != null) {
          uploadResponse = await _supabase.storage
              .from('tutorial-files')
              .uploadBinary(
                filePath,
                _selectedFileInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception('File bytes are null for web upload');
        }
      } else {
        // Native platforms - try path first, fallback to bytes
        if (_selectedFileInfo!.path != null) {
          final file = File(_selectedFileInfo!.path!);
          if (await file.exists()) {
            uploadResponse = await _supabase.storage
                .from('tutorial-files')
                .upload(
                  filePath,
                  file,
                  fileOptions: FileOptions(
                    contentType: contentType,
                    upsert: true,
                  ),
                );
          } else {
            throw Exception('File does not exist at the specified path');
          }
        } else if (_selectedFileInfo!.bytes != null) {
          // Fallback to bytes if path is not available
          uploadResponse = await _supabase.storage
              .from('tutorial-files')
              .uploadBinary(
                filePath,
                _selectedFileInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception(
            'Neither file path nor bytes are available for upload',
          );
        }
      }

      print('Upload response: $uploadResponse');

      // Get the public URL for the uploaded file
      final fileUrl = _supabase.storage
          .from('tutorial-files')
          .getPublicUrl(filePath);

      print('File uploaded successfully. URL: $fileUrl');

      // Create an entry in the tutorial_files table to track the file
      await _supabase.from('tutorial_files').insert({
        'file_name': _selectedFileInfo!.name,
        'file_type': fileExtension,
        'file_size': _selectedFileInfo!.size,
        'file_path': filePath,
        'file_url': fileUrl,
        'description': _fileDescriptionController.text,
        'title':
            _titleController.text.isEmpty
                ? _selectedFileInfo!.name
                : _titleController.text,
        'platform': selectedPlatform,
        'uploaded_at': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
        'thumbnail_url': _thumbnailUrl, // Add the thumbnail URL
      });

      setState(() {
        isUploading = false;
        _selectedFileInfo = null;
        _fileName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error during file upload: $e');
      setState(() {
        isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add file directly without creating a tutorial
  Future<void> _addFileOnly() async {
    if (_selectedFileInfo == null || selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and platform')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      isUploading = true;
    });

    try {
      // Upload thumbnail if selected
      if (_selectedThumbnailInfo != null) {
        await _uploadThumbnail();
      }

      // Upload file directly to tutorial_files table
      await _uploadFile();

      // After successful upload, create notification
      final String notificationTitle = 'New File Available';
      final String notificationBody =
          'A new file "${_selectedFileInfo!.name}" has been uploaded.';

      // Send local notification
      await _sendNotification(notificationTitle, notificationBody);

      // Save to database for all users to see
      await _saveNotificationToDatabase(notificationTitle, notificationBody);

      _titleController.clear();
      setState(() {
        selectedPlatform = null;
        _selectedFileInfo = null;
        _fileName = null;
        _selectedThumbnailInfo = null;
        _thumbnailName = null;
        _thumbnailUrl = null;
        isLoading = false;
        isUploading = false;
        isPreviewingFile = false;
      });
      _fileDescriptionController.clear();

      fetchTutorialFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    }
  }

  void _showPlatformSelectionDialog() {
    // Make a local copy to avoid state issues
    String? currentSelection = selectedPlatform;

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Platform'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Google Meet'),
                      leading: Radio<String>(
                        value: 'google_meet',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'google_meet');
                      },
                    ),
                    ListTile(
                      title: const Text('Zoom'),
                      leading: Radio<String>(
                        value: 'zoom',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'zoom');
                      },
                    ),
                    ListTile(
                      title: const Text('Gmail'),
                      leading: Radio<String>(
                        value: 'gmail',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'gmail');
                      },
                    ),
                    ListTile(
                      title: const Text('Viber'),
                      leading: Radio<String>(
                        value: 'viber',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'viber');
                      },
                    ),
                    ListTile(
                      title: const Text('WhatsApp'),
                      leading: Radio<String>(
                        value: 'whatsapp',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'whatsapp');
                      },
                    ),
                    ListTile(
                      title: const Text('Cliqq'),
                      leading: Radio<String>(
                        value: 'cliqq',
                        groupValue: currentSelection,
                        onChanged: (value) {
                          setStateDialog(() => currentSelection = value);
                        },
                      ),
                      onTap: () {
                        setStateDialog(() => currentSelection = 'cliqq');
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(currentSelection);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((selectedValue) {
      if (selectedValue != null) {
        setState(() {
          selectedPlatform = selectedValue;
        });
      }
    });
  }

  Widget _buildPlatformOption(String name, String value) {
    return ListTile(
      title: Text(name),
      selected: selectedPlatform == value,
      leading:
          selectedPlatform == value
              ? const Icon(Icons.check_circle, color: Color(0xFF3B6EA5))
              : const Icon(Icons.circle_outlined),
      onTap: () {
        setState(() {
          selectedPlatform = value;
        });
        Navigator.of(context).pop();
      },
    );
  }

  // Open a file URL in browser
  Future<void> _openFileURL(
    String url, [
    String? fileType,
    String? title,
  ]) async {
    // Try to determine file type from URL if not provided
    fileType ??= url.toLowerCase().endsWith('.pdf') ? 'pdf' : null;

    // Default title if null - Added fix for nullable title
    final String safeTitle = title ?? 'File Viewer';

    try {
      // Handle PDFs with the internal viewer
      if (fileType == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PDFViewerPage(
                  title: safeTitle,
                  fileUrl: url,
                  requiresAuth: false,
                ),
          ),
        );
      } else {
        // For other files, open in external application
        if (!await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: $url')),
            );
          }
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  // Delete file from storage and database
  Future<void> _deleteFile(Map<String, dynamic> file) async {
    try {
      // Delete from storage if it's an actual file (not just a link)
      if (file['file_path'] != null && file['file_type'] != 'link') {
        await _supabase.storage.from('tutorial-files').remove([
          file['file_path'],
        ]);
      }

      // Delete thumbnail if exists
      if (file['thumbnail_url'] != null) {
        final thumbnailPath =
            file['thumbnail_url'].toString().split('tutorial-thumbnails/').last;
        if (thumbnailPath.isNotEmpty) {
          try {
            await _supabase.storage.from('tutorial-thumbnails').remove([
              thumbnailPath,
            ]);
            print('Thumbnail deleted: $thumbnailPath');
          } catch (e) {
            print('Error deleting thumbnail: $e');
          }
        }
      }

      // Delete from database
      await _supabase.from('tutorial_files').delete().eq('id', file['id']);

      fetchTutorialFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Ghost white color
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            isLoading &&
                    tutorialFiles
                        .isEmpty // Only show loading if actually loading initial data
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          'Add Tutorial or File',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27445D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tutorial Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _showPlatformSelectionDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: const Color(0xFF3B6EA5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.devices, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              selectedPlatform != null
                                  ? 'Platform: ${_formatPlatformName(selectedPlatform!)}'
                                  : 'Select Platform',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tutorial Thumbnail Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickThumbnail,
                              icon: const Icon(Icons.image),
                              label: Text(
                                _thumbnailName ??
                                    'Select Thumbnail Image (JPG, PNG)',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedThumbnailInfo != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: const Color(0xFFEBF2FA),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(
                              color: Color(0xFF3B6EA5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      color: Color(0xFF3B6EA5),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected Thumbnail: ${_selectedThumbnailInfo!.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selectedThumbnailInfo = null;
                                          _thumbnailName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Size: ${_formatFileSize(_selectedThumbnailInfo!.size)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                if (_selectedThumbnailInfo != null &&
                                    _selectedThumbnailInfo!.bytes != null &&
                                    kIsWeb) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _selectedThumbnailInfo!.bytes!,
                                      height: 150,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Tutorial File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.file_upload),
                              label: Text(
                                _fileName ?? 'Select File (PDF, PPT, DOC)',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          if (_selectedFileInfo != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFileInfo = null;
                                  _fileName = null;
                                });
                              },
                              tooltip: 'Remove File',
                            ),
                          ],
                        ],
                      ),
                      if (_selectedFileInfo != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: const Color(0xFFEBF2FA),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(
                              color: Color(0xFF3B6EA5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _getFileIcon(_selectedFileInfo!.extension),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected File: ${_selectedFileInfo!.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Type: ${_selectedFileInfo!.extension?.toUpperCase() ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${_formatFileSize(_selectedFileInfo!.size)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _fileDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'File Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : _addNewTutorial,
                        icon:
                            isUploading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.add),
                        label: Text(
                          isUploading ? 'Uploading...' : 'Add Tutorial',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: const Color(0xFF2A9D8F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Existing Tutorials & Files',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27445D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTutorialFilesList(),
                    ],
                  ),
                ),
      ),
    );
  }

  // Helper method to get the appropriate icon for file type
  Widget _getFileIcon(String? extension) {
    IconData iconData;
    Color iconColor;

    switch (extension?.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'ppt':
      case 'pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 28);
  }

  // Format file size to human-readable
  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Build the list of existing tutorial files
  Widget _buildTutorialFilesList() {
    if (tutorialFiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No tutorials or files available. Upload one now!',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tutorialFiles.length,
      itemBuilder: (context, index) {
        final file = tutorialFiles[index];
        final bool isLink = file['file_type'] == 'link';
        final String title = file['title'] ?? file['file_name'] ?? 'Untitled';
        final String description = file['description'] ?? 'No description';
        final String platform = file['platform'] ?? 'Unknown Platform';
        final String date = DateTime.parse(
          file['uploaded_at'],
        ).toLocal().toString().substring(0, 10);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              if (isLink) {
                launchUrl(Uri.parse(file['file_url']));
              } else {
                _openFileURL(file['file_url'], file['file_type'], title);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Thumbnail or Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD1E3F8),
                        width: 1,
                      ),
                    ),
                    child:
                        file['thumbnail_url'] != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                file['thumbnail_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _getTutorialIcon(platform);
                                },
                              ),
                            )
                            : _getTutorialIcon(platform),
                  ),
                  const SizedBox(width: 16),
                  // Middle: Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27445D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                platform.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFF3B6EA5),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (!isLink) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatFileSize(file['file_size'] ?? 0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: Actions
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmationDialog(file),
                        tooltip: 'Delete',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Color(0xFF3B6EA5),
                        ),
                        onPressed: () {
                          if (isLink) {
                            launchUrl(Uri.parse(file['file_url']));
                          } else {
                            _openFileURL(
                              file['file_url'],
                              file['file_type'],
                              title,
                            );
                          }
                        },
                        tooltip: 'Open',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Get icon for tutorial platform
  Widget _getTutorialIcon(String platform) {
    IconData iconData;
    Color iconColor;

    switch (platform.toLowerCase()) {
      case 'google_meet':
        iconData = Icons.video_call;
        iconColor = Colors.green;
        break;
      case 'zoom':
        iconData = Icons.videocam;
        iconColor = Colors.blue;
        break;
      case 'gmail':
        iconData = Icons.email;
        iconColor = Colors.red;
        break;
      case 'viber':
        iconData = Icons.chat;
        iconColor = Colors.purple;
        break;
      case 'whatsapp':
        iconData = Icons.phone;
        iconColor = Colors.green;
        break;
      case 'cliqq':
        iconData = Icons.message;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.help;
        iconColor = Colors.grey;
    }

    return Center(child: Icon(iconData, color: iconColor, size: 40));
  }

  // Show confirmation dialog before deleting
  void _showDeleteConfirmationDialog(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tutorial File'),
          content: Text(
            'Are you sure you want to delete "${file['title'] ?? file['file_name']}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFile(file);
              },
            ),
          ],
        );
      },
    );
  }

  // Send local notification using Flutter Local Notifications
  Future<void> _sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'tutorial_channel',
          'Tutorial Notifications',
          channelDescription: 'Notification channel for tutorial uploads',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'tutorial_notification',
    );
  }

  // Save notification to database for all users
  Future<void> _saveNotificationToDatabase(String title, String message) async {
    try {
      await _supabase.from('notifications').insert({
        'title': title,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
        'is_read': false,
        'notification_type': 'tutorial_update',
      });
    } catch (e) {
      print('Error saving notification to database: $e');
    }
  }
}
