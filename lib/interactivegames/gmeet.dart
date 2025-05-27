// File: gmeet1.dart - Improved Contrast & UX Version
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../widgets/scaled_text.dart';
import '../../dashboardsidebar.dart';

class GoogleMeetTutorial extends StatefulWidget {
  const GoogleMeetTutorial({Key? key}) : super(key: key);

  @override
  State<GoogleMeetTutorial> createState() => _GoogleMeetTutorialState();
}

class _GoogleMeetTutorialState extends State<GoogleMeetTutorial>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  bool isPlaying = false;
  bool autoRead = true; // Auto-read enabled by default
  int currentStep = 0;
  double localFontSize = 18.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<TutorialStep> tutorialSteps = [
    TutorialStep(
      title: "Welcome to Google Meet Installation!",
      description:
          "Let's learn how to install Google Meet step by step. This tutorial will guide you through the entire process.",
      content:
          "Google Meet is a video calling app that helps you stay connected with family and friends. Don't worry - we'll take it slow and explain everything clearly!",
      icon: Icons.waving_hand,
      color: Colors.blue,
      imagePath: null,
    ),
    TutorialStep(
      title: "Step 1: Find Your App Store",
      description:
          "First, we need to find where to download apps on your phone.",
      content:
          "Look for the app store on your phone:\n\n• On Android phones: Look for 'Play Store' (it has a colorful triangle icon)\n• On iPhones: Look for 'App Store' (it has a blue icon with a white 'A')\n\nTap on it to open. Don't worry if it takes a moment to load!",
      icon: Icons.store,
      color: Colors.green,
      imagePath: "assets/images/tutorial/app_stores.png",
    ),
    TutorialStep(
      title: "Step 2: Search for Google Meet",
      description: "Now we'll search for the Google Meet app.",
      content:
          "1. Look at the top of your screen - you'll see a search bar (it looks like a white rectangle)\n\n2. Tap on this search bar\n\n3. Type 'Google Meet' using your keyboard\n\n4. The app should appear in the search results. Look for the one made by 'Google LLC'",
      icon: Icons.search,
      color: Colors.orange,
      imagePath: "assets/images/tutorial/search_google_meet.png",
    ),
    TutorialStep(
      title: "Step 3: Install the App",
      description: "Time to download and install Google Meet!",
      content:
          "1. Tap on the Google Meet app from the search results\n\n2. You'll see a button that says 'Install' or 'Get'\n\n3. Tap this button\n\n4. Your phone might ask for your password or fingerprint - this is normal!\n\n5. Wait for the app to download (you'll see a progress circle)",
      icon: Icons.download,
      color: Colors.purple,
      imagePath: "assets/images/tutorial/install_button.png",
    ),
    TutorialStep(
      title: "Step 4: Open Google Meet",
      description: "Great! Now let's open your new app.",
      content:
          "1. Once installation is complete, you'll see an 'Open' button - tap it!\n\n2. OR you can find the Google Meet icon on your phone's home screen\n\n3. The Google Meet icon looks like a video camera with colorful background\n\n4. Tap the icon to open the app",
      icon: Icons.videocam,
      color: Colors.teal,
      imagePath: "assets/images/tutorial/google_meet_icon.png",
    ),
    TutorialStep(
      title: "Congratulations! 🎉",
      description: "You've successfully installed Google Meet!",
      content:
          "Well done! You now have Google Meet installed on your phone. \n\nNext steps:\n• The app might ask for permissions (camera, microphone) - these are needed for video calls\n• You can sign in with your Google account\n• You're ready to make video calls with family and friends!\n\nRemember: Take your time, and don't hesitate to ask for help if needed.",
      icon: Icons.celebration,
      color: Colors.pink,
      imagePath: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Auto-read the first step after a brief delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (autoRead && mounted) {
        _speakCurrentStep();
      }
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4); // Slower speech for seniors
    await flutterTts.setVolume(0.8);
    await flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    } else {
      await flutterTts.speak(text);
    }
  }

  Future<void> _speakCurrentStep() async {
    final step = tutorialSteps[currentStep];
    final fullText = "${step.title}. ${step.description}. ${step.content}";
    await _speak(fullText);
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  }

  void _nextStep() {
    if (currentStep < tutorialSteps.length - 1) {
      setState(() {
        currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
      _stopSpeaking();

      // Auto-read next step if enabled
      if (autoRead) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _speakCurrentStep();
        });
      }
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
      _stopSpeaking();

      // Auto-read previous step if enabled
      if (autoRead) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _speakCurrentStep();
        });
      }
    }
  }

  void _showSettingsPopup() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final scaleFactor = localFontSize / 16.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 20 : 24,
                      right: isMobile ? 20 : 24,
                      top: isMobile ? 20 : 24,
                      bottom:
                          MediaQuery.of(context).viewInsets.bottom +
                          (isMobile ? 20 : 24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with Aa icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade800.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'A',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    'a',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Text & Audio Settings',
                                    style: TextStyle(
                                      fontSize:
                                          (isMobile ? 18 : 20) * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Adjust text size and reading options',
                                    style: TextStyle(
                                      fontSize:
                                          (isMobile ? 14 : 16) * scaleFactor,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 20 : 24),

                        // Auto-Read Toggle
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.play_circle,
                                  color: Colors.white,
                                  size: isMobile ? 24 : 28,
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Auto-Read Steps',
                                      style: TextStyle(
                                        fontSize:
                                            (isMobile ? 16 : 18) * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Automatically read each step aloud',
                                      style: TextStyle(
                                        fontSize:
                                            (isMobile ? 12 : 14) * scaleFactor,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: isMobile ? 1.2 : 1.4,
                                child: Switch(
                                  value: autoRead,
                                  onChanged: (value) {
                                    setState(() {
                                      autoRead = value;
                                    });
                                    setModalState(() {
                                      autoRead = value;
                                    });
                                  },
                                  activeColor: Colors.green.shade600,
                                  activeTrackColor: Colors.green.shade200,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Manual Read Button
                        Container(
                          width: double.infinity,
                          height: isMobile ? 56 : 64,
                          child: ElevatedButton.icon(
                            onPressed: () => _speakCurrentStep(),
                            icon: Icon(
                              isSpeaking ? Icons.stop_circle : Icons.volume_up,
                              size: isMobile ? 20 : 24,
                            ),
                            label: Text(
                              isSpeaking
                                  ? 'Stop Reading'
                                  : 'Read This Step Aloud',
                              style: TextStyle(
                                fontSize: (isMobile ? 14 : 16) * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isSpeaking
                                      ? Colors.red.shade600
                                      : Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Font Size Control
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.text_fields,
                                      color: Colors.white,
                                      size: isMobile ? 24 : 28,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Text Size',
                                          style: TextStyle(
                                            fontSize:
                                                (isMobile ? 16 : 18) *
                                                scaleFactor,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Adjust text size for better reading',
                                          style: TextStyle(
                                            fontSize:
                                                (isMobile ? 12 : 14) *
                                                scaleFactor,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade600,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${localFontSize.round()}px',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 16 : 20),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: localFontSize,
                                      min: 12.0,
                                      max: 32.0,
                                      divisions: 20,
                                      activeColor: Colors.purple.shade600,
                                      inactiveColor: Colors.purple.shade200,
                                      thumbColor: Colors.purple.shade700,
                                      onChanged: (value) {
                                        setState(() {
                                          localFontSize = value;
                                        });
                                        setModalState(() {
                                          localFontSize = value;
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 16 : 20),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showCompletionDialog() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final scaleFactor = localFontSize / 16.0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              'Tutorial Complete! 🎉',
              style: TextStyle(
                fontSize: (isMobile ? 20 : 24) * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: Text(
              'Congratulations! You\'ve successfully learned how to install Google Meet. You\'re now ready to connect with family and friends through video calls!',
              style: TextStyle(
                fontSize: (isMobile ? 16 : 18) * scaleFactor,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            actions: [
              // Only one button now - Back to Tutorials
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/tutorials');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Back to Tutorials',
                    style: TextStyle(
                      fontSize: (isMobile ? 16 : 18) * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/gmeet-tutorial',
          pageTitle: 'Google Meet Tutorial',
          child: _buildTutorialContent(context, fontProvider),
        );
      },
    );
  }

  Widget _buildTutorialContent(
    BuildContext context,
    FontSizeProvider fontProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final scaleFactor = localFontSize / 16.0;

    return SafeArea(
      child: Column(
        children: [
          // Progress Indicator - Clean Design
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${currentStep + 1} of ${tutorialSteps.length}',
                      style: TextStyle(
                        fontSize: (isMobile ? 16 : 18) * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tutorialSteps[currentStep].color.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tutorialSteps[currentStep].color.withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        '${((currentStep + 1) / tutorialSteps.length * 100).round()}%',
                        style: TextStyle(
                          fontSize: (isMobile ? 12 : 14) * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                LinearProgressIndicator(
                  value: (currentStep + 1) / tutorialSteps.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tutorialSteps[currentStep].color,
                  ),
                  minHeight: isMobile ? 6 : 8,
                ),
              ],
            ),
          ),

          // Main Tutorial Content - Scrollable
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Header - Clean Layout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              decoration: BoxDecoration(
                                color: tutorialSteps[currentStep].color
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: tutorialSteps[currentStep].color
                                      .withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                tutorialSteps[currentStep].icon,
                                size:
                                    (isMobile ? 28 : 36) *
                                    scaleFactor.clamp(0.8, 1.5),
                                color: tutorialSteps[currentStep].color,
                              ),
                            ),
                            SizedBox(width: isMobile ? 16 : 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tutorialSteps[currentStep].title,
                                    style: TextStyle(
                                      fontSize:
                                          (isMobile ? 20 : 26) * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Text(
                                    tutorialSteps[currentStep].description,
                                    style: TextStyle(
                                      fontSize:
                                          (isMobile ? 16 : 18) * scaleFactor,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Tutorial Image (if available)
                        if (tutorialSteps[currentStep].imagePath != null)
                          Center(
                            child: Container(
                              height:
                                  (isMobile ? 180 : 240) *
                                  scaleFactor.clamp(0.8, 1.3),
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? screenWidth * 0.85 : 450,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  tutorialSteps[currentStep].imagePath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade50,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size:
                                                (isMobile ? 40 : 56) *
                                                scaleFactor,
                                            color: Colors.grey.shade400,
                                          ),
                                          SizedBox(height: isMobile ? 8 : 12),
                                          Text(
                                            'Tutorial Image',
                                            style: TextStyle(
                                              fontSize:
                                                  (isMobile ? 14 : 16) *
                                                  scaleFactor,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        if (tutorialSteps[currentStep].imagePath != null)
                          SizedBox(height: isMobile ? 20 : 28),

                        // Tutorial Content - High Contrast
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            tutorialSteps[currentStep].content,
                            style: TextStyle(
                              fontSize: (isMobile ? 16 : 18) * scaleFactor,
                              height: 1.6,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 20 : 28),

                        // Helpful Tips Box - High Contrast
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.amber.shade700,
                                size: (isMobile ? 24 : 28) * scaleFactor,
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Helpful Tip',
                                      style: TextStyle(
                                        fontSize:
                                            (isMobile ? 16 : 18) * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: isMobile ? 6 : 8),
                                    Text(
                                      _getHelpfulTip(currentStep),
                                      style: TextStyle(
                                        fontSize:
                                            (isMobile ? 14 : 16) * scaleFactor,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Extra padding for bottom navigation
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Navigation Controls with Aa Settings Button
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous Button
                  SizedBox(
                    width: isMobile ? 90 : 110,
                    child: ElevatedButton(
                      onPressed: currentStep > 0 ? _previousStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: isMobile ? 16 : 18),
                          SizedBox(width: isMobile ? 4 : 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: (isMobile ? 12 : 14) * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isMobile ? 8 : 12),

                  // Aa Settings Button (Popup)
                  SizedBox(
                    width: isMobile ? 50 : 60,
                    child: ElevatedButton(
                      onPressed: _showSettingsPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: (isMobile ? 12 : 14) * scaleFactor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'a',
                            style: TextStyle(
                              fontSize: (isMobile ? 16 : 18) * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isMobile ? 8 : 12),

                  // Next/Finish Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          currentStep < tutorialSteps.length - 1
                              ? _nextStep
                              : () => _showCompletionDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tutorialSteps[currentStep].color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentStep < tutorialSteps.length - 1
                                ? 'Next Step'
                                : 'Complete',
                            style: TextStyle(
                              fontSize: (isMobile ? 14 : 16) * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: isMobile ? 6 : 8),
                          Icon(
                            currentStep < tutorialSteps.length - 1
                                ? Icons.arrow_forward
                                : Icons.check_circle,
                            size: isMobile ? 16 : 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHelpfulTip(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return "Take your time with this tutorial. You can replay any step or use the 'Read Aloud' feature!";
      case 1:
        return "Can't find the app store? Ask a family member to help you locate it on your phone.";
      case 2:
        return "Make sure you're connected to Wi-Fi for faster searching and downloading.";
      case 3:
        return "The download might take a few minutes depending on your internet speed. Be patient!";
      case 4:
        return "You can also find Google Meet by swiping up from the bottom of your phone to see all apps.";
      case 5:
        return "Congratulations! Remember, practice makes perfect. Don't worry about making mistakes.";
      default:
        return "You're doing great! Take breaks if you need them.";
    }
  }
}

// Data model for tutorial steps
class TutorialStep {
  final String title;
  final String description;
  final String content;
  final IconData icon;
  final Color color;
  final String? imagePath;

  TutorialStep({
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
    required this.color,
    this.imagePath,
  });
}
