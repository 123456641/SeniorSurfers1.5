import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'games/googlemeet.dart';
import 'dashboardsidebar.dart';
import 'providers/font_size_provider.dart';
import 'widgets/scaled_text.dart';
import 'services/tts_service.dart'; // Add TTS import

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final _supabase = Supabase.instance.client;
  bool _isTtsEnabled = false; // Track TTS setting

  final List<GameInfo> games = [
    GameInfo(
      title: 'Google Meet',
      description: 'Practice using Google Meet',
      imagePath: 'assets/images/practice/gmeet.png',
      route: '/googlemeet',
      page: const GoogleMeetAdventureGame(),
      color: Colors.green.shade700,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTtsPreference(); // Load TTS setting
  }

  // Load TTS preference from user settings
  Future<void> _loadTtsPreference() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response =
            await _supabase
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
    print('_speakText called with: $text'); // Debug log
    print('TTS enabled: $_isTtsEnabled'); // Debug log

    if (_isTtsEnabled && text.isNotEmpty) {
      try {
        print('Attempting to speak text...'); // Debug log
        await TTSService().speak(text);
        print('TTS speak completed'); // Debug log

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
        print('Error in TTS: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error with text-to-speech: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (!_isTtsEnabled) {
      print('TTS not enabled, showing settings prompt'); // Debug log
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
    } else {
      print('Text is empty, not speaking'); // Debug log
    }
  }

  // Custom widget for long-pressable text
  Widget _buildLongPressText({
    required String text,
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    double? height,
  }) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return GestureDetector(
          onLongPress: () {
            print('Long press detected on: $text'); // Debug log
            _speakText(text);
          },
          child: Container(
            child: ScaledText(
              text,
              baseFontSize: baseFontSize,
              fontWeight: fontWeight,
              color: color,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              height: height,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/games',
          pageTitle: 'Games',
          child: Stack(
            children: [
              _buildContent(context, fontProvider),

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
      },
    );
  }

  Widget _buildContent(BuildContext context, FontSizeProvider fontProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 1024;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF27445D),
                        const Color(0xFF27445D).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.games,
                            color: Colors.amber,
                            size: isMobile ? 32 : 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLongPressText(
                              text: "Practice Games",
                              baseFontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLongPressText(
                        text:
                            "Learn by playing! Practice your video calling skills with these quiz games.",
                        baseFontSize: isMobile ? 16 : 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Games Grid
                _buildGamesGrid(context, isMobile, isTablet, fontProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamesGrid(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    FontSizeProvider fontProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLongPressText(
          text: "Available Games",
          baseFontSize: isMobile ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF27445D),
        ),
        const SizedBox(height: 20),

        // Responsive grid layout
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            double maxCardWidth = 280;
            double spacing = isMobile ? 16 : 24;

            if (constraints.maxWidth < 600) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = (constraints.maxWidth / (maxCardWidth + spacing))
                  .floor()
                  .clamp(2, 4);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.85,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _buildGameCard(game, isMobile, context, fontProvider);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard(
    GameInfo game,
    bool isMobile,
    BuildContext context,
    FontSizeProvider fontProvider,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => game.page),
            ),
        onLongPress: () => _speakText(game.title), // Add long press for TTS
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [game.color.withOpacity(0.05), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game Image/Icon
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: game.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: game.color.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: game.color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    game.imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Container(
                        decoration: BoxDecoration(
                          color: game.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          game.title.toLowerCase().contains('google')
                              ? Icons.video_call
                              : Icons.videocam,
                          size: isMobile ? 50 : 60,
                          color: game.color,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Game Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLongPressText(
                  text: game.title,
                  baseFontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27445D),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Game Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLongPressText(
                  text: game.description,
                  baseFontSize: isMobile ? 14 : 15,
                  color: Colors.grey[600],
                  height: 1.3,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Play Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => game.page),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: game.color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: ScaledText(
                    "Play Game",
                    baseFontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class GameInfo {
  final String title;
  final String description;
  final String imagePath;
  final String route;
  final Widget page;
  final Color color;

  const GameInfo({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.route,
    required this.page,
    required this.color,
  });
}
