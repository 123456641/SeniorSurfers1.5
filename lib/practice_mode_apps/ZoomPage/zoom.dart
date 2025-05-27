import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../games/zoom.dart';

class ZoomPage extends StatelessWidget {
  const ZoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice: Zoom'),
        backgroundColor: const Color(0xFF2D8CFF), // Zoom Blue
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Zoom Practice!',
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize * 1.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Learn how to use Zoom effectively with our interactive tutorials and practice exercises.',
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            if (isLargeScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTutorialSection(context, fontSizeProvider),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _buildQuizSection(context, fontSizeProvider)),
                ],
              )
            else
              Column(
                children: [
                  _buildTutorialSection(context, fontSizeProvider),
                  const SizedBox(height: 24),
                  _buildQuizSection(context, fontSizeProvider),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialSection(
    BuildContext context,
    FontSizeProvider fontSizeProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: const Color(0xFF2D8CFF), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Learn Zoom Basics',
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTutorialItem(
              'Joining a Meeting',
              'Learn how to join Zoom meetings using meeting links or IDs',
              fontSizeProvider,
            ),
            _buildTutorialItem(
              'Audio and Video',
              'Master your microphone and camera controls',
              fontSizeProvider,
            ),
            _buildTutorialItem(
              'Chat and Reactions',
              'Communicate effectively using chat and reaction features',
              fontSizeProvider,
            ),
            _buildTutorialItem(
              'Screen Sharing',
              'Share your screen with other participants',
              fontSizeProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection(
    BuildContext context,
    FontSizeProvider fontSizeProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: const Color(0xFF2D8CFF), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Test Your Knowledge',
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Take our interactive quiz to test your understanding of Zoom features and best practices.',
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ZoomQuizGame(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D8CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialItem(
    String title,
    String description,
    FontSizeProvider fontSizeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
