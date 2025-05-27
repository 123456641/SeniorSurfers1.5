import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dashboardsidebar.dart';
import 'providers/font_size_provider.dart';
import 'widgets/scaled_text.dart';
import 'services/tts_service.dart'; // Add TTS import

class HomePage1 extends StatefulWidget {
  const HomePage1({super.key});

  @override
  State<HomePage1> createState() => _HomePage1State();
}

class _HomePage1State extends State<HomePage1> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> featuredTutorials = [];
  bool isLoadingTutorials = false;
  bool _isTtsEnabled = false; // Track TTS setting

  // Onboarding check states
  bool _isCheckingOnboarding = true;
  bool _hasCheckedOnboarding = false;

  final ScrollController _scrollController = ScrollController();

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  // Interactive tutorials data (same as TutorialPage)
  final List<InteractiveTutorial> interactiveTutorials = [
    InteractiveTutorial(
      title: 'How to Install Google Meet',
      description: 'Step-by-step installation guide with audio',
      platform: 'google_meet',
      route: '/gmeet-tutorial',
      color: Colors.green.shade700,
      features: ['📱 Setup', '🔊 Audio', '👥 Senior'],
    ),
    InteractiveTutorial(
      title: 'How to Join Google Meet',
      description: 'Learn to join meetings step-by-step with audio guidance',
      platform: 'google_meet',
      route: '/gmeet-join-tutorial',
      color: Colors.green.shade700,
      features: ['🤝 Join', '🔊 Audio', '👥 Senior'],
    ),
    // Add more interactive tutorials here as they become available
  ];

  final List<QuickAction> quickActions = [
    QuickAction(
      title: "Start Learning",
      description: "Begin with easy tutorials",
      icon: Icons.school,
      color: Colors.blue.shade700,
      route: "/tutorials",
    ),
    QuickAction(
      title: "Tech Glossary",
      description: "Learn technology terms",
      icon: Icons.book,
      color: Colors.green.shade700,
      route: "/techglossary",
    ),
    QuickAction(
      title: "Play Games",
      description: "Fun learning activities",
      icon: Icons.games,
      color: Colors.orange.shade700,
      route: "/games",
    ),
    QuickAction(
      title: "Join Community",
      description: "Connect with others",
      icon: Icons.people,
      color: Colors.purple.shade700,
      route: "/community",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus(); // Check onboarding first
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🎯 ONBOARDING CHECK LOGIC
  Future<void> _checkOnboardingStatus() async {
    if (_hasCheckedOnboarding) return; // Prevent multiple calls
    _hasCheckedOnboarding = true;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ HomePage1: No user found - redirecting to welcome');
        if (mounted) context.go('/');
        return;
      }

      print('🔍 HomePage1: Checking onboarding status for user: ${user.id}');
      print('🔍 HomePage1: User email: ${user.email}');

      // First, let's check if the user exists in our users table
      final userCheck = await _supabase
          .from('users')
          .select('*')
          .eq('id', user.id);

      print('🔍 HomePage1: User query result: $userCheck');

      if (userCheck.isEmpty) {
        print(
          '🆕 HomePage1: User not found in users table - creating record and showing onboarding',
        );

        // Create user record with onboarding_completed = false
        try {
          await _supabase.from('users').insert({
            'id': user.id,
            'email': user.email ?? '',
            'first_name': '',
            'last_name': '',
            'onboarding_completed': false,
            'tts_enabled': false,
            'tutorial_page_visited': false,
            'games_page_visited': false,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('✅ HomePage1: User record created successfully');
        } catch (insertError) {
          print('❌ HomePage1: Error creating user record: $insertError');
        }

        // Show onboarding for new users
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            print('🎯 HomePage1: New user - redirecting to onboarding');
            context.go('/onboarding');
          }
        }
        return;
      }

      // User exists, check onboarding status
      final userData = userCheck.first;
      final onboardingCompleted = userData['onboarding_completed'] ?? false;

      print('📊 HomePage1: User data: $userData');
      print('📊 HomePage1: Onboarding completed: $onboardingCompleted');

      if (mounted) {
        if (onboardingCompleted) {
          print(
            '🏠 HomePage1: User has completed onboarding - loading homepage',
          );
          setState(() {
            _isCheckingOnboarding = false;
          });
          // Load the rest of the homepage data
          _loadHomePageData();
        } else {
          print('🎯 HomePage1: First-time user - redirecting to onboarding');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.go('/onboarding');
          }
        }
      }
    } catch (e) {
      print('❌ HomePage1: Error checking onboarding status: $e');
      print('❌ HomePage1: Error type: ${e.runtimeType}');
      print('❌ HomePage1: Error details: ${e.toString()}');

      if (mounted) {
        // If there's an error, assume they need onboarding (safer approach)
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          print(
            '🎯 HomePage1: Error occurred - assuming new user, redirecting to onboarding',
          );
          context.go('/onboarding');
        }
      }
    }
  }

  // Load homepage data after onboarding check passes
  Future<void> _loadHomePageData() async {
    await _fetchFeaturedTutorials();
    await _loadTtsPreference();
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

        if (mounted) {
          setState(() {
            _isTtsEnabled = response['tts_enabled'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading TTS preference: $e');
    }
  }

  // Function to speak text when long pressed
  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      await TTSService().speak(text);

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

  Future<void> _fetchFeaturedTutorials() async {
    setState(() {
      isLoadingTutorials = true;
    });

    try {
      // Fetch database tutorials (exclude PDFs like in TutorialPage)
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .neq('file_type', 'pdf') // Exclude PDF tutorials
          .order('uploaded_at', ascending: false)
          .limit(4); // Reduce to make room for interactive tutorials

      List<Map<String, dynamic>> databaseTutorials =
          List<Map<String, dynamic>>.from(response);

      // Convert interactive tutorials to the same format
      List<Map<String, dynamic>> interactiveTutorialsMapped =
          interactiveTutorials
              .map(
                (tutorial) => {
                  'id': 'interactive_${tutorial.route}',
                  'title': tutorial.title,
                  'description': tutorial.description,
                  'platform': tutorial.platform,
                  'file_type': 'interactive',
                  'file_url': tutorial.route,
                  'thumbnail_url': null,
                  'uploaded_at': DateTime.now().toIso8601String(),
                  'color': tutorial.color,
                  'features': tutorial.features,
                },
              )
              .toList();

      // Combine both lists with interactive tutorials first
      List<Map<String, dynamic>> allTutorials = [
        ...interactiveTutorialsMapped,
        ...databaseTutorials,
      ];

      // Limit to 6 total tutorials for featured section
      if (allTutorials.length > 6) {
        allTutorials = allTutorials.take(6).toList();
      }

      if (mounted) {
        setState(() {
          featuredTutorials = allTutorials;
          isLoadingTutorials = false;
        });
      }
    } catch (e) {
      print('Error fetching featured tutorials: $e');
      if (mounted) {
        setState(() {
          isLoadingTutorials = false;
        });
      }
    }
  }

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];

    if (fileType == 'interactive') {
      // Navigate to interactive tutorial route
      context.go(fileUrl);
    } else if (fileType == 'link' || fileType == 'pdf') {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open tutorial')),
          );
        }
      }
    } else {
      context.go('/tutorials');
    }
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

  Widget _buildTutorialThumbnail(
    Map<String, dynamic> tutorial, {
    double size = 120,
    required FontSizeProvider fontProvider,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];
    final scaleFactor = fontProvider.fontSize / 16.0;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: size * scaleFactor.clamp(0.8, 1.3),
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  color: _getPlatformColor(platform),
                  strokeWidth: 3,
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              fallbackImagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: size * scaleFactor.clamp(0.8, 1.3),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(
                      Icons.description,
                      size: size * 0.4 * scaleFactor.clamp(0.8, 1.5),
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: size * scaleFactor.clamp(0.8, 1.3),
        color: Colors.grey.shade100,
        child: Center(
          child: Image.asset(
            fallbackImagePath,
            fit: BoxFit.contain,
            width: size * 0.6 * scaleFactor.clamp(0.8, 1.3),
            height: size * 0.6 * scaleFactor.clamp(0.8, 1.3),
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.description,
                size: size * 0.4 * scaleFactor.clamp(0.8, 1.5),
                color: Colors.grey.shade600,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        // Show loading screen while checking onboarding
        if (_isCheckingOnboarding) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF27445D),
                    ),
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Welcome to Senior Surfers!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF27445D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Preparing your personalized experience...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF27445D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show actual homepage after onboarding check passes
        return SidebarLayoutWrapper(
          currentPage: '/home1',
          pageTitle: 'Welcome Home',
          child: Stack(
            children: [
              _buildHomeContent(context, fontProvider),

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

  Widget _buildHomeContent(
    BuildContext context,
    FontSizeProvider fontProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 1024;
        final scaleFactor = fontProvider.fontSize / 16.0;

        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(context, isMobile, fontProvider),

                    SizedBox(
                      height:
                          (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.2),
                    ),

                    // Quick Actions
                    _buildQuickActions(
                      context,
                      isMobile,
                      isTablet,
                      fontProvider,
                    ),

                    SizedBox(
                      height:
                          (isMobile ? 32 : 40) * scaleFactor.clamp(0.8, 1.2),
                    ),

                    // Featured Tutorials
                    _buildFeaturedTutorials(
                      context,
                      isMobile,
                      isTablet,
                      fontProvider,
                    ),

                    SizedBox(
                      height:
                          (isMobile ? 32 : 40) * scaleFactor.clamp(0.8, 1.2),
                    ),

                    // Daily Tips
                    _buildDailyTip(context, isMobile, fontProvider),

                    SizedBox(
                      height:
                          (isMobile ? 40 : 60) * scaleFactor.clamp(0.8, 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Welcome Header
  Widget _buildWelcomeHeader(
    BuildContext context,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.3),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF27445D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27445D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Colors.amber.shade400,
                size: (isMobile ? 36 : 44) * scaleFactor.clamp(0.8, 1.5),
              ),
              SizedBox(width: 16 * scaleFactor.clamp(0.8, 1.2)),
              Expanded(
                child: _buildLongPressText(
                  text: "Welcome Back!",
                  style: TextStyle(
                    fontSize: (isMobile ? 28 : 36) * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scaleFactor.clamp(0.8, 1.2)),
          _buildLongPressText(
            text:
                "Ready to learn something new today? Explore our latest tutorials and connect with your community.",
            style: TextStyle(
              fontSize: (isMobile ? 18 : 20) * scaleFactor,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 24 * scaleFactor.clamp(0.8, 1.2)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/tutorials'),
              icon: Icon(
                Icons.play_arrow,
                color: const Color(0xFF27445D),
                size: 24 * scaleFactor.clamp(0.8, 1.5),
              ),
              label: Text(
                "Continue Learning",
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  color: const Color(0xFF27445D),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF27445D),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.3),
                  vertical: (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF27445D), width: 2),
                ),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLongPressText(
          text: "Quick Start",
          style: TextStyle(
            fontSize: (isMobile ? 24 : 28) * scaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            double childAspectRatio;
            double maxCrossAxisExtent;

            if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
              childAspectRatio = 0.85;
              maxCrossAxisExtent = 200;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
              childAspectRatio = 0.9;
              maxCrossAxisExtent = 250;
            } else {
              crossAxisCount = 4;
              childAspectRatio = 1.0;
              maxCrossAxisExtent = 300;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                crossAxisSpacing:
                    (isMobile ? 12 : 16) * scaleFactor.clamp(0.8, 1.2),
                mainAxisSpacing:
                    (isMobile ? 12 : 16) * scaleFactor.clamp(0.8, 1.2),
                childAspectRatio: childAspectRatio,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionCard(action, isMobile, fontProvider);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    QuickAction action,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;
    final maxTitleSize = isMobile ? 20.0 : 22.0;
    final titleFontSize = ((isMobile ? 16 : 18) * scaleFactor).clamp(
      14.0,
      maxTitleSize,
    );

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () => context.go(action.route),
        onLongPress: () => _speakText(action.title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(
            (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  (isMobile ? 12 : 14) * scaleFactor.clamp(0.8, 1.2),
                ),
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: action.color, width: 2),
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: (isMobile ? 28 : 32) * scaleFactor.clamp(0.8, 1.3),
                ),
              ),
              SizedBox(
                height: (isMobile ? 12 : 16) * scaleFactor.clamp(0.8, 1.1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    action.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTutorials(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _buildLongPressText(
                text: "Featured for You",
                style: TextStyle(
                  fontSize: (isMobile ? 24 : 28) * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/tutorials'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "See All",
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
        if (isLoadingTutorials)
          Container(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27445D),
                strokeWidth: 4,
              ),
            ),
          )
        else if (featuredTutorials.isEmpty)
          Container(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80 * scaleFactor.clamp(0.8, 1.5),
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
                  _buildLongPressText(
                    text: "No tutorials available yet",
                    style: TextStyle(
                      fontSize: (isMobile ? 18 : 20) * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor.clamp(0.8, 1.2)),
                  _buildLongPressText(
                    text: "Check back later for new content!",
                    style: TextStyle(
                      fontSize: (isMobile ? 16 : 18) * scaleFactor,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.3),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: isMobile ? 16 : 0),
              itemCount: featuredTutorials.length,
              itemBuilder: (context, index) {
                final tutorial = featuredTutorials[index];
                return Container(
                  width: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
                  margin: EdgeInsets.only(
                    right: (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.2),
                  ),
                  child: _buildTutorialCard(tutorial, isMobile, fontProvider),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTutorialCard(
    Map<String, dynamic> tutorial,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () => _openTutorial(tutorial),
        onLongPress:
            () => _speakText(
              tutorial['title'] ?? tutorial['file_name'] ?? 'Tutorial',
            ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: (isMobile ? 140 : 160) * scaleFactor.clamp(0.8, 1.3),
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildTutorialThumbnail(
                      tutorial,
                      size: isMobile ? 140 : 160,
                      fontProvider: fontProvider,
                    ),
                  ),
                  Positioned(
                    top: 12 * scaleFactor.clamp(0.8, 1.2),
                    left: 12 * scaleFactor.clamp(0.8, 1.2),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scaleFactor.clamp(0.8, 1.2),
                        vertical: 6 * scaleFactor.clamp(0.8, 1.2),
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(tutorial['platform']),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        tutorial['platform']
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: (isMobile ? 11 : 12) * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12 * scaleFactor.clamp(0.8, 1.2),
                    right: 12 * scaleFactor.clamp(0.8, 1.2),
                    child: Container(
                      padding: EdgeInsets.all(8 * scaleFactor.clamp(0.8, 1.2)),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        tutorial['file_type'] == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.open_in_new,
                        size: 18 * scaleFactor.clamp(0.8, 1.3),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLongPressText(
                      text:
                          tutorial['title'] ??
                          tutorial['file_name'] ??
                          'Untitled',
                      style: TextStyle(
                        fontSize: (isMobile ? 17 : 19) * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8 * scaleFactor.clamp(0.8, 1.2)),
                    if (tutorial['description'] != null &&
                        tutorial['description'].toString().isNotEmpty)
                      Expanded(
                        child: _buildLongPressText(
                          text: tutorial['description'].toString(),
                          style: TextStyle(
                            fontSize: (isMobile ? 15 : 16) * scaleFactor,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: _buildLongPressText(
                          text:
                              "Learn ${tutorial['platform'].toString().replaceAll('_', ' ')} with this step-by-step guide",
                          style: TextStyle(
                            fontSize: (isMobile ? 15 : 16) * scaleFactor,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(height: 12 * scaleFactor.clamp(0.8, 1.2)),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle,
                          size: 20 * scaleFactor.clamp(0.8, 1.3),
                          color: _getPlatformColor(tutorial['platform']),
                        ),
                        SizedBox(width: 6 * scaleFactor.clamp(0.8, 1.2)),
                        Text(
                          tutorial['file_type'] == 'pdf'
                              ? 'PDF Guide'
                              : 'Interactive',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: _getPlatformColor(tutorial['platform']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 20 * scaleFactor.clamp(0.8, 1.3),
                          color: Colors.black,
                        ),
                      ],
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

  Widget _buildDailyTip(
    BuildContext context,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        (isMobile ? 24 : 28) * scaleFactor.clamp(0.8, 1.3),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade600, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scaleFactor.clamp(0.8, 1.2)),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: (isMobile ? 28 : 32) * scaleFactor.clamp(0.8, 1.5),
                ),
              ),
              SizedBox(width: 16 * scaleFactor.clamp(0.8, 1.2)),
              Flexible(
                child: _buildLongPressText(
                  text: "Today's Tip",
                  style: TextStyle(
                    fontSize: (isMobile ? 22 : 24) * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scaleFactor.clamp(0.8, 1.2)),
          _buildLongPressText(
            text:
                _isTtsEnabled
                    ? "You have text-to-speech enabled! Long press on any text to hear it read aloud. This makes learning easier and more accessible."
                    : "Did you know you can make text larger throughout this entire app? Go to Settings and adjust the 'Text Size' slider to make reading easier on your eyes! You can also enable 'Read Text Aloud' to have text spoken to you.",
            style: TextStyle(
              fontSize: (isMobile ? 17 : 18) * scaleFactor,
              color: Colors.black,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isTtsEnabled) ...[
            SizedBox(height: 16 * scaleFactor.clamp(0.8, 1.2)),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/settingsD'),
                icon: Icon(Icons.volume_up, size: 18),
                label: Text('Enable Read Aloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Data Models
class QuickAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  QuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class InteractiveTutorial {
  final String title;
  final String description;
  final String platform;
  final String route;
  final Color color;
  final List<String> features;

  InteractiveTutorial({
    required this.title,
    required this.description,
    required this.platform,
    required this.route,
    required this.color,
    required this.features,
  });
}
