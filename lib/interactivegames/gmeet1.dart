// File: gmeet_join_tutorial.dart - How to Join a Google Meet Meeting Tutorial
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../widgets/scaled_text.dart';
import '../../dashboardsidebar.dart';

class GoogleMeetJoinTutorial extends StatefulWidget {
  const GoogleMeetJoinTutorial({Key? key}) : super(key: key);

  @override
  State<GoogleMeetJoinTutorial> createState() => _GoogleMeetJoinTutorialState();
}

class _GoogleMeetJoinTutorialState extends State<GoogleMeetJoinTutorial>
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
      title: "Welcome to Joining Google Meet!",
      description:
          "Let's learn how to join a Google Meet meeting step by step. This tutorial will guide you through the entire process.",
      content:
          "Joining a Google Meet meeting is easy once you know the steps! We'll show you exactly how to click the meeting link, handle permissions, check your settings, and join the meeting. Don't worry - we'll take it slow and explain everything clearly!",
      icon: Icons.waving_hand,
      color: Colors.blue,
      imagePath: null,
    ),
    TutorialStep(
      title: "Step 1: Find and Click the Meeting Link",
      description:
          "First, you need to locate and click on the meeting link that was provided to you.",
      content:
          "Look for your meeting link - it might be in:\n\n• An email invitation\n• A text message\n• A calendar appointment\n• A chat message from a friend or family member\n\nThe link usually looks like: meet.google.com/abc-defg-hij\n\nSimply tap or click on this link. Your device will automatically open Google Meet and take you to the meeting room!",
      icon: Icons.link,
      color: Colors.green,
      imagePath: "assets/images/tutorial/meeting_link.png",
    ),
    TutorialStep(
      title: "Step 2: Handle App Permissions",
      description:
          "Your phone will open Google Meet and may ask for permissions.",
      content:
          "When Google Meet opens, it might ask for permission to use:\n\n• Your camera (to show your video)\n• Your microphone (to hear your voice)\n\nYou'll see a popup asking for these permissions. Choose one of these options:\n\n• 'While using the app' - Recommended for most people\n• 'Only this time' - If you prefer more privacy\n\nDon't worry - you can always change these settings later!",
      icon: Icons.security,
      color: Colors.orange,
      imagePath: "assets/images/tutorial/permissions.png",
    ),
    TutorialStep(
      title: "Step 3: Check Your Camera and Microphone",
      description:
          "Before joining, let's make sure your settings are ready for the meeting.",
      content:
          "Take a moment to check your device settings:\n\n🎥 Camera Settings:\n• If you want others to see you, make sure your camera is ON\n• If you prefer privacy, you can keep it OFF\n\n🎤 Microphone Settings:\n• Turn ON if you plan to speak during the meeting\n• You can mute/unmute anytime during the call\n\nYou'll see preview of yourself if your camera is on. Don't worry about how you look - everyone is understanding!",
      icon: Icons.settings,
      color: Colors.purple,
      imagePath: "assets/images/tutorial/camera_mic_settings.png",
    ),
    TutorialStep(
      title: "Step 4: Ask to Join the Meeting",
      description: "Now it's time to request entry into the meeting!",
      content:
          "You'll see a button that says 'Ask to Join' - this is your gateway to the meeting!\n\n1. Click the 'Ask to Join' button\n2. This sends a polite request to the meeting organizer\n3. Wait patiently - the organizer will see your request\n4. Once they approve, you'll automatically enter the meeting\n5. You're now connected and can participate!\n\nRemember: The organizer might take a moment to notice and approve your request. Be patient!",
      icon: Icons.meeting_room,
      color: Colors.teal,
      imagePath: "assets/images/tutorial/ask_to_join.png",
    ),
    TutorialStep(
      title: "Congratulations! You're In! 🎉",
      description: "You've successfully joined your Google Meet meeting!",
      content:
          "Well done! You're now part of the meeting and can:\n\n✅ See and hear other participants\n✅ Turn your camera on/off anytime\n✅ Mute/unmute your microphone\n✅ Use the chat feature to type messages\n✅ Leave the meeting when you're ready\n\nHelpful Meeting Tips:\n• Mute yourself when not speaking\n• Speak clearly and at normal volume\n• Don't worry about technical issues - ask for help!\n• Enjoy connecting with others!",
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
              'Congratulations! You\'ve successfully learned how to join Google Meet meetings. You\'re now ready to participate in video calls with family and friends!',
              style: TextStyle(
                fontSize: (isMobile ? 16 : 18) * scaleFactor,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            actions: [
              // Only one button - Back to Tutorials
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
          currentPage: '/gmeet-join-tutorial',
          pageTitle: 'Join Google Meet Tutorial',
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
        return "Don't worry if joining meetings seems confusing at first - it gets easier with practice!";
      case 1:
        return "Meeting links are usually sent via email or text message. Check both if you can't find yours!";
      case 2:
        return "It's okay to deny permissions initially - you can always change them later in your phone settings.";
      case 3:
        return "Don't worry about how you look on camera - everyone understands we're all learning!";
      case 4:
        return "If the organizer doesn't approve your request immediately, they might be busy. Be patient!";
      case 5:
        return "You've got this! The more you practice joining meetings, the more confident you'll become.";
      default:
        return "Take your time and don't hesitate to ask for help if you need it!";
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
