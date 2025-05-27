import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../practice_mode.dart'; // Import practice mode directly

class JoinMeet3Screen extends StatelessWidget {
  const JoinMeet3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define colors for consistency
    const backgroundColor = Color(0xFF1c1214);
    const textColor = Color(0xFFe6d9d9);
    const accentColor = Color(0xFFd4a1b1);
    const buttonColor = Color(0xFFf9b3c0);
    const dashboardButtonColor = Color(0xFF27445D);

    return WillPopScope(
      // Handle system back button press with go_router
      onWillPop: () async {
        context.pop();
        return false; // We handled navigation ourselves
      },
      child: DeviceFrame(
        device: Devices.android.onePlus8Pro,
        screen: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            iconTheme: const IconThemeData(color: textColor),
            title: const Text(
              'Meeting: ikz-dmfx-sht',
              style: TextStyle(color: textColor),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Use go_router to go back
                context.pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.ellipsisV),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Meeting interface placeholder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.users,
                            color: accentColor,
                            size: 80,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Meeting Room',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Waiting for others to join...',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Overlay the image on top
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Image.asset(
                              'assets/images/joinmeet4.jpg',
                              width: 300,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return const Text(
                                  'Image not found',
                                  style: TextStyle(color: Colors.red),
                                );
                              },
                            ),
                          ),

                          // Add buttons below the image
                          const SizedBox(height: 20),
                          // Row containing both buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Practice Mode Button
                              ElevatedButton(
                                onPressed: () {
                                  print('Practice Mode button pressed');
                                  // Use go_router for navigation to practice mode
                                  context.push('/practice');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dashboardButtonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Practice Mode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom control bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.microphoneSlash,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.videoSlash,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.desktop,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.users,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.commentAlt,
                        color: textColor,
                      ),
                      onPressed: () {},
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Use go_router to return to dashboard properly
                        context.go('/dashboard');
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
