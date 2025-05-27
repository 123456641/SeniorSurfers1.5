//File: onboarding_page.dart - Updated to redirect to /home1
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'services/tts_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool _isTtsEnabled = false;
  bool _isLoading = false;

  final List<OnboardingStep> onboardingSteps = [
    OnboardingStep(
      title: "Welcome to Senior Surfers! 🌊",
      description: "Your friendly guide to technology",
      content:
          "We're here to help you navigate the digital world with confidence. Let's start your journey together!",
      icon: Icons.waving_hand,
      color: Colors.blue.shade600,
    ),
    OnboardingStep(
      title: "Learn at Your Own Pace 📚",
      description: "Step-by-step tutorials made simple",
      content:
          "Our tutorials are designed specifically for seniors. We explain everything clearly and give you time to practice.",
      icon: Icons.school,
      color: Colors.green.shade600,
    ),
    OnboardingStep(
      title: "Practice Safely 🛡️",
      description: "Try new apps without worry",
      content:
          "Practice using apps like Google Meet, WhatsApp, and more in a safe environment before using them for real.",
      icon: Icons.security,
      color: Colors.orange.shade600,
    ),
    OnboardingStep(
      title: "Get Help When Needed 🤝",
      description: "You're never alone in your learning",
      content:
          "Access our community forum, helpful glossary, and audio features to support your learning journey.",
      icon: Icons.help_center,
      color: Colors.purple.shade600,
    ),
    OnboardingStep(
      title: "Ready to Start? 🚀",
      description: "Let's explore your homepage",
      content:
          "You're all set! Your homepage has everything you need: tutorials, practice modes, games, and more. Take your time exploring!",
      icon: Icons.home,
      color: Colors.teal.shade600,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTtsPreference();
  }

  Future<void> _loadTtsPreference() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response =
            await Supabase.instance.client
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

  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      try {
        await TTSService().speak(text);
      } catch (e) {
        print('TTS Error: $e');
      }
    }
  }

  Future<void> _markOnboardingComplete() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'onboarding_completed': true})
            .eq('id', user.id);

        print('✅ Onboarding marked as complete');
      }
    } catch (e) {
      print('Error marking onboarding complete: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _nextPage() {
    if (currentPage < onboardingSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await _markOnboardingComplete();
    if (mounted) {
      // CHANGED: Redirect to /home1 instead of /dashboard
      context.go('/home1');
    }
  }

  void _skipOnboarding() async {
    await _markOnboardingComplete();
    if (mounted) {
      // CHANGED: Redirect to /home1 instead of /dashboard
      context.go('/home1');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final fontSize = fontProvider.fontSize;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Column(
              children: [
                // Header with skip button
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Senior Surfers',
                        style: TextStyle(
                          fontSize: fontSize * 1.2,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF27445D),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _skipOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: fontSize * 0.9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicator
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: LinearProgressIndicator(
                    value: (currentPage + 1) / onboardingSteps.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      onboardingSteps[currentPage].color,
                    ),
                    minHeight: 4,
                  ),
                ),

                // Main content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (mounted) {
                        setState(() {
                          currentPage = index;
                        });

                        // Auto-speak if TTS is enabled
                        if (_isTtsEnabled) {
                          final step = onboardingSteps[index];
                          _speakText(
                            '${step.title}. ${step.description}. ${step.content}',
                          );
                        }
                      }
                    },
                    itemCount: onboardingSteps.length,
                    itemBuilder:
                        (context, index) => _buildOnboardingPage(
                          onboardingSteps[index],
                          isMobile,
                          fontSize,
                        ),
                  ),
                ),

                // Navigation buttons
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Row(
                    children: [
                      // Previous button
                      if (currentPage > 0)
                        SizedBox(
                          width: isMobile ? 80 : 100,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _previousPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(fontSize: fontSize * 0.9),
                            ),
                          ),
                        )
                      else
                        SizedBox(width: isMobile ? 80 : 100),

                      const Spacer(),

                      // Page indicators
                      Row(
                        children: List.generate(
                          onboardingSteps.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentPage == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  currentPage == index
                                      ? onboardingSteps[currentPage].color
                                      : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Next/Complete button
                      SizedBox(
                        width: isMobile ? 100 : 120,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onboardingSteps[currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    currentPage == onboardingSteps.length - 1
                                        ? 'Get Started'
                                        : 'Next',
                                    style: TextStyle(
                                      fontSize: fontSize * 0.9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingPage(
    OnboardingStep step,
    bool isMobile,
    double fontSize,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Icon - SIMPLIFIED to prevent graphics issues
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(step.icon, size: isMobile ? 64 : 80, color: step.color),
          ),

          const SizedBox(height: 40),

          // Title
          GestureDetector(
            onLongPress: () => _speakText(step.title),
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: fontSize * 1.8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          GestureDetector(
            onLongPress: () => _speakText(step.description),
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.w600,
                color: step.color,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Content
          GestureDetector(
            onLongPress: () => _speakText(step.content),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                step.content,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // TTS indicator
          if (_isTtsEnabled)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: step.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, size: 16, color: step.color),
                  const SizedBox(width: 4),
                  Text(
                    'Long press text to hear it read aloud',
                    style: TextStyle(
                      color: step.color,
                      fontSize: fontSize * 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Simplified data model
class OnboardingStep {
  final String title;
  final String description;
  final String content;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
    required this.color,
  });
}
