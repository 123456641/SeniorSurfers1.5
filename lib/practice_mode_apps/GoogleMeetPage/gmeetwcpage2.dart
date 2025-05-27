import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:go_router/go_router.dart';

class Gmeet3 extends StatelessWidget {
  const Gmeet3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DeviceFrame(
      device: Devices.ios.iPhone13,
      screen: const GMeetScreen(),
    );
  }
}

class GMeetScreen extends StatefulWidget {
  const GMeetScreen({Key? key}) : super(key: key);

  @override
  State<GMeetScreen> createState() => _GMeetScreenState();
}

class _GMeetScreenState extends State<GMeetScreen> {
  bool showCopyConfirmation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140C0F),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF7A6A6F),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Start a call',
                        style: TextStyle(
                          color: Color(0xFFA68A8F),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F2228),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Color(0xFFA68A8F), fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search contacts or dial a number',
                        hintStyle: TextStyle(
                          color: Color(0xFFA68A8F),
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFFA68A8F),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.link,
                          label: 'Create link',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.calendar_today,
                          label: 'Schedule',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.group,
                          label: 'Group call',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Suggestions label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Suggestions',
                        style: TextStyle(
                          color: Color(0xFFA68A8F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFA68A8F),
                        size: 16,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Suggestions contacts
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [],
                  ),
                ),

                const Spacer(),

                // Bottom modal
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3F2E33),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Share this joining info with people that you want in the meeting',
                        style: TextStyle(
                          color: Color(0xFFF1B6BC),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Meeting link
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A2F3E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'meet.google.com/wjf-wvcc-hry',
                                style: TextStyle(
                                  color: Color(0xFFF1B6BC),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  showCopyConfirmation = true;
                                });
                              },
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFFF1B6BC),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.share,
                              color: Color(0xFFF1B6BC),
                            ),
                            label: const Text(
                              'Share',
                              style: TextStyle(color: Color(0xFFF1B6BC)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF1B6BC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.login,
                              color: Color(0xFFF1B6BC),
                            ),
                            label: const Text(
                              'Join',
                              style: TextStyle(color: Color(0xFFF1B6BC)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF1B6BC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dismiss button
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Dismiss',
                            style: TextStyle(
                              color: Color(0xFFF1B6BC),
                              fontSize: 18,
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
          // Image overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  showCopyConfirmation
                      ? 'assets/images/createmeet5.jpg'
                      : 'assets/images/createmeet4.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        showCopyConfirmation
                            ? 'createmeet5.jpg not found'
                            : 'createmeet4.jpg not found',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
                if (showCopyConfirmation) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/practice');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Go back to practice mode',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5A2F3E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFA68A8F), size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFA68A8F), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required String name,
    required String email,
    required String imagePath,
    required bool hasGoogleMeet,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: const Color(0xFF5A2F3E),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A2F3E),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFA68A8F),
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (hasGoogleMeet)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF140C0F),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/google_meet_icon.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.video_call,
                              color: Colors.white,
                              size: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFC9B9BC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              email,
              style: const TextStyle(color: Color(0xFFA68A8F), fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarContact(String letter, Color backgroundColor) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
