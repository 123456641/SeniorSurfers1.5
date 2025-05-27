import 'package:flutter/material.dart';
import 'package:senior_surfers/practice_mode_apps/GoogleMeetPage/gmeetwcpage.dart';
import 'package:flutter/cupertino.dart';
import 'joinmeet.dart';
import 'gmeetwcpage1.dart';
// Import for additional tutorial pages
// import 'create_meeting.dart';
// import 'use_meeting_buttons.dart';

class GoogleMeetPage extends StatelessWidget {
  const GoogleMeetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size to adapt layouts
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 900;
    final isMediumScreen = screenSize.width > 600 && screenSize.width <= 900;
    final isSmallScreen = screenSize.width <= 600;

    // Adjust padding based on screen size
    final horizontalPadding =
        isLargeScreen
            ? 48.0
            : isMediumScreen
            ? 32.0
            : 16.0;

    // Adjust max width based on screen size
    final maxContentWidth =
        isLargeScreen
            ? 1100.0
            : isMediumScreen
            ? 700.0
            : double.infinity;

    // Adjust title size based on screen size
    final titleSize =
        isLargeScreen
            ? 48.0
            : isMediumScreen
            ? 40.0
            : 32.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF2F4F8)],
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 24.0 : 40.0,
                    bottom: isSmallScreen ? 8.0 : 10.0,
                  ),
                  child: Text(
                    'Google Meet',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: const Color(0xFF1A73E8),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Text(
                  'Practice tutorials',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16.0 : 18.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F6368),
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use GridView for larger screens
                      if (isLargeScreen) {
                        return GridView(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          children: _buildTutorialItems(context),
                        );
                      } else if (isMediumScreen) {
                        // Use a different aspect ratio for medium screens
                        return GridView(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          children: _buildTutorialItems(context),
                        );
                      } else {
                        // Use a ListView for mobile screens
                        return ListView(children: _buildTutorialItems(context));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTutorialItems(BuildContext context) {
    // Define all tutorial items
    final List<Map<String, dynamic>> tutorialData = [
      {
        'title': 'How to join in a Meeting',
        'description':
            'Learn how to join Google Meet sessions using links or codes',
        'icon': Icons.login_rounded,
        'color': const Color(0xFF1A73E8),
        'onTap': () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const JoinMeet1()));
        },
      },
      {
        'title': 'How to create a Meeting',
        'description': 'Learn how to start your own Google Meet sessions',
        'icon': Icons.add_box_rounded,
        'color': const Color(0xFF34A853),
        'onTap': () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const Gmeet()));
        },
      },
      {
        'title': 'How to use the Meeting buttons',
        'description':
            'Learn about camera, microphone, chat and other controls',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFEA4335),
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UseMeetingButtons()),
          );
        },
      },
      {
        'title': 'Try Signing In to Google Meet',
        'description': 'A simulated environment for signing in to Google Meet',
        'icon': Icons.person_rounded,
        'color': const Color(0xFFFBBC04),
        'onTap': () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const JoinMeet1()));
        },
      },
    ];

    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width <= 600;

    // Build the tutorial cards
    return tutorialData.map((tutorial) {
      if (isSmallScreen) {
        // Add spacing between cards on mobile
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildTutorialCard(
            context,
            title: tutorial['title'],
            description: tutorial['description'],
            icon: tutorial['icon'],
            color: tutorial['color'],
            onTap: tutorial['onTap'],
          ),
        );
      } else {
        // No additional padding needed for grid layout
        return _buildTutorialCard(
          context,
          title: tutorial['title'],
          description: tutorial['description'],
          icon: tutorial['icon'],
          color: tutorial['color'],
          onTap: tutorial['onTap'],
        );
      }
    }).toList();
  }

  Widget _buildTutorialCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Check screen size to adjust card layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 600;
    final isMediumScreen = screenWidth > 600 && screenWidth <= 900;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
          child: Row(
            children: [
              Container(
                height: isSmallScreen ? 50 : 60,
                width: isSmallScreen ? 50 : 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: isSmallScreen ? 26 : 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF202124),
                      ),
                      // If on medium screen with grid layout, limit to 2 lines
                      maxLines: isMediumScreen ? 2 : null,
                      overflow: isMediumScreen ? TextOverflow.ellipsis : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: const Color(0xFF5F6368),
                      ),
                      // If on medium screen with grid layout, limit to 3 lines
                      maxLines: isMediumScreen ? 3 : null,
                      overflow: isMediumScreen ? TextOverflow.ellipsis : null,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF5F6368),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder classes for the new tutorial pages
class CreateMeeting extends StatelessWidget {
  const CreateMeeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Meeting')),
      body: const Center(child: Text('Create Meeting Tutorial Content')),
    );
  }
}

class UseMeetingButtons extends StatelessWidget {
  const UseMeetingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Controls')),
      body: const Center(child: Text('Meeting Controls Tutorial Content')),
    );
  }
}
