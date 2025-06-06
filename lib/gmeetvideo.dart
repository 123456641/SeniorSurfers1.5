import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'services/tts_service.dart';

class GMeetInstallVideoPage extends StatefulWidget {
  const GMeetInstallVideoPage({super.key});

  @override
  State<GMeetInstallVideoPage> createState() => _GMeetInstallVideoPageState();
}

class _GMeetInstallVideoPageState extends State<GMeetInstallVideoPage> {
  late VideoPlayerController _videoController;
  final _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFullscreen = false;
  bool _isTtsEnabled = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;

  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _loadTtsPreference();
    _initializeVideo();
  }

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

        if (mounted) {
          setState(() {
            _isTtsEnabled = response['tts_enabled'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading TTS preference: $e');
    }
  }

  Future<void> _initializeVideo() async {
    try {
      print('Attempting to load video: assets/videos/installgmeet.mp4');

      // Check if running on web
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage =
                'Video playback is not fully supported on Flutter Web. Please use the mobile app for the best video experience, or try the interactive tutorial instead.';
          });
        }
        return;
      }

      // Initialize video from assets
      _videoController = VideoPlayerController.asset(
        'assets/videos/installgmeet.mp4',
      );

      // Add error listener
      _videoController.addListener(() {
        if (_videoController.value.hasError) {
          print(
            'Video player error: ${_videoController.value.errorDescription}',
          );
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage =
                  'Video format not supported. Please ensure the video is in MP4 format with H.264 codec.';
            });
          }
        }
      });

      await _videoController.initialize();
      _videoController.addListener(_videoListener);

      print(
        'Video initialized successfully. Duration: ${_videoController.value.duration}',
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _duration = _videoController.value.duration;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Unable to load asset') ||
          errorMessage.contains('AssetManifest')) {
        errorMessage =
            'Video file not found. Please ensure "installgmeet.mp4" is placed in the assets/videos/ folder and listed in pubspec.yaml under assets.';
      } else if (errorMessage.contains('MEDIA_ERR_SRC_NOT_SUPPORTED') ||
          errorMessage.contains('Format error')) {
        errorMessage =
            'Video format not supported by your browser. Please try:\n• Converting video to MP4 with H.264 codec\n• Using the mobile app instead\n• Trying the interactive tutorial';
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _position = _videoController.value.position;
        _isPlaying = _videoController.value.isPlaying;
      });
    }
  }

  Future<void> _speakText(String text) async {
    if (_isTtsEnabled && text.isNotEmpty) {
      await TTSService().speak(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reading: ${text.length > 30 ? text.substring(0, 30) + "..." : text}',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  double _getFontSize(BuildContext context, {double multiplier = 1.0}) {
    try {
      final fontSizeProvider = Provider.of<FontSizeProvider>(
        context,
        listen: false,
      );
      return fontSizeProvider.fontSize * multiplier;
    } catch (e) {
      return 16.0 * multiplier;
    }
  }

  Widget _buildText(
    String text,
    BuildContext context, {
    double multiplier = 1.0,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GestureDetector(
      onLongPress: () => _speakText(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _getFontSize(context, multiplier: multiplier),
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
    _resetHideControlsTimer();
  }

  void _seekTo(Duration position) {
    _videoController.seekTo(position);
    _resetHideControlsTimer();
  }

  void _skipForward() {
    final newPosition = _position + Duration(seconds: 10);
    if (newPosition < _duration) {
      _seekTo(newPosition);
    } else {
      _seekTo(_duration);
    }
  }

  void _skipBackward() {
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _seekTo(newPosition);
    } else {
      _seekTo(Duration.zero);
    }
  }

  void _changeVolume(double volume) {
    setState(() {
      _volume = volume;
    });
    _videoController.setVolume(volume);
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _videoController.setPlaybackSpeed(speed);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls && _isPlaying) {
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Volume'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(_volume * 100).round()}%'),
                Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                    _changeVolume(value);
                  },
                  activeColor: Colors.green.shade600,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Playback Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('0.5x'),
                  onTap: () {
                    _changePlaybackSpeed(0.5);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('0.75x'),
                  onTap: () {
                    _changePlaybackSpeed(0.75);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('1x (Normal)'),
                  onTap: () {
                    _changePlaybackSpeed(1.0);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('1.25x'),
                  onTap: () {
                    _changePlaybackSpeed(1.25);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('1.5x'),
                  onTap: () {
                    _changePlaybackSpeed(1.5);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('2x'),
                  onTap: () {
                    _changePlaybackSpeed(2.0);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Widget _buildSimpleVideoPlayer() {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = screenHeight > screenWidth;

    // Calculate video player height based on screen size
    final videoHeight =
        isPortrait
            ? screenWidth *
                0.56 // 16:9 aspect ratio for portrait
            : screenHeight * 0.5; // 50% of screen height for landscape

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: videoHeight,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        width: double.infinity,
        height: videoHeight,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Video Not Available',
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/gmeet-tutorial'),
                    icon: Icon(Icons.touch_app, size: 18),
                    label: Text('Interactive', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/tutorials'),
                    icon: Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      'All Tutorials',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      side: BorderSide(color: Colors.blue.shade600),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: videoHeight,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    // Mobile-optimized video player
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: videoHeight,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player - Responsive sizing
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),

              // Mobile-optimized controls overlay
              if (_showControls)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top bar - Mobile optimized
                      SafeArea(
                        bottom: false,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Back button with better touch target
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () => context.go('/tutorials'),
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                              ),

                              // Title - responsive text size
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Google Meet Installation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isPortrait ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // Fullscreen button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: _toggleFullscreen,
                                  icon: Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center play button - Larger for mobile
                      Expanded(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: isPortrait ? 48 : 40,
                              ),
                              constraints: BoxConstraints(
                                minWidth: isPortrait ? 80 : 70,
                                minHeight: isPortrait ? 80 : 70,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom controls - Mobile optimized
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar with better touch targets
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3,
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 8,
                                          ),
                                          overlayShape: RoundSliderOverlayShape(
                                            overlayRadius: 16,
                                          ),
                                          activeTrackColor:
                                              Colors.green.shade500,
                                          inactiveTrackColor: Colors.white
                                              .withOpacity(0.3),
                                          thumbColor: Colors.green.shade400,
                                          overlayColor: Colors.green
                                              .withOpacity(0.2),
                                        ),
                                        child: Slider(
                                          value: _position.inSeconds
                                              .toDouble()
                                              .clamp(
                                                0.0,
                                                _duration.inSeconds.toDouble(),
                                              ),
                                          max: _duration.inSeconds
                                              .toDouble()
                                              .clamp(1.0, double.infinity),
                                          onChanged:
                                              (value) => _seekTo(
                                                Duration(
                                                  seconds: value.toInt(),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 8),

                              // Control buttons - Mobile optimized with better spacing
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMobileControlButton(
                                    icon: Icons.replay_10,
                                    onPressed: _skipBackward,
                                    size: 20,
                                  ),
                                  _buildMobileControlButton(
                                    icon:
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                    onPressed: _togglePlayPause,
                                    size: 24,
                                    isPrimary: true,
                                  ),
                                  _buildMobileControlButton(
                                    icon: Icons.forward_10,
                                    onPressed: _skipForward,
                                    size: 20,
                                  ),
                                  _buildMobileControlButton(
                                    icon:
                                        _volume == 0
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                    onPressed: _showVolumeDialog,
                                    size: 20,
                                  ),
                                  _buildMobileControlButton(
                                    icon: Icons.speed,
                                    onPressed: _showSpeedDialog,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  // Helper method for mobile-optimized control buttons
  Widget _buildMobileControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isPrimary
                ? Colors.green.shade600.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border:
            isPrimary
                ? Border.all(color: Colors.green.shade400.withOpacity(0.5))
                : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: size),
        constraints: BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildTutorialInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.video_call,
                  color: Colors.green.shade600,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildText(
                      'How to Install Google Meet',
                      context,
                      multiplier: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27445D),
                      maxLines: 2,
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildText(
                        'VIDEO TUTORIAL',
                        context,
                        multiplier: 0.75,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildText(
            'This comprehensive video tutorial will guide you through every step of installing Google Meet on your device. Perfect for seniors and first-time users, the video includes clear visual instructions and helpful tips.',
            context,
            color: Colors.grey.shade700,
            maxLines: 6,
            multiplier: 0.95,
          ),
          SizedBox(height: 16),
          // Feature badges - Mobile optimized
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMobileFeatureBadge('📱 Mobile Setup', Colors.blue.shade600),
              _buildMobileFeatureBadge('🔊 Audio Guide', Colors.green.shade600),
              _buildMobileFeatureBadge(
                '👥 Senior Friendly',
                Colors.purple.shade600,
              ),
              _buildMobileFeatureBadge('📺 HD Video', Colors.orange.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: _buildText(
        text,
        context,
        multiplier: 0.8,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Back to tutorials - Mobile optimized
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/tutorials'),
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              label: _buildText(
                'Back to All Tutorials',
                context,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                multiplier: 1.0,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF27445D),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: 12),

          // Interactive tutorial option - Mobile optimized
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/gmeet-tutorial'),
              icon: Icon(
                Icons.touch_app,
                color: Colors.green.shade600,
                size: 20,
              ),
              label: _buildText(
                'Try Interactive Tutorial',
                context,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
                multiplier: 1.0,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.shade600, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Fullscreen video
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),

              // Fullscreen controls
              if (_showControls)
                GestureDetector(
                  onTap: _toggleControls,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleFullscreen,
                              icon: Icon(
                                Icons.fullscreen_exit,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Google Meet Installation Tutorial',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.go('/tutorials'),
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: IconButton(
                              onPressed: _togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _position.inSeconds.toDouble().clamp(
                                    0.0,
                                    _duration.inSeconds.toDouble(),
                                  ),
                                  max: _duration.inSeconds.toDouble().clamp(
                                    1.0,
                                    double.infinity,
                                  ),
                                  onChanged:
                                      (value) => _seekTo(
                                        Duration(seconds: value.toInt()),
                                      ),
                                  activeColor: Colors.green.shade600,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/tutorials',
          pageTitle: 'Video Tutorial',
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: 80,
                    ), // Extra padding for bottom navigation
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video player
                        _buildSimpleVideoPlayer(),

                        // Tutorial information
                        _buildTutorialInfo(),

                        // Navigation buttons
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    if (_isInitialized) {
      _videoController.removeListener(_videoListener);
      _videoController.dispose();
    }

    // Reset system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }
}
