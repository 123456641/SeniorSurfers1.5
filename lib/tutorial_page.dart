import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'services/tts_service.dart'; // Add TTS import

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPage();
}

class _TutorialPage extends State<TutorialPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = true;
  String? selectedPlatform;
  Map<String, dynamic>? selectedTutorial;
  bool _isTtsEnabled = false; // Track TTS setting

  // Tab controller for bookmark categories
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  // Interactive tutorials data - updated with video support for install tutorial
  final List<InteractiveTutorial> interactiveTutorials = [
    InteractiveTutorial(
      title: 'How to Install Google Meet',
      description: 'Step-by-step installation guide with audio',
      platform: 'google_meet',
      route: '/gmeet-tutorial',
      color: Colors.green.shade700,
      features: ['📱 Setup', '🔊 Audio', '👥 Senior'],
      hasVideo: true, // Enable video for this tutorial
      videoDescription:
          'Watch a complete video walkthrough of the installation process',
    ),
    InteractiveTutorial(
      title: 'How to Join Google Meet',
      description: 'Learn to join meetings step-by-step with audio guidance',
      platform: 'google_meet',
      route: '/gmeet-join-tutorial',
      color: Colors.green.shade700,
      features: ['🤝 Join', '🔊 Audio', '👥 Senior'],
      hasVideo: false, // Keep video as coming soon for this tutorial
      videoDescription: 'Video tutorial coming soon',
    ),
    // Add more interactive tutorials here as they become available
  ];

  // Category definitions for bookmark tabs (Interactive tutorials only)
  final List<CategoryTab> categories = [
    CategoryTab(title: 'All', key: null, color: const Color(0xFF27445D)),
    CategoryTab(
      title: 'Google Meet',
      key: 'google_meet',
      color: Colors.green.shade700,
    ),
    CategoryTab(title: 'Zoom', key: 'zoom', color: Colors.blue.shade700),
    CategoryTab(title: 'Gmail', key: 'gmail', color: Colors.red.shade700),
    CategoryTab(title: 'Viber', key: 'viber', color: Colors.purple.shade700),
    CategoryTab(
      title: 'WhatsApp',
      key: 'whatsapp',
      color: Colors.green.shade700,
    ),
    CategoryTab(title: 'CliQQ', key: 'cliqq', color: Colors.orange.shade700),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryIndex = _tabController.index;
          selectedPlatform = categories[_selectedCategoryIndex].key;
        });
        fetchTutorials();
      }
    });
    _loadTtsPreference();
    fetchTutorials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load TTS preference from user settings
  Future<void> _loadTtsPreference() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response =
            await _supabase
                .from('users')
                .select('tts_enabled')
                .eq('id', user.id)
                .single();

        setState(() {
          _isTtsEnabled = response['tts_enabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading TTS preference: $e');
    }
  }

  // Function to speak text when long pressed
  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      await TTSService().speak(text);

      // Show feedback to user
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
    } else if (!_isTtsEnabled) {
      // Show instruction to enable TTS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.volume_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enable "Read Text Aloud" in Settings to use this feature',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => context.go('/settingsD'),
          ),
        ),
      );
    }
  }

  // Show "Coming Soon" dialog for video tutorials that aren't ready
  void _showComingSoonDialog(String tutorialTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.video_library,
                color: Colors.orange.shade600,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Video Tutorial',
                style: TextStyle(
                  color: const Color(0xFF27445D),
                  fontWeight: FontWeight.bold,
                  fontSize: _getFontSize(context, multiplier: 1.2),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.construction,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Coming Soon!',
                        style: TextStyle(
                          fontSize: _getFontSize(context, multiplier: 1.1),
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'The video tutorial for "$tutorialTitle" is currently in development. For now, you can use the interactive step-by-step tutorial with audio guidance.',
                style: TextStyle(
                  fontSize: _getFontSize(context),
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Try the interactive tutorial instead!',
                        style: TextStyle(
                          fontSize: _getFontSize(context, multiplier: 0.9),
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: _getFontSize(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigate to dedicated video page for install tutorial
  void _navigateToVideoPage(InteractiveTutorial tutorial) {
    if (tutorial.title == 'How to Install Google Meet' && tutorial.hasVideo) {
      // Navigate to dedicated video page with the video file
      context.go('/gmeet-install-video');
    } else {
      // Show coming soon dialog for other tutorials
      _showComingSoonDialog(tutorial.title);
    }
  }

  // Custom widget for long-pressable text
  Widget _buildLongPressText({
    required String text,
    required TextStyle style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GestureDetector(
      onLongPress: () => _speakText(text),
      child: Container(
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }

  // Helper method to get font size safely
  double _getFontSize(BuildContext context, {double multiplier = 1.0}) {
    try {
      final fontSizeProvider = Provider.of<FontSizeProvider>(
        context,
        listen: false,
      );
      return fontSizeProvider.fontSize * multiplier;
    } catch (e) {
      return 16.0 * multiplier;
    }
  }

  // Helper method to build text with safe font size
  Widget _buildText(
    String text,
    BuildContext context, {
    double multiplier = 1.0,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return _buildLongPressText(
      text: text,
      style: TextStyle(
        fontSize: _getFontSize(context, multiplier: multiplier),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  Future<void> fetchTutorials() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Filter tutorials to exclude PDFs - only keep interactive/link types
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .neq('file_type', 'pdf') // Exclude PDF tutorials
          .order('uploaded_at', ascending: false);

      List<Map<String, dynamic>> filteredTutorials = [];
      if (selectedPlatform != null) {
        for (var tutorial in response as List) {
          if (tutorial['platform'] == selectedPlatform) {
            filteredTutorials.add(tutorial);
          }
        }
      } else {
        filteredTutorials = List<Map<String, dynamic>>.from(response);
      }

      setState(() {
        tutorials = filteredTutorials;
        isLoading = false;

        if (selectedTutorial != null) {
          bool tutorialExists = false;
          for (var tutorial in filteredTutorials) {
            if (tutorial['id'] == selectedTutorial!['id']) {
              tutorialExists = true;
              break;
            }
          }
          if (!tutorialExists) {
            selectedTutorial = null;
          }
        }
      });
    } catch (e) {
      print('Error fetching tutorials: $e');
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

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    setState(() {
      selectedTutorial = tutorial;
    });

    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];

    // Only handle link types since we removed PDF support
    if (fileType == 'link') {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $fileUrl')),
          );
        }
      }
    } else {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $fileUrl')),
          );
        }
      }
    }
  }

  // Get filtered interactive tutorials based on selected platform
  List<InteractiveTutorial> getFilteredInteractiveTutorials() {
    if (selectedPlatform == null) {
      return interactiveTutorials;
    }
    return interactiveTutorials
        .where((tutorial) => tutorial.platform == selectedPlatform)
        .toList();
  }

  // Build interactive tutorials section
  Widget _buildInteractiveTutorials() {
    final filteredTutorials = getFilteredInteractiveTutorials();

    if (filteredTutorials.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, color: Colors.amber.shade700, size: 48),
            SizedBox(height: 12),
            _buildText(
              'Interactive Tutorials Coming Soon!',
              context,
              multiplier: 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            _buildText(
              selectedPlatform != null
                  ? 'Interactive tutorials for ${selectedPlatform!.replaceAll('_', ' ')} are in development'
                  : 'More interactive tutorials are being developed',
              context,
              multiplier: 0.9,
              color: Colors.amber.shade700,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildText(
                      'Interactive Tutorials',
                      context,
                      multiplier: 1.3,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27445D),
                    ),
                    SizedBox(height: 4),
                    _buildText(
                      'Step-by-step guided tutorials with audio and practice',
                      context,
                      multiplier: 0.9,
                      color: Colors.grey.shade600,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Interactive tutorials list
        ...filteredTutorials
            .map((tutorial) => _buildInteractiveTutorialCard(tutorial))
            .toList(),
      ],
    );
  }

  Widget _buildInteractiveTutorialCard(InteractiveTutorial tutorial) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tutorial.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main tutorial card
          InkWell(
            onTap: () => context.go(tutorial.route),
            onLongPress:
                () => _speakText('${tutorial.title}. ${tutorial.description}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tutorial icon/image
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tutorial.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tutorial.color.withOpacity(0.3),
                        ),
                      ),
                      child: Image.asset(
                        platformImages[tutorial.platform] ??
                            'assets/images/practice/document.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.play_circle_fill,
                            color: tutorial.color,
                            size: 32,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16),

                    // Tutorial content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildText(
                            tutorial.title,
                            context,
                            multiplier: 1.1,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF27445D),
                            maxLines: 2,
                          ),
                          SizedBox(height: 6),
                          _buildText(
                            tutorial.description,
                            context,
                            multiplier: 0.9,
                            color: Colors.grey.shade600,
                            maxLines: 2,
                          ),
                          SizedBox(height: 12),

                          // Feature badges - Fix overflow here
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 200,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    tutorial.features
                                        .map(
                                          (feature) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: _buildFeatureBadge(
                                              feature,
                                              tutorial.color,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),

                    // Play button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tutorial.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Video tutorial option - updated logic
          Divider(height: 1, color: Colors.grey.shade200),
          InkWell(
            onTap: () => _navigateToVideoPage(tutorial),
            onLongPress:
                () => _speakText(
                  tutorial.hasVideo
                      ? 'Video tutorial - ${tutorial.videoDescription}'
                      : 'Video tutorial option - Coming soon',
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          tutorial.hasVideo
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_library,
                      color:
                          tutorial.hasVideo
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildText(
                          'Video Tutorial',
                          context,
                          multiplier: 0.9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF27445D),
                        ),
                        _buildText(
                          tutorial.hasVideo
                              ? 'Watch a video walkthrough'
                              : 'Watch a video walkthrough',
                          context,
                          multiplier: 0.8,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          tutorial.hasVideo
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            tutorial.hasVideo
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                      ),
                    ),
                    child: _buildText(
                      tutorial.hasVideo ? 'Available' : 'Coming Soon',
                      context,
                      multiplier: 0.7,
                      color:
                          tutorial.hasVideo
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: _buildText(
        text,
        context,
        multiplier: 0.65,
        color: color,
        fontWeight: FontWeight.w600,
        maxLines: 1,
      ),
    );
  }

  Widget _buildBookmarkTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isSelected = index == _selectedCategoryIndex;

            final screenWidth = MediaQuery.of(context).size.width;
            final baseWidth = screenWidth < 600 ? 80.0 : 100.0;
            final textLength = category.title.length;
            final dynamicWidth = (baseWidth + (textLength * 2)).clamp(
              baseWidth,
              baseWidth * 1.5,
            );

            return GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              onLongPress: () => _speakText(category.title), // Add TTS to tabs
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: CustomPaint(
                  painter: BookmarkPainter(
                    color: category.color,
                    isSelected: isSelected,
                  ),
                  child: Container(
                    width: dynamicWidth,
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(
                      bottom: 8,
                      left: 4,
                      right: 4,
                    ),
                    child: Text(
                      category.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: _getFontSize(
                          context,
                          multiplier: 0.7,
                        ).clamp(10.0, 14.0),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(
    Map<String, dynamic> tutorial, {
    double size = 64,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder:
            (context, url) => Center(
              child: SizedBox(
                width: size / 2,
                height: size / 2,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              fallbackImagePath,
              fit: BoxFit.contain,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.description,
                  size: size * 0.75,
                  color: Colors.grey.shade400,
                );
              },
            ),
      );
    } else {
      return Image.asset(
        fallbackImagePath,
        fit: BoxFit.contain,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.description,
            size: size * 0.75,
            color: Colors.grey.shade400,
          );
        },
      );
    }
  }

  Widget _buildTutorialDetail(Map<String, dynamic> tutorial) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button for mobile
          if (MediaQuery.of(context).size.width < 600)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedTutorial = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: const Color(0xFF27445D),
                ),
              ),
            ),

          // Tutorial image with proper constraints
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width < 600 ? 0.8 : 0.4),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _buildThumbnailImage(tutorial, size: 200),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title with overflow handling
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: _buildText(
                tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                context,
                multiplier: 1.4,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getPlatformColor(tutorial['platform']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildText(
                tutorial['platform']
                    .toString()
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                context,
                multiplier: 0.9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description with overflow handling
          if (tutorial['description'] != null &&
              tutorial['description'].toString().isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildText(
                  tutorial['description'].toString(),
                  context,
                  color: Colors.grey[700],
                  maxLines: 10,
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Action button
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.open_in_new, color: Colors.white),
                label: Text(
                  'Open Tutorial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getFontSize(context),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final fileUrl = tutorial['file_url'];
                  launchUrl(
                    Uri.parse(fileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),
          ),

          // Add bottom padding to prevent overflow
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTutorialsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Interactive tutorials section
          _buildInteractiveTutorials(),

          // Database tutorials list (non-PDF only)
          if (tutorials.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: const Color(0xFF27445D), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildText(
                      'External Resources',
                      context,
                      multiplier: 1.1,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27445D),
                    ),
                  ),
                ],
              ),
            ),

            // External tutorials list
            ...tutorials.map((tutorial) {
              final bool isSelected =
                  selectedTutorial != null &&
                  tutorial['id'] == selectedTutorial!['id'];

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12.0,
                  left: 16,
                  right: 16,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side:
                        isSelected
                            ? const BorderSide(
                              color: Color(0xFF27445D),
                              width: 2,
                            )
                            : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () => _openTutorial(tutorial),
                    onLongPress:
                        () => _speakText(
                          tutorial['title'] ??
                              tutorial['file_name'] ??
                              'Tutorial',
                        ),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Leading image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildThumbnailImage(tutorial, size: 56),
                          ),
                          const SizedBox(width: 16),

                          // Content with proper overflow handling
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                _buildText(
                                  tutorial['title'] ??
                                      tutorial['file_name'] ??
                                      'Untitled',
                                  context,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),

                                // Platform badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPlatformColor(
                                      tutorial['platform'],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getPlatformColor(
                                        tutorial['platform'],
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: _buildText(
                                    tutorial['platform']
                                        .toString()
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    context,
                                    multiplier: 0.75,
                                    color: _getPlatformColor(
                                      tutorial['platform'],
                                    ),
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Trailing icon
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF27445D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.open_in_new,
                              color: const Color(0xFF27445D),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            // Add some bottom padding
            SizedBox(height: 20),
          ] else if (getFilteredInteractiveTutorials().isEmpty) ...[
            // Show message when no tutorials available
            Container(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      _buildText(
                        'No tutorials available',
                        context,
                        multiplier: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      _buildText(
                        selectedPlatform != null
                            ? 'Try selecting a different platform or clear filters'
                            : 'Check back later for new content',
                        context,
                        multiplier: 0.9,
                        color: Colors.grey[500],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'google_meet':
        return Colors.green.shade700;
      case 'zoom':
        return Colors.blue.shade700;
      case 'gmail':
        return Colors.red.shade700;
      case 'viber':
        return Colors.purple.shade700;
      case 'whatsapp':
        return Colors.green.shade700;
      case 'cliqq':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/tutorials',
          pageTitle: 'Tutorials',
          child: Stack(
            children: [
              _buildContent(),

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

  Widget _buildContent() {
    return Column(
      children: [
        // Bookmark-style category tabs
        _buildBookmarkTabs(),

        // Main content area with proper constraints - THIS IS THE KEY FIX
        Expanded(
          child:
              selectedTutorial == null
                  ? _buildTutorialsList()
                  : SingleChildScrollView(
                    child: _buildTutorialDetail(selectedTutorial!),
                  ),
        ),
      ],
    );
  }
}

// Data models
class CategoryTab {
  final String title;
  final String? key;
  final Color color;

  CategoryTab({required this.title, required this.key, required this.color});
}

class InteractiveTutorial {
  final String title;
  final String description;
  final String platform;
  final String route;
  final Color color;
  final List<String> features;
  final bool hasVideo; // New field to indicate if video is available
  final String videoDescription; // New field for video description

  InteractiveTutorial({
    required this.title,
    required this.description,
    required this.platform,
    required this.route,
    required this.color,
    required this.features,
    this.hasVideo = false, // Default to false
    this.videoDescription = '', // Default empty description
  });
}

// Custom painter for bookmark shape
class BookmarkPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  BookmarkPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();

    // Create bookmark shape
    path.moveTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.lineTo(size.width, size.height - 12); // Right side
    path.lineTo(size.width / 2, size.height); // Bottom point
    path.lineTo(0, size.height - 12); // Left side
    path.close();

    // Add shadow for selected state
    if (isSelected) {
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final shadowPath = Path.from(path);
      shadowPath.transform(Matrix4.translationValues(0, 2, 0).storage);
      canvas.drawPath(shadowPath, shadowPaint);
    }

    canvas.drawPath(path, paint);

    // Add highlight for selected state
    if (isSelected) {
      final highlightPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.fill;
      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BookmarkPainter &&
        (oldDelegate.color != color || oldDelegate.isSelected != isSelected);
  }
}
