import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddTutorialPage extends StatefulWidget {
  const AddTutorialPage({super.key});

  @override
  State<AddTutorialPage> createState() => _AddTutorialPageState();
}

class _AddTutorialPageState extends State<AddTutorialPage> {
  final _supabase = Supabase.instance.client;

  // Tutorial metadata
  final TextEditingController _tutorialTitleController =
      TextEditingController();
  final TextEditingController _tutorialDescriptionController =
      TextEditingController();
  String? selectedPlatform;
  PlatformFile? _tutorialThumbnailInfo;

  // Tutorial steps
  List<TutorialStepData> tutorialSteps = [];

  // UI state
  bool isLoading = false;
  bool isUploading = false;

  // Notifications
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    // Start with one empty step
    _addNewStep();
  }

  @override
  void dispose() {
    _tutorialTitleController.dispose();
    _tutorialDescriptionController.dispose();
    for (var step in tutorialSteps) {
      step.dispose();
    }
    super.dispose();
  }

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

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions
    if (!kIsWeb && Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (!kIsWeb && Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _addNewStep() {
    setState(() {
      tutorialSteps.add(TutorialStepData());
    });
  }

  void _removeStep(int index) {
    if (tutorialSteps.length > 1) {
      setState(() {
        tutorialSteps[index].dispose();
        tutorialSteps.removeAt(index);
      });
    }
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final step = tutorialSteps.removeAt(oldIndex);
      tutorialSteps.insert(newIndex, step);
    });
  }

  Future<void> _uploadTutorial() async {
    // Validation
    if (_tutorialTitleController.text.trim().isEmpty ||
        selectedPlatform == null) {
      _showErrorDialog(
        'Please provide a tutorial title and select a platform.',
      );
      return;
    }

    if (tutorialSteps.isEmpty || tutorialSteps.any((step) => !step.isValid())) {
      _showErrorDialog(
        'Please ensure all tutorial steps have title, description, and content.',
      );
      return;
    }

    setState(() {
      isUploading = true;
      isLoading = true;
    });

    try {
      // Upload tutorial thumbnail if provided
      String? tutorialThumbnailUrl;
      if (_tutorialThumbnailInfo != null) {
        tutorialThumbnailUrl = await _uploadFile(
          _tutorialThumbnailInfo!,
          'tutorial-thumbnails',
        );
      }

      // Upload step videos and prepare step data
      List<Map<String, dynamic>> stepDataList = [];

      for (int i = 0; i < tutorialSteps.length; i++) {
        final step = tutorialSteps[i];

        // Upload step video if provided
        String? stepVideoUrl;
        if (step.videoFile != null) {
          stepVideoUrl = await _uploadFile(
            step.videoFile!,
            'tutorial-step-videos',
          );
        }

        stepDataList.add({
          'step_number': i + 1,
          'title': step.titleController.text.trim(),
          'description': step.descriptionController.text.trim(),
          'content': step.contentController.text.trim(),
          'icon_name': step.selectedIcon,
          'color_value': step.selectedColor.value,
          'video_url': stepVideoUrl,
          'helpful_tip': step.helpfulTipController.text.trim(),
        });
      }

      // Create tutorial record in database
      final tutorialResponse =
          await _supabase
              .from('tutorials')
              .insert({
                'title': _tutorialTitleController.text.trim(),
                'description': _tutorialDescriptionController.text.trim(),
                'platform': selectedPlatform,
                'thumbnail_url': tutorialThumbnailUrl,
                'created_at': DateTime.now().toIso8601String(),
                'created_by': _supabase.auth.currentUser?.id,
                'is_active': true,
                'total_steps': tutorialSteps.length,
              })
              .select()
              .single();

      final tutorialId = tutorialResponse['id'];

      // Insert tutorial steps
      for (var stepData in stepDataList) {
        stepData['tutorial_id'] = tutorialId;
        await _supabase.from('tutorial_steps').insert(stepData);
      }

      // Send notification
      await _sendNotification(
        'New Tutorial Published',
        'A new tutorial "${_tutorialTitleController.text.trim()}" is now available!',
      );

      // Save notification to database
      await _saveNotificationToDatabase(
        'New Tutorial Published',
        'A new tutorial "${_tutorialTitleController.text.trim()}" is now available!',
      );

      _showSuccessDialog('Tutorial uploaded successfully!');
      _clearForm();
    } catch (e) {
      print('Error uploading tutorial: $e');
      _showErrorDialog('Error uploading tutorial: ${e.toString()}');
    } finally {
      setState(() {
        isUploading = false;
        isLoading = false;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String bucketPath) async {
    try {
      final fileExtension = file.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$bucketPath/$fileName';

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
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mov':
          contentType = 'video/quicktime';
          break;
        case 'avi':
          contentType = 'video/x-msvideo';
          break;
        case 'mkv':
          contentType = 'video/x-matroska';
          break;
        case 'webm':
          contentType = 'video/webm';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      if (kIsWeb) {
        if (file.bytes != null) {
          await _supabase.storage
              .from(bucketPath)
              .uploadBinary(
                filePath,
                file.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception('File bytes are null for web upload');
        }
      } else {
        if (file.path != null) {
          final fileObj = File(file.path!);
          if (await fileObj.exists()) {
            await _supabase.storage
                .from(bucketPath)
                .upload(
                  filePath,
                  fileObj,
                  fileOptions: FileOptions(
                    contentType: contentType,
                    upsert: true,
                  ),
                );
          } else {
            throw Exception('File does not exist at the specified path');
          }
        } else if (file.bytes != null) {
          await _supabase.storage
              .from(bucketPath)
              .uploadBinary(
                filePath,
                file.bytes!,
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

      return _supabase.storage.from(bucketPath).getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  Future<void> _pickTutorialThumbnail() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _tutorialThumbnailInfo = result.files.first;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking thumbnail: ${e.toString()}');
    }
  }

  Future<void> _pickStepVideo(int stepIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          tutorialSteps[stepIndex].videoFile = result.files.first;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking video: ${e.toString()}');
    }
  }

  void _showPlatformSelectionDialog() {
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
                    _buildPlatformRadio(
                      'Google Meet',
                      'google_meet',
                      currentSelection,
                      setStateDialog,
                    ),
                    _buildPlatformRadio(
                      'Zoom',
                      'zoom',
                      currentSelection,
                      setStateDialog,
                    ),
                    _buildPlatformRadio(
                      'Gmail',
                      'gmail',
                      currentSelection,
                      setStateDialog,
                    ),
                    _buildPlatformRadio(
                      'Viber',
                      'viber',
                      currentSelection,
                      setStateDialog,
                    ),
                    _buildPlatformRadio(
                      'WhatsApp',
                      'whatsapp',
                      currentSelection,
                      setStateDialog,
                    ),
                    _buildPlatformRadio(
                      'Cliqq',
                      'cliqq',
                      currentSelection,
                      setStateDialog,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text('Confirm'),
                  onPressed:
                      () => Navigator.of(dialogContext).pop(currentSelection),
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

  Widget _buildPlatformRadio(
    String name,
    String value,
    String? currentSelection,
    StateSetter setStateDialog,
  ) {
    return ListTile(
      title: Text(name),
      leading: Radio<String>(
        value: value,
        groupValue: currentSelection,
        onChanged: (newValue) {
          setStateDialog(() => currentSelection = newValue);
        },
      ),
      onTap: () {
        setStateDialog(() => currentSelection = value);
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _clearForm() {
    _tutorialTitleController.clear();
    _tutorialDescriptionController.clear();
    setState(() {
      selectedPlatform = null;
      _tutorialThumbnailInfo = null;
      tutorialSteps.clear();
    });
    _addNewStep();
  }

  Future<void> _sendNotification(String title, String body) async {
    try {
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
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

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

  String _formatPlatformName(String platform) {
    return platform
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: const Text('Admin Tutorial Uploader'),
        backgroundColor: const Color(0xFF3B6EA5),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTutorialMetadataSection(),
                    const SizedBox(height: 32),
                    _buildTutorialStepsSection(),
                    const SizedBox(height: 32),
                    _buildUploadButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTutorialMetadataSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tutorial Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tutorialTitleController,
              decoration: const InputDecoration(
                labelText: 'Tutorial Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tutorialDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Tutorial Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showPlatformSelectionDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF3B6EA5),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.devices),
              label: Text(
                selectedPlatform != null
                    ? 'Platform: ${_formatPlatformName(selectedPlatform!)}'
                    : 'Select Platform',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTutorialThumbnail,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _tutorialThumbnailInfo?.name ??
                          'Select Tutorial Thumbnail (Optional)',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (_tutorialThumbnailInfo != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _tutorialThumbnailInfo = null;
                      });
                    },
                    tooltip: 'Remove Thumbnail',
                  ),
                ],
              ],
            ),
            if (_tutorialThumbnailInfo != null &&
                _tutorialThumbnailInfo!.bytes != null &&
                kIsWeb) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _tutorialThumbnailInfo!.bytes!,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStepsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tutorial Steps',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF27445D),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tutorialSteps.length,
              onReorder: _reorderSteps,
              itemBuilder: (context, index) {
                return TutorialStepCard(
                  key: ValueKey(tutorialSteps[index].id),
                  stepData: tutorialSteps[index],
                  stepNumber: index + 1,
                  onRemove:
                      tutorialSteps.length > 1
                          ? () => _removeStep(index)
                          : null,
                  onVideoPick: () => _pickStepVideo(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isUploading ? null : _uploadTutorial,
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
                : const Icon(Icons.upload),
        label: Text(
          isUploading ? 'Uploading Tutorial...' : 'Upload Tutorial',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: const Color(0xFF2A9D8F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// FIXED: Simple and robust ID generation
class TutorialStepData {
  static int _counter = 0;
  late final String id;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController helpfulTipController = TextEditingController();

  String selectedIcon = 'Icons.info';
  Color selectedColor = Colors.blue;
  PlatformFile? videoFile;

  TutorialStepData() {
    _counter++;
    id = 'step_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  bool isValid() {
    return titleController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        contentController.text.trim().isNotEmpty;
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    contentController.dispose();
    helpfulTipController.dispose();
  }
}

class TutorialStepCard extends StatefulWidget {
  final TutorialStepData stepData;
  final int stepNumber;
  final VoidCallback? onRemove;
  final VoidCallback onVideoPick;

  const TutorialStepCard({
    Key? key,
    required this.stepData,
    required this.stepNumber,
    this.onRemove,
    required this.onVideoPick,
  }) : super(key: key);

  @override
  State<TutorialStepCard> createState() => _TutorialStepCardState();
}

class _TutorialStepCardState extends State<TutorialStepCard> {
  bool isExpanded = false;

  final List<IconData> availableIcons = [
    Icons.info,
    Icons.waving_hand,
    Icons.store,
    Icons.search,
    Icons.download,
    Icons.videocam,
    Icons.celebration,
    Icons.lightbulb,
    Icons.phone,
    Icons.email,
    Icons.chat,
    Icons.message,
    Icons.play_circle,
    Icons.help,
  ];

  final List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.red,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.stepData.selectedColor,
              child: Text('${widget.stepNumber}'),
            ),
            title: Text(
              widget.stepData.titleController.text.isEmpty
                  ? 'Step ${widget.stepNumber}'
                  : widget.stepData.titleController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.stepData.descriptionController.text.isEmpty
                  ? 'Click to edit step details'
                  : widget.stepData.descriptionController.text,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
                const Icon(Icons.drag_handle),
              ],
            ),
            onTap: () => setState(() => isExpanded = !isExpanded),
          ),
          if (isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: widget.stepData.titleController,
                    decoration: const InputDecoration(
                      labelText: 'Step Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.stepData.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Step Description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.stepData.contentController,
                    decoration: const InputDecoration(
                      labelText: 'Step Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.stepData.helpfulTipController,
                    decoration: const InputDecoration(
                      labelText: 'Helpful Tip (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Icon:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  availableIcons.map((icon) {
                                    final isSelected =
                                        widget.stepData.selectedIcon ==
                                        icon.toString();
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                widget.stepData.selectedIcon =
                                                    icon.toString(),
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? widget
                                                      .stepData
                                                      .selectedColor
                                                  : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? widget
                                                        .stepData
                                                        .selectedColor
                                                    : Colors.grey,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Color:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  availableColors.map((color) {
                                    final isSelected =
                                        widget.stepData.selectedColor == color;
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                widget.stepData.selectedColor =
                                                    color,
                                          ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.black
                                                    : Colors.grey,
                                            width: isSelected ? 3 : 1,
                                          ),
                                        ),
                                        child:
                                            isSelected
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                                : null,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onVideoPick,
                          icon: const Icon(Icons.video_library),
                          label: Text(
                            widget.stepData.videoFile?.name ??
                                'Select Step Video',
                          ),
                        ),
                      ),
                      if (widget.stepData.videoFile != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed:
                              () => setState(
                                () => widget.stepData.videoFile = null,
                              ),
                          tooltip: 'Remove Video',
                        ),
                      ],
                    ],
                  ),
                  if (widget.stepData.videoFile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.video_file, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.stepData.videoFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Size: ${(widget.stepData.videoFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
