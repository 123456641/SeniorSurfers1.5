import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'widgets/scaled_text.dart';
import 'services/tts_service.dart'; // Add this import

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? profilePictureUrl;
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isFontSizeChanged = false;
  bool _isTtsEnabled = false; // Add TTS toggle state

  final picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool isEditable = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchUserData();
  }

  // Function to speak text when long pressed
  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      try {
        await TTSService().speak(text);

        // Show feedback to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reading: ${text.length > 30 ? text.substring(0, 30) + "..." : text}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF27445D),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error in TTS: $e');
      }
    } else if (!_isTtsEnabled) {
      // Show instruction to enable TTS
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.volume_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enable "Read Text Aloud" above to use this feature',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Custom widget for long-pressable text
  Widget _buildLongPressText({
    required String text,
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return GestureDetector(
          onLongPress: () => _speakText(text),
          child: Container(
            child: ScaledText(
              text,
              baseFontSize: baseFontSize,
              fontWeight: fontWeight,
              color: color,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              height: height,
            ),
          ),
        );
      },
    );
  }

  // Toggle TTS and save preference
  void _toggleTts() async {
    setState(() {
      _isTtsEnabled = !_isTtsEnabled;
    });

    // Save preference to database
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({'tts_enabled': _isTtsEnabled})
            .eq('id', user.id);
      }
    } catch (e) {
      print('Error saving TTS preference: $e');
    }

    // Test TTS when enabled
    if (_isTtsEnabled) {
      await TTSService().speak("Text to speech is now enabled");
    } else {
      await TTSService().stop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTtsEnabled ? 'Text to speech enabled' : 'Text to speech disabled',
        ),
        backgroundColor: _isTtsEnabled ? Colors.green : Colors.orange,
      ),
    );
  }

  void _onFontSizeChanged(double newSize) {
    Provider.of<FontSizeProvider>(context, listen: false).setFontSize(newSize);
    setState(() {
      _isFontSizeChanged = true;
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.photos,
            Permission.storage,
            Permission.camera,
          ].request();
      print('Permission statuses: $statuses');
    }
  }

  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response =
          await supabase
              .from('users')
              .select(
                'profile_picture_url, first_name, last_name, phone, email, tts_enabled',
              )
              .eq('id', user.id)
              .single();

      if (mounted) {
        String? pictureUrl = response['profile_picture_url'];
        if (pictureUrl != null) {
          pictureUrl =
              pictureUrl.contains('?')
                  ? '$pictureUrl&_cache=${DateTime.now().millisecondsSinceEpoch}'
                  : '$pictureUrl?_cache=${DateTime.now().millisecondsSinceEpoch}';
        }

        setState(() {
          profilePictureUrl = pictureUrl;
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _phoneNumber = response['phone'] ?? '';
          _email = response['email'] ?? '';
          _isTtsEnabled =
              response['tts_enabled'] ?? false; // Load TTS preference
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickAndUploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLongPressText(
                  text: 'Choose Photo Source',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onLongPress: () => _speakText('Gallery'),
                  child: ListTile(
                    leading: const Icon(Icons.photo_library, size: 32),
                    title: const ScaledText('Gallery', baseFontSize: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _getAndUploadImage(ImageSource.gallery, user);
                    },
                  ),
                ),
                GestureDetector(
                  onLongPress: () => _speakText('Camera'),
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt, size: 32),
                    title: const ScaledText('Camera', baseFontSize: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _getAndUploadImage(ImageSource.camera, user);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getAndUploadImage(ImageSource source, User user) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final Uint8List bytes = await pickedFile.readAsBytes();
      final String fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('profiles')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String imageUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);
      imageUrl =
          imageUrl.contains('?')
              ? '$imageUrl&t=$timestamp'
              : '$imageUrl?t=$timestamp';

      await supabase
          .from('users')
          .update({'profile_picture_url': imageUrl})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          profilePictureUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleEditability() {
    setState(() {
      isEditable = !isEditable;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = supabase.auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        await supabase
            .from('users')
            .update({
              'first_name': _firstName,
              'last_name': _lastName,
              'phone': _phoneNumber,
            })
            .eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            isEditable = false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: _buildLongPressText(
            text: "Sign Out",
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          content: _buildLongPressText(
            text: "Are you sure you want to sign out?",
            baseFontSize: 16,
          ),
          actions: [
            GestureDetector(
              onLongPress: () => _speakText("Cancel"),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const ScaledText("Cancel", baseFontSize: 16),
              ),
            ),
            GestureDetector(
              onLongPress: () => _speakText("Sign Out"),
              child: ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (mounted) {
                    context.go('/');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const ScaledText(
                  "Sign Out",
                  baseFontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/settingsD',
          pageTitle: 'Settings',
          child: Stack(
            children: [
              _buildSettingsContent(fontProvider),
              // TTS Indicator when enabled
              if (_isTtsEnabled)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF27445D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'TTS On',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsContent(FontSizeProvider fontProvider) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _fetchUserData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child:
                    isLargeScreen
                        ? _buildLargeScreenLayout(fontProvider)
                        : _buildSmallScreenLayout(fontProvider),
              ),
            ),
          ),
        );
  }

  Widget _buildLargeScreenLayout(FontSizeProvider fontProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfilePicture(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onLongPress: () => _speakText('Sign Out'),
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout),
                        label: const ScaledText('Sign Out', baseFontSize: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 2, child: _buildAccountDetails(fontProvider)),
      ],
    );
  }

  Widget _buildSmallScreenLayout(FontSizeProvider fontProvider) {
    return Column(
      children: [
        _buildProfilePicture(),
        const SizedBox(height: 24),
        _buildAccountDetails(fontProvider),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onLongPress: () => _speakText('Sign Out'),
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              label: const ScaledText('Sign Out', baseFontSize: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              onLongPress: () => _speakText('Tap to change photo'),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF27445D), width: 3),
                ),
                child:
                    _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : ClipOval(
                          child:
                              profilePictureUrl != null
                                  ? Image.network(
                                    profilePictureUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 70);
                                    },
                                  )
                                  : const Icon(Icons.person, size: 70),
                        ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF27445D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLongPressText(
          text: 'Tap to change photo',
          baseFontSize: 14,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildAccountDetails(FontSizeProvider fontProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLongPressText(
                    text: 'Account Details',
                    baseFontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                isEditable
                    ? GestureDetector(
                      onLongPress: () => _speakText('Save'),
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save, size: 16),
                        label: const ScaledText('Save', baseFontSize: 14),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    )
                    : GestureDetector(
                      onLongPress: () => _speakText('Edit'),
                      child: ElevatedButton.icon(
                        onPressed: _toggleEditability,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const ScaledText('Edit', baseFontSize: 14),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27445D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            const Divider(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'First Name',
                    value: _firstName,
                    enabled: isEditable,
                    onSaved: (value) => _firstName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Last Name',
                    value: _lastName,
                    enabled: isEditable,
                    onSaved: (value) => _lastName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Phone',
                    value: _phoneNumber,
                    enabled: isEditable,
                    onSaved: (value) => _phoneNumber = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email',
                    value: _email,
                    enabled: false,
                    onSaved: (value) => _email = value ?? '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TTS Settings Section
            GestureDetector(
              onLongPress:
                  () => _speakText(
                    _isTtsEnabled
                        ? 'Read Text Aloud is enabled. Text will be read aloud when you tap on content.'
                        : 'Read Text Aloud is disabled. Enable to have text read aloud throughout the app.',
                  ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                          color: const Color(0xFF27445D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLongPressText(
                            text: 'Read Text Aloud',
                            baseFontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onLongPress:
                              () => _speakText(
                                _isTtsEnabled
                                    ? 'Disable text to speech'
                                    : 'Enable text to speech',
                              ),
                          child: Switch(
                            value: _isTtsEnabled,
                            onChanged: (value) => _toggleTts(),
                            activeColor: const Color(0xFF27445D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLongPressText(
                      text:
                          _isTtsEnabled
                              ? 'Text will be read aloud when you long press on content'
                              : 'Enable to have text read aloud throughout the app',
                      baseFontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    if (_isTtsEnabled) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onLongPress: () => _speakText('Test Voice'),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await TTSService().speak(
                                "This is a test of the text to speech feature. You can now hear content read aloud throughout the Senior Surfers app.",
                              );
                            },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const ScaledText(
                              'Test Voice',
                              baseFontSize: 14,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27445D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Font Size Settings
            GestureDetector(
              onLongPress:
                  () => _speakText(
                    'Text Size settings. Use the slider to adjust text size throughout the app.',
                  ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields, color: Color(0xFF27445D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLongPressText(
                            text: 'Text Size',
                            baseFontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isFontSizeChanged)
                          GestureDetector(
                            onLongPress: () => _speakText('Applied!'),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isFontSizeChanged = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Font size applied to entire app!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: const ScaledText(
                                'Applied!',
                                baseFontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildLongPressText(text: 'A', baseFontSize: 12),
                        Expanded(
                          child: Slider(
                            value: fontProvider.fontSize,
                            min: fontProvider.minFontSize,
                            max: fontProvider.maxFontSize,
                            divisions: 20,
                            activeColor: const Color(0xFF27445D),
                            onChanged: _onFontSizeChanged,
                          ),
                        ),
                        _buildLongPressText(text: 'A', baseFontSize: 18),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onLongPress:
                              () => _speakText(
                                'Current text size is ${fontProvider.fontSize.round()} pixels',
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27445D),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ScaledText(
                              '${fontProvider.fontSize.round()}px',
                              baseFontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onLongPress:
                          () => _speakText(
                            'Sample text: This shows how text appears throughout the app.',
                          ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const ScaledText(
                          'Sample text: This shows how text appears throughout the app.',
                          baseFontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onLongPress: () => _speakText('Reset to Default'),
                        child: TextButton(
                          onPressed: () {
                            fontProvider.resetToDefault();
                            setState(() {
                              _isFontSizeChanged = true;
                            });
                          },
                          child: const ScaledText(
                            'Reset to Default',
                            baseFontSize: 14,
                            color: Color(0xFF27445D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required bool enabled,
    required Function(String?) onSaved,
  }) {
    return GestureDetector(
      onLongPress:
          () => _speakText('$label: ${value.isEmpty ? "Not set" : value}'),
      child: TextFormField(
        initialValue: value,
        enabled: enabled,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF27445D), width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: 16,
        ),
      ),
    );
  }
}
