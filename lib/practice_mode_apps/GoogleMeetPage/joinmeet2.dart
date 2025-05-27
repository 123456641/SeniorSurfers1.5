import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'joinmeet3.dart';

class JoinMeet2 extends StatefulWidget {
  const JoinMeet2({super.key});

  @override
  State<JoinMeet2> createState() => _JoinMeet2State();
}

class _JoinMeet2State extends State<JoinMeet2> {
  // Add state variables to track image visibility
  bool showFirstImage = true;
  bool showSecondImage = false;

  @override
  Widget build(BuildContext context) {
    // Colors from the original HTML
    const backgroundColor = Color(0xFF1c1214);
    const textColor = Color(0xFFe6d9d9);
    const secondaryTextColor = Color(0xFFb9a7a7);
    const accentColor = Color(0xFFd4a1b1);
    const buttonColor = Color(0xFFf9b3c0);
    const borderColor = Color(0xFF3a2a2d);
    const videoPreviewColor = Color(0xFFd4c0c4);
    const avatarBackgroundColor = Color(0xFF005696);
    const iconButtonColor = Color(0xFF6b6b6b);

    return DeviceFrame(
      device: Devices.android.onePlus8Pro,
      screen: Stack(
        children: [
          // Base app UI
          GestureDetector(
            onTap: () {
              setState(() {
                if (showFirstImage) {
                  showFirstImage = false;
                  showSecondImage = true;
                }
              });
            },
            child: Scaffold(
              backgroundColor: backgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              FontAwesomeIcons.arrowLeft,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  FontAwesomeIcons.volumeUp,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: textColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    FontAwesomeIcons.exclamation,
                                    color: textColor,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),

                              // Meeting code
                              const Text(
                                'ikz-dmfx-sht',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Video preview
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Container for video preview
                                  Container(
                                    width: 180,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      color: videoPreviewColor,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: const BoxDecoration(
                                            color: avatarBackgroundColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'B',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 48,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Video control
                                        Positioned(
                                          bottom: 16,
                                          left: 24,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                FontAwesomeIcons.videoSlash,
                                                color: iconButtonColor,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Mic control
                                        Positioned(
                                          bottom: 16,
                                          right: 24,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                FontAwesomeIcons
                                                    .microphoneSlash,
                                                color: iconButtonColor,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                        FontAwesomeIcons.arrowUp,
                                        size: 14,
                                      ),
                                      label: const Text('Share screen'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: accentColor,
                                        side: BorderSide(color: accentColor),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                        FontAwesomeIcons.columns,
                                        size: 14,
                                      ),
                                      label: const Text('Use Companion Mode'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: accentColor,
                                        side: BorderSide(color: accentColor),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Status text
                              Text(
                                'No one is in the call yet',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Divider
                              Divider(color: borderColor, thickness: 1),
                              const SizedBox(height: 16),

                              // Security info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.shield,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text:
                                                'This meeting is secured with cloud encryption. ',
                                          ),
                                          TextSpan(
                                            text:
                                                'Learn more about cloud encryption',
                                            style: TextStyle(
                                              color: accentColor,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Joining info
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.infoCircle,
                                        color: accentColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Joining information',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      FontAwesomeIcons.shareAlt,
                                      color: accentColor,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Join button
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const JoinMeet3Screen(),
                                    ),
                                  );
                                },
                                icon: const Icon(FontAwesomeIcons.video),
                                label: const Text('Join'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: borderColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // User info
                              Text(
                                'Joining as',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: avatarBackgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'L',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'user@gmail.com',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      '(Switch)',
                                      style: TextStyle(
                                        color: buttonColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // First image overlay (on top of everything)
          if (showFirstImage)
            Align(
              alignment: Alignment.center, // Center the image on screen
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 200,
                ), // Moved higher (increased bottom padding)
                child: Image.asset(
                  'assets/images/joinmeet2.jpg',
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // Second image overlay (on top of everything)
          if (showSecondImage)
            Align(
              alignment: Alignment.center, // Center the image on screen
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 150,
                ), // Moved lower (increased top padding)
                child: Image.asset(
                  'assets/images/joinmeet3.jpg',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
