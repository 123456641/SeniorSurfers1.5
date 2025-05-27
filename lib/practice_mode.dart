import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'practice_mode_apps/GmailPage/gmail.dart';
import 'practice_mode_apps/GoogleMeetPage/googleMeet.dart';
import 'practice_mode_apps/ZoomPage/zoom.dart';
import 'practice_mode_apps/ViberPage/viber.dart';
import 'practice_mode_apps/WhatsappPage/whatsapp.dart';
import 'practice_mode_apps/CliqqPage/cliqq.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';

class PracticeModePage extends StatelessWidget {
  final List<_AppButtonData> apps = [
    _AppButtonData(
      "Google Meet",
      "assets/images/practice/gmeet.png",
      GoogleMeetPage(),
    ),
    _AppButtonData("Zoom", "assets/images/practice/zoom.png", ZoomPage()),
    _AppButtonData("Gmail", "assets/images/practice/gmail.png", GmailPage()),
    _AppButtonData("Viber", "assets/images/practice/viber.png", ViberPage()),
    _AppButtonData(
      "WhatsApp",
      "assets/images/practice/whatsapp.png",
      WhatsAppPage(),
    ),
    _AppButtonData("CLIQQ", "assets/images/practice/cliqq.png", CliqqPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/practice',
      pageTitle: 'Practice Mode',
      child: _buildPracticeGrid(),
    );
  }

  Widget _buildPracticeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column count based on width
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children:
              apps.map((app) {
                return GestureDetector(
                  onTap: () {
                    // For now, we'll keep using MaterialPageRoute for the app pages
                    // since they don't appear to have dedicated routes in the router
                    // You could add these to your router config if needed
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => app.page),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(app.imagePath, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class _AppButtonData {
  final String label;
  final String imagePath;
  final Widget page;

  _AppButtonData(this.label, this.imagePath, this.page);
}
