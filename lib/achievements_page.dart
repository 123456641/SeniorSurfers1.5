import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'services/tts_service.dart'; // Add TTS import

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final supabase = Supabase.instance.client;
  List<Achievement> achievements = [];
  bool isLoading = true;
  String? errorMessage;
  bool _isTtsEnabled = false; // Track TTS setting

  @override
  void initState() {
    super.initState();
    _loadAchievements();
    _loadTtsPreference(); // Load TTS setting
  }

  // Load TTS preference from user settings
  Future<void> _loadTtsPreference() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase
                .from('users')
                .select('tts_enabled')
                .eq('id', user.id)
                .single();

        setState(() {
          _isTtsEnabled = response['tts_enabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading TTS preference: $e');
    }
  }

  // Function to speak text when long pressed
  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      try {
        await TTSService().speak(text);

        // Show feedback to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reading: ${text.length > 30 ? text.substring(0, 30) + "..." : text}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF27445D),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error in TTS: $e');
      }
    } else if (!_isTtsEnabled) {
      // Show instruction to enable TTS
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.volume_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enable "Read Text Aloud" in Settings to use this feature',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/settingsD'),
            ),
          ),
        );
      }
    }
  }

  // Custom widget for long-pressable text
  Widget _buildLongPressText({
    required String text,
    required TextStyle style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GestureDetector(
      onLongPress: () => _speakText(text),
      child: Container(
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user's game statistics
      final user = supabase.auth.currentUser;
      Map<String, dynamic> stats = {};

      if (user != null) {
        // Fetch user's Google Meet Adventure game progress from Supabase
        final gameProgressResponse =
            await supabase
                .from('game_progress')
                .select('*')
                .eq('user_id', user.id)
                .eq('game_type', 'Google Meet Adventure')
                .maybeSingle();

        // Fetch user's unlocked achievements
        final achievementsResponse = await supabase
            .from('user_achievements')
            .select('achievement_id')
            .eq('user_id', user.id);

        final unlockedAchievements = Set<String>.from(
          (achievementsResponse as List).map((a) => a['achievement_id']),
        );

        // Calculate statistics based on adventure game progress
        stats = _calculateGameStats(gameProgressResponse, unlockedAchievements);
      }

      // Define all available achievements based on Google Meet Adventure Game
      achievements = [
        Achievement(
          id: 'hello_emma',
          title: 'Hello, Emma!',
          description: 'Successfully joined your first Google Meet call',
          imagePath: 'assets/images/badges/badge1.png',
          unlocked:
              stats['unlockedAchievements']?.contains('hello_emma') ?? false,
          requirement: 1,
          currentProgress: stats['levelsCompleted'] >= 1 ? 1 : 0,
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'camera_ready',
          title: 'I Can See You!',
          description: 'Successfully turned on your camera for the first time',
          imagePath: 'assets/images/badges/badge2.png',
          unlocked:
              stats['unlockedAchievements']?.contains('camera_ready') ?? false,
          requirement: 2,
          currentProgress:
              stats['levelsCompleted'] >= 2
                  ? 2
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'voice_activated',
          title: 'Can You Hear Me Now?',
          description: 'Successfully turned on your microphone',
          imagePath: 'assets/images/badges/badge3.png',
          unlocked:
              stats['unlockedAchievements']?.contains('voice_activated') ??
              false,
          requirement: 3,
          currentProgress:
              stats['levelsCompleted'] >= 3
                  ? 3
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'family_reunion',
          title: 'Family Reunion Host',
          description: 'Added family members to a Google Meet call',
          imagePath: 'assets/images/badges/badge4.png',
          unlocked:
              stats['unlockedAchievements']?.contains('family_reunion') ??
              false,
          requirement: 4,
          currentProgress:
              stats['levelsCompleted'] >= 4
                  ? 4
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'photo_sharer',
          title: 'Memory Keeper',
          description: 'Successfully shared your screen to show photos',
          imagePath: 'assets/images/badges/badge5.png',
          unlocked:
              stats['unlockedAchievements']?.contains('photo_sharer') ?? false,
          requirement: 5,
          currentProgress:
              stats['levelsCompleted'] >= 5
                  ? 5
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'social_butterfly',
          title: 'Grandparents\' Club Member',
          description: 'Joined a scheduled meeting using a meeting link',
          imagePath: 'assets/images/badges/badge6.png',
          unlocked:
              stats['unlockedAchievements']?.contains('social_butterfly') ??
              false,
          requirement: 6,
          currentProgress:
              stats['levelsCompleted'] >= 6
                  ? 6
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.levelsCompleted,
        ),
        Achievement(
          id: 'google_meet_graduate',
          title: 'Google Meet Graduate',
          description: 'Completed all levels of the Google Meet Adventure',
          imagePath: 'assets/images/badges/badge7.png',
          unlocked:
              stats['unlockedAchievements']?.contains('google_meet_graduate') ??
              false,
          requirement: 6,
          currentProgress:
              stats['levelsCompleted'] >= 6
                  ? 6
                  : (stats['levelsCompleted'] ?? 0),
          type: AchievementType.gameCompletion,
        ),
        Achievement(
          id: 'star_collector',
          title: 'Star Collector',
          description: 'Earned 10 or more stars in the adventure game',
          imagePath: 'assets/images/badges/badge8.png',
          unlocked:
              stats['unlockedAchievements']?.contains('star_collector') ??
              false,
          requirement: 10,
          currentProgress: stats['totalStars'] ?? 0,
          type: AchievementType.starsEarned,
        ),
        Achievement(
          id: 'family_connector',
          title: 'Family Bridge Builder',
          description: 'Connected with all available family members',
          imagePath: 'assets/images/badges/badge9.png',
          unlocked:
              stats['unlockedAchievements']?.contains('family_connector') ??
              false,
          requirement: 5,
          currentProgress: stats['familyMembersUnlocked'] ?? 1,
          type: AchievementType.familyConnections,
        ),
        Achievement(
          id: 'tech_explorer',
          title: 'Digital Pioneer',
          description: 'Completed the adventure game without hints',
          imagePath: 'assets/images/badges/badge10.png',
          unlocked:
              stats['unlockedAchievements']?.contains('tech_explorer') ?? false,
          requirement: 1,
          currentProgress: stats['completedWithoutHints'] == true ? 1 : 0,
          type: AchievementType.expertCompletion,
        ),
      ];

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load achievements: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateGameStats(
    Map<String, dynamic>? gameProgress,
    Set<String> unlockedAchievements,
  ) {
    if (gameProgress == null) {
      return {
        'levelsCompleted': 0,
        'gameCompleted': false,
        'totalStars': 0,
        'familyMembersUnlocked': 1, // Always start with Grandma Rose
        'completedWithoutHints': false,
        'unlockedAchievements': unlockedAchievements,
      };
    }

    int levelsCompleted = gameProgress['current_level'] ?? 0;
    bool gameCompleted = gameProgress['game_completed'] ?? false;
    int totalStars = gameProgress['total_stars'] ?? 0;

    // Count family members unlocked (from comma-separated string)
    int familyMembersUnlocked = 1; // Start with Grandma Rose
    if (gameProgress['unlocked_family_members'] != null) {
      final familyData = gameProgress['unlocked_family_members'] as String;
      if (familyData.isNotEmpty) {
        familyMembersUnlocked =
            familyData.split(',').where((s) => s.trim().isNotEmpty).length;
      }
    }

    bool completedWithoutHints =
        gameProgress['completed_without_hints'] ?? false;

    return {
      'levelsCompleted': levelsCompleted,
      'gameCompleted': gameCompleted,
      'totalStars': totalStars,
      'familyMembersUnlocked': familyMembersUnlocked,
      'completedWithoutHints': completedWithoutHints,
      'unlockedAchievements': unlockedAchievements,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/achievements',
      pageTitle: 'Achievements',
      child: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildAchievementsList(),
          // TTS Indicator when enabled
          if (_isTtsEnabled)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF27445D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'TTS On',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildAchievementsList() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            _buildLongPressText(
              text: errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPress: () => _speakText('Retry'),
              child: ElevatedButton(
                onPressed: _loadAchievements,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate achievement statistics
    int unlockedCount = achievements.where((a) => a.unlocked).length;
    int totalCount = achievements.length;
    double completionPercentage = (unlockedCount / totalCount) * 100;

    return RefreshIndicator(
      onRefresh: _loadAchievements,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLongPressText(
                  text: 'Achievements',
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Color(0xFF27445D),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onLongPress:
                      () => _speakText(
                        'You have unlocked $unlockedCount out of $totalCount achievements. That is ${completionPercentage.toStringAsFixed(1)} percent complete.',
                      ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.blue[700],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLongPressText(
                                text:
                                    '$unlockedCount of $totalCount Achievements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              _buildLongPressText(
                                text:
                                    '${completionPercentage.toStringAsFixed(1)}% Complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onLongPress:
                              () => _speakText(
                                'Progress: ${completionPercentage.toStringAsFixed(1)} percent complete',
                              ),
                          child: CircularProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.blue[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[700]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Achievement list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                return AchievementBadge(
                  achievement: achievements[index],
                  isTtsEnabled: _isTtsEnabled,
                  onTtsSpeak: _speakText,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum AchievementType {
  levelsCompleted,
  gameCompletion,
  starsEarned,
  familyConnections,
  expertCompletion,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final bool unlocked;
  final int requirement;
  final int currentProgress;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.unlocked,
    required this.requirement,
    required this.currentProgress,
    required this.type,
  });
}

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isTtsEnabled;
  final Function(String) onTtsSpeak;

  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.isTtsEnabled,
    required this.onTtsSpeak,
  });

  @override
  Widget build(BuildContext context) {
    // Create comprehensive TTS text for the achievement
    String achievementTts = '${achievement.title}. ${achievement.description}.';
    if (achievement.unlocked) {
      achievementTts += ' This achievement is unlocked!';
    } else {
      String progressText = _getProgressText();
      achievementTts += ' Progress: $progressText. Not yet unlocked.';
    }

    return GestureDetector(
      onLongPress: () => onTtsSpeak(achievementTts),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: achievement.unlocked ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: achievement.unlocked ? Colors.green : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow:
              achievement.unlocked
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Badge Image
              Stack(
                children: [
                  GestureDetector(
                    onLongPress:
                        () => onTtsSpeak(
                          'Achievement badge for ${achievement.title}',
                        ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            achievement.unlocked
                                ? Colors.transparent
                                : Colors.grey[300],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          achievement.imagePath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          color:
                              achievement.unlocked
                                  ? null
                                  : Colors.grey.withOpacity(0.6),
                          colorBlendMode:
                              achievement.unlocked ? null : BlendMode.modulate,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    achievement.unlocked
                                        ? Colors.blue[100]
                                        : Colors.grey[300],
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color:
                                    achievement.unlocked
                                        ? Colors.blue[700]
                                        : Colors.grey[500],
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (achievement.unlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onLongPress:
                            () => onTtsSpeak('Achievement unlocked checkmark'),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Achievement Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => onTtsSpeak(achievement.title),
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              achievement.unlocked
                                  ? Colors.black
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onLongPress: () => onTtsSpeak(achievement.description),
                      child: Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              achievement.unlocked
                                  ? Colors.grey[700]
                                  : Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress indicator
                    if (!achievement.unlocked) ...[
                      GestureDetector(
                        onLongPress:
                            () => onTtsSpeak('Progress: ${_getProgressText()}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value:
                                    achievement.currentProgress /
                                    achievement.requirement,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[400]!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getProgressText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onLongPress:
                            () => onTtsSpeak('This achievement is unlocked!'),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unlocked!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProgressText() {
    switch (achievement.type) {
      case AchievementType.expertCompletion:
        return achievement.currentProgress > 0
            ? 'Completed!'
            : 'Not yet achieved';
      default:
        return '${achievement.currentProgress}/${achievement.requirement}';
    }
  }
}
