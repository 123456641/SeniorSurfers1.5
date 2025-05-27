import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:device_frame/device_frame.dart';
import 'gmeetwcpage.dart'; // Import the file containing GMeet2

class Gmeet extends StatelessWidget {
  const Gmeet({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceFrame(
      device: Devices.android.samsungGalaxyS20,
      isFrameVisible: true,
      screen: Stack(
        children: [
          // Main content behind the image
          Scaffold(
            backgroundColor: const Color(0xFF1a0f0f),
            body: SafeArea(
              child: Column(
                children: [
                  // Status bar simulation
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text(
                              "5:14",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFd9c7c7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              FontAwesomeIcons.commentAlt,
                              size: 12,
                              color: Color(0xFFd9c7c7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "...",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFd9c7c7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.moon,
                              size: 12,
                              color: Color(0xFFd9c7c7),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              FontAwesomeIcons.bellSlash,
                              size: 12,
                              color: Color(0xFFd9c7c7),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "5G",
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFFd9c7c7),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 20,
                              height: 12,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFd9c7c7)),
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF0f1a0f),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "19",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFa3d97a),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              FontAwesomeIcons.bolt,
                              size: 12,
                              color: Color(0xFFd9c7c7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4f3a44),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.bars,
                            color: Color(0xFFd9c7c7),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: TextField(
                              style: TextStyle(
                                color: Color(0xFFd9c7c7),
                                fontSize: 18,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search contacts',
                                hintStyle: TextStyle(color: Color(0xFFd9c7c7)),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7f4a5a),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  FontAwesomeIcons.keyboard,
                                  size: 14,
                                  color: Color(0xFFd9c7c7),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Code",
                                  style: TextStyle(
                                    color: Color(0xFFd9c7c7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0f5a9f),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF0f5a9f),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFFd9c7c7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Meetings Label
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Meetings",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFd9c7c7),
                        ),
                      ),
                    ),
                  ),

                  // Meeting Item
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6f4a54),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                FontAwesomeIcons.calendarAlt,
                                color: Color(0xFFd9c7c7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Wellness Meeting",
                                  style: TextStyle(
                                    color: Color(0xFFd9c7c7),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "8-10 am",
                                  style: TextStyle(
                                    color: Color(0xFFd9c7c7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf4a6b0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            "Now",
                            style: TextStyle(
                              color: Color(0xFF4f3a44),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 8),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFFf4a6b0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GMeet2()),
                  );
                },
                label: Row(
                  children: const [
                    Icon(FontAwesomeIcons.video, color: Color(0xFF4f3a44)),
                    SizedBox(width: 8),
                    Text("New", style: TextStyle(color: Color(0xFF4f3a44))),
                  ],
                ),
              ),
            ),
          ),

          // Image overlay - positioned on top of everything
          Positioned(
            top: 400, // Adjust vertical position as needed
            left: 50, // Adjust horizontal position as needed
            child: Container(
              width: 280, // Made smaller than original (was double.infinity)
              height: 200, // Set a specific height to make it smaller
              child: Image.asset(
                'assets/images/createmeet1.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
