import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'gmeetwcpage2.dart'; // Import the file containing Gmeet3

class GMeet2 extends StatelessWidget {
  const GMeet2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DeviceFrame(
          device: Devices.ios.iPhone13,
          screen: const GoogleMeetInterface(),
        ),
      ),
    );
  }
}

class GoogleMeetInterface extends StatefulWidget {
  const GoogleMeetInterface({Key? key}) : super(key: key);

  @override
  State<GoogleMeetInterface> createState() => _GoogleMeetInterfaceState();
}

class _GoogleMeetInterfaceState extends State<GoogleMeetInterface> {
  bool showFirstImage = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showFirstImage = !showFirstImage;
        });
      },
      child: Stack(
        children: [
          // Main content behind the image
          Scaffold(
            backgroundColor: const Color(0xFF1E1216),
            body: SafeArea(
              child: Column(
                children: [
                  // Status bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '6:25',
                          style: TextStyle(
                            color: Color(0xFFD6B9BB),
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_off,
                              color: Color(0xFFD6B9BB),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.signal_cellular_4_bar,
                              color: Color(0xFFD6B9BB),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.wifi,
                              color: Color(0xFFD6B9BB),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF6ECB3C),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '42',
                                style: TextStyle(
                                  color: Color(0xFF6ECB3C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.bolt,
                              color: Color(0xFFD6B9BB),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Color(0xFFD6B9BB),
                          size: 24,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Start a call',
                          style: TextStyle(
                            color: Color(0xFFD6B9BB),
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F2F3A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Color(0xFFD6B9BB), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Color(0xFFD6B9BB)),
                            decoration: InputDecoration(
                              hintText: 'Search contacts or dial a number',
                              hintStyle: TextStyle(color: Color(0xFFD6B9BB)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.link,
                            'Create link',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.calendar_today,
                            'Schedule',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.group,
                            'Group call',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Suggestions label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      children: [
                        Text(
                          'Suggestions',
                          style: TextStyle(
                            color: Color(0xFFD6B9BB),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFD6B9BB),
                          size: 12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contacts grid
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                        children: [],
                      ),
                    ),
                  ),

                  // Bottom navigation
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6B9BB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD6B9BB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6B9BB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image overlay - centered and positioned on top of everything
          Center(
            child: Container(
              width: 350, // Made bigger than previous size
              height: 200, // Made bigger than previous size
              child: Image.asset(
                showFirstImage
                    ? 'assets/images/createmeet2.jpg'
                    : 'assets/images/createmeet3.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Gmeet3()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF6F3B4A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFD6B9BB), size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFD6B9BB), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(String name, String email, String imageUrl) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E1216), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://storage.googleapis.com/a1aa/image/bf6626c6-06ec-468e-1b88-994eb62b45a6.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFFD6B9BB),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(color: Color(0xFFBFA6A9), fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContactWithInitial(
    String name,
    String email,
    String initial,
    Color backgroundColor,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E1216), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://storage.googleapis.com/a1aa/image/bf6626c6-06ec-468e-1b88-994eb62b45a6.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFFD6B9BB),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(color: Color(0xFFBFA6A9), fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
