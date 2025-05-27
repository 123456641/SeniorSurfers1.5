// lib/progress/progress.dart

import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({Key? key}) : super(key: key);

  // Dummy progress data (can be dynamic in future)
  final List<_TutorialProgress> progressData = const [
    _TutorialProgress("Google Meet", "assets/images/practice/gmeet.png", 0.7),
    _TutorialProgress("Zoom", "assets/images/practice/zoom.png", 0.3),
    _TutorialProgress("Gmail", "assets/images/practice/gmail.png", 0.0),
    _TutorialProgress("Viber", "assets/images/practice/viber.png", 0.5),
    _TutorialProgress("WhatsApp", "assets/images/practice/whatsapp.png", 1.0),
    _TutorialProgress("CLIQQ", "assets/images/practice/cliqq.png", 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Progress'),
        backgroundColor: const Color(0xFF27445D),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: progressData.length,
        itemBuilder: (context, index) {
          final tutorial = progressData[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Image.asset(
                tutorial.imagePath,
                width: 50,
                height: 50,
              ),
              title: Text(
                tutorial.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: tutorial.progress,
                    backgroundColor: Colors.grey[300],
                    color: const Color(0xFF27445D),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 4),
                  Text('${(tutorial.progress * 100).toStringAsFixed(0)}% completed'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TutorialProgress {
  final String label;
  final String imagePath;
  final double progress; // 0.0 to 1.0

  const _TutorialProgress(this.label, this.imagePath, this.progress);
}
