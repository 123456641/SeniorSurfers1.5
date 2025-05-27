import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'package:realtime_client/src/realtime_channel.dart';
import 'package:provider/provider.dart';
import '../dashboardsidebar.dart';
import '../providers/font_size_provider.dart';
import '../widgets/scaled_text.dart';
import '../services/tts_service.dart'; // Add TTS import

// Get a reference to Supabase client
final supabase = Supabase.instance.client;

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({Key? key}) : super(key: key);

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  List<Map<String, dynamic>> _forumTopics = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _expandedTopicId;
  Map<String, List<Map<String, dynamic>>> _topicReplies = {};
  Map<String, bool> _loadingReplies = {};
  bool _isTtsEnabled = false; // Track TTS setting

  @override
  void initState() {
    super.initState();
    _loadForumTopics();
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
          onLongPress: () => _speakText(text),
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

  Future<void> _loadForumTopics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch forum topics with user information
      final response = await supabase
          .from('forum_topics')
          .select('''
            *,
            users:user_id (
              id, 
              first_name, 
              last_name, 
              profile_picture_url
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _forumTopics = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading forum topics: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRepliesForTopic(String topicId) async {
    if (_loadingReplies[topicId] == true) return;

    setState(() {
      _loadingReplies[topicId] = true;
    });

    try {
      final repliesResponse = await supabase
          .from('forum_replies')
          .select('''
            *,
            users:user_id (
              id, 
              first_name, 
              last_name, 
              profile_picture_url
            )
          ''')
          .eq('topic_id', topicId)
          .order('created_at', ascending: true);

      setState(() {
        _topicReplies[topicId] = repliesResponse;
        _loadingReplies[topicId] = false;
      });
    } catch (error) {
      setState(() {
        _loadingReplies[topicId] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading replies: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _submitReply(String topicId, String content) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to reply'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      await supabase.from('forum_replies').insert({
        'topic_id': topicId,
        'user_id': userId,
        'content': content.trim(),
      });

      // Reload replies for this topic
      await _loadRepliesForTopic(topicId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting reply: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/community',
          pageTitle: 'Community Forum',
          child: Stack(
            children: [
              _buildContent(fontProvider),
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

  Widget _buildContent(FontSizeProvider fontProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return RefreshIndicator(
      onRefresh: _loadForumTopics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 900 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create Topic button - Made larger and more prominent
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onLongPress: () => _speakText('Start New Discussion'),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWideScreen ? 24.0 : 20.0,
                                vertical: isWideScreen ? 16.0 : 14.0,
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateTopicPage(),
                                ),
                              ).then((_) => _loadForumTopics());
                            },
                            icon: const Icon(Icons.add, size: 24),
                            label: ScaledText(
                              isWideScreen
                                  ? 'Start New Discussion'
                                  : 'New Topic',
                              baseFontSize: isWideScreen ? 18.0 : 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Show error message if any
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: _buildLongPressText(
                          text: _errorMessage,
                          baseFontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),

                  // Display forum topics
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                            : _forumTopics.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLongPressText(
                                      text: 'No discussions yet',
                                      baseFontSize: 20.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLongPressText(
                                      text:
                                          'Be the first to start a conversation!',
                                      baseFontSize: 16.0,
                                      color: Colors.grey.shade500,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              itemCount: _forumTopics.length,
                              itemBuilder: (context, index) {
                                final topic = _forumTopics[index];
                                final user =
                                    topic['users'] as Map<String, dynamic>;
                                final fullName =
                                    '${user['first_name']} ${user['last_name']}';
                                final createdAt = DateTime.parse(
                                  topic['created_at'],
                                );
                                final timeAgo = timeago.format(createdAt);
                                final topicId = topic['id'];
                                final isExpanded = _expandedTopicId == topicId;

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 8.0 : 4.0,
                                    vertical: 6.0,
                                  ),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Column(
                                    children: [
                                      // Main topic content
                                      InkWell(
                                        onTap: () async {
                                          if (isExpanded) {
                                            setState(() {
                                              _expandedTopicId = null;
                                            });
                                          } else {
                                            setState(() {
                                              _expandedTopicId = topicId;
                                            });
                                            await _loadRepliesForTopic(topicId);
                                          }
                                        },
                                        onLongPress:
                                            () => _speakText(topic['title']),
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            isWideScreen ? 20.0 : 16.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // User info and expand button
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius:
                                                        isWideScreen ? 24 : 20,
                                                    backgroundImage:
                                                        user['profile_picture_url'] !=
                                                                null
                                                            ? NetworkImage(
                                                              user['profile_picture_url'],
                                                            )
                                                            : null,
                                                    backgroundColor:
                                                        Colors.blue.shade100,
                                                    child:
                                                        user['profile_picture_url'] ==
                                                                null
                                                            ? ScaledText(
                                                              fullName[0],
                                                              baseFontSize:
                                                                  isWideScreen
                                                                      ? 18
                                                                      : 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade700,
                                                            )
                                                            : null,
                                                  ),
                                                  const SizedBox(width: 12.0),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        _buildLongPressText(
                                                          text: fullName,
                                                          baseFontSize:
                                                              isWideScreen
                                                                  ? 16.0
                                                                  : 15.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade700,
                                                        ),
                                                        _buildLongPressText(
                                                          text: timeAgo,
                                                          baseFontSize:
                                                              isWideScreen
                                                                  ? 14.0
                                                                  : 13.0,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade500,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    isExpanded
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                    size: 28,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16.0),

                                              // Topic title
                                              _buildLongPressText(
                                                text: topic['title'],
                                                baseFontSize:
                                                    isWideScreen ? 20.0 : 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1565C0),
                                                height: 1.3,
                                              ),
                                              const SizedBox(height: 12.0),

                                              // Topic content preview
                                              _buildLongPressText(
                                                text: topic['content'],
                                                baseFontSize:
                                                    isWideScreen ? 16.0 : 15.0,
                                                height: 1.5,
                                                color: Colors.grey.shade700,
                                                maxLines: isExpanded ? null : 3,
                                                overflow:
                                                    isExpanded
                                                        ? null
                                                        : TextOverflow.ellipsis,
                                              ),

                                              const SizedBox(height: 12.0),

                                              // Replies count
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.comment_outlined,
                                                    size: 18,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _buildLongPressText(
                                                    text:
                                                        '${_topicReplies[topicId]?.length ?? 0} replies',
                                                    baseFontSize: 14.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                  const Spacer(),
                                                  _buildLongPressText(
                                                    text:
                                                        isExpanded
                                                            ? 'Tap to collapse'
                                                            : 'Tap to view replies',
                                                    baseFontSize: 13.0,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Expanded replies section
                                      if (isExpanded)
                                        _buildRepliesSection(
                                          topicId,
                                          isWideScreen,
                                          fontProvider,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepliesSection(
    String topicId,
    bool isWideScreen,
    FontSizeProvider fontProvider,
  ) {
    final replies = _topicReplies[topicId] ?? [];
    final isLoading = _loadingReplies[topicId] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12.0),
          bottomRight: Radius.circular(12.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          // Replies header
          Padding(
            padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
            child: Row(
              children: [
                Icon(Icons.forum, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                _buildLongPressText(
                  text: 'Discussion',
                  baseFontSize: isWideScreen ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),

          // Replies list
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (replies.isEmpty)
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
              child: Center(
                child: _buildLongPressText(
                  text:
                      'No replies yet. Be the first to join the conversation!',
                  baseFontSize: isWideScreen ? 16.0 : 15.0,
                  color: Colors.grey.shade600,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 20.0 : 16.0,
                vertical: 8.0,
              ),
              itemCount: replies.length,
              separatorBuilder:
                  (context, index) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                return _buildReplyCard(
                  replies[index],
                  isWideScreen,
                  fontProvider,
                );
              },
            ),

          // Reply input
          _buildReplyInput(topicId, isWideScreen, fontProvider),
        ],
      ),
    );
  }

  Widget _buildReplyCard(
    Map<String, dynamic> reply,
    bool isWideScreen,
    FontSizeProvider fontProvider,
  ) {
    final user = reply['users'] as Map<String, dynamic>? ?? {};
    final firstName = user['first_name'] ?? 'Unknown';
    final lastName = user['last_name'] ?? 'User';
    final fullName = '$firstName $lastName';

    final createdAt = DateTime.parse(reply['created_at']);
    final timeAgo = timeago.format(createdAt);
    final currentUser = supabase.auth.currentUser;
    final isCurrentUserReply =
        currentUser != null && currentUser.id == user['id'];

    return GestureDetector(
      onLongPress: () => _speakText(reply['content']),
      child: Container(
        padding: EdgeInsets.all(isWideScreen ? 16.0 : 14.0),
        decoration: BoxDecoration(
          color: isCurrentUserReply ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color:
                isCurrentUserReply
                    ? Colors.blue.shade200
                    : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isWideScreen ? 18 : 16,
                  backgroundImage:
                      user['profile_picture_url'] != null
                          ? NetworkImage(user['profile_picture_url'])
                          : null,
                  backgroundColor: Colors.green.shade100,
                  child:
                      user['profile_picture_url'] == null
                          ? ScaledText(
                            fullName[0],
                            baseFontSize: isWideScreen ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          )
                          : null,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLongPressText(
                        text: fullName,
                        baseFontSize: isWideScreen ? 15.0 : 14.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      _buildLongPressText(
                        text: timeAgo,
                        baseFontSize: isWideScreen ? 13.0 : 12.0,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                if (isCurrentUserReply)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const ScaledText(
                                  'Delete Reply',
                                  baseFontSize: 18,
                                ),
                                content: const ScaledText(
                                  'Are you sure you want to delete this reply?',
                                  baseFontSize: 16,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const ScaledText(
                                      'Cancel',
                                      baseFontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const ScaledText(
                                      'Delete',
                                      baseFontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed == true) {
                          try {
                            await supabase
                                .from('forum_replies')
                                .delete()
                                .eq('id', reply['id']);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reply deleted'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Reload replies
                            String? topicId;
                            for (var entry in _topicReplies.entries) {
                              if (entry.value.any(
                                (r) => r['id'] == reply['id'],
                              )) {
                                topicId = entry.key;
                                break;
                              }
                            }
                            if (topicId != null) {
                              await _loadRepliesForTopic(topicId);
                            }
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting reply: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8.0),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
              ],
            ),
            SizedBox(height: isWideScreen ? 12.0 : 10.0),
            _buildLongPressText(
              text: reply['content'],
              baseFontSize: isWideScreen ? 16.0 : 15.0,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(
    String topicId,
    bool isWideScreen,
    FontSizeProvider fontProvider,
  ) {
    final TextEditingController replyController = TextEditingController();
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLongPressText(
                text: 'Join the conversation',
                baseFontSize: isWideScreen ? 16.0 : 15.0,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: replyController,
                decoration: InputDecoration(
                  hintText: 'Write your reply here...',
                  hintStyle: TextStyle(
                    fontSize:
                        fontProvider.fontSize *
                        (isWideScreen ? 16.0 : 15.0) /
                        16.0,
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 16.0 : 14.0,
                    vertical: isWideScreen ? 16.0 : 14.0,
                  ),
                ),
                style: TextStyle(
                  fontSize:
                      fontProvider.fontSize *
                      (isWideScreen ? 16.0 : 15.0) /
                      16.0,
                ),
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onLongPress:
                        () => _speakText(
                          isSubmitting ? 'Posting...' : 'Post Reply',
                        ),
                    child: ElevatedButton.icon(
                      onPressed:
                          isSubmitting
                              ? null
                              : () async {
                                if (replyController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a reply'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setLocalState(() {
                                  isSubmitting = true;
                                });

                                await _submitReply(
                                  topicId,
                                  replyController.text,
                                );

                                replyController.clear();
                                setLocalState(() {
                                  isSubmitting = false;
                                });
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWideScreen ? 20.0 : 16.0,
                          vertical: isWideScreen ? 12.0 : 10.0,
                        ),
                      ),
                      icon:
                          isSubmitting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.send, size: 18),
                      label: ScaledText(
                        isSubmitting ? 'Posting...' : 'Post Reply',
                        baseFontSize: isWideScreen ? 16.0 : 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({Key? key}) : super(key: key);

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isTtsEnabled = false; // Track TTS setting

  @override
  void initState() {
    super.initState();
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
          onLongPress: () => _speakText(text),
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

  Future<void> _submitTopic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a topic'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('forum_topics').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discussion created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating discussion: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWideScreen = screenWidth > 600;

        return SidebarLayoutWrapper(
          currentPage: '/community',
          pageTitle: 'Start New Discussion',
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 800 : screenWidth * 0.95,
                      minHeight: 300,
                    ),
                    padding: EdgeInsets.all(isWideScreen ? 24.0 : 20.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Icon(
                                    Icons.create,
                                    color: Colors.blue.shade600,
                                    size: isWideScreen ? 28 : 24,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildLongPressText(
                                    text: 'Create New Discussion',
                                    baseFontSize: isWideScreen ? 24.0 : 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ],
                              ),
                              SizedBox(height: isWideScreen ? 32.0 : 24.0),

                              // Title field
                              _buildLongPressText(
                                text: 'Discussion Title',
                                baseFontSize: isWideScreen ? 18.0 : 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _titleController,
                                style: TextStyle(
                                  fontSize:
                                      fontProvider.fontSize *
                                      (isWideScreen ? 18.0 : 16.0) /
                                      16.0,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter a clear, descriptive title...',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        fontProvider.fontSize *
                                        (isWideScreen ? 16.0 : 15.0) /
                                        16.0,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 16.0 : 14.0,
                                    vertical: isWideScreen ? 16.0 : 14.0,
                                  ),
                                  errorStyle: TextStyle(
                                    fontSize:
                                        fontProvider.fontSize *
                                        (isWideScreen ? 14.0 : 13.0) /
                                        16.0,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title for your discussion';
                                  }
                                  if (value.trim().length < 5) {
                                    return 'Title should be at least 5 characters long';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isWideScreen ? 24.0 : 20.0),

                              // Content field
                              _buildLongPressText(
                                text: 'Your Message',
                                baseFontSize: isWideScreen ? 18.0 : 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _contentController,
                                style: TextStyle(
                                  fontSize:
                                      fontProvider.fontSize *
                                      (isWideScreen ? 16.0 : 15.0) /
                                      16.0,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Share your thoughts, ask a question, or start a conversation...',
                                  hintStyle: TextStyle(
                                    fontSize:
                                        fontProvider.fontSize *
                                        (isWideScreen ? 15.0 : 14.0) /
                                        16.0,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 16.0 : 14.0,
                                    vertical: isWideScreen ? 16.0 : 14.0,
                                  ),
                                  alignLabelWithHint: true,
                                  errorStyle: TextStyle(
                                    fontSize:
                                        fontProvider.fontSize *
                                        (isWideScreen ? 14.0 : 13.0) /
                                        16.0,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                maxLines: isWideScreen ? 12 : 10,
                                minLines: isWideScreen ? 6 : 5,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your message';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Message should be at least 10 characters long';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isWideScreen ? 32.0 : 24.0),

                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Cancel button
                                  GestureDetector(
                                    onLongPress: () => _speakText('Cancel'),
                                    child: TextButton(
                                      onPressed:
                                          _isSubmitting
                                              ? null
                                              : () {
                                                Navigator.pop(context);
                                              },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              isWideScreen ? 24.0 : 20.0,
                                          vertical: isWideScreen ? 16.0 : 14.0,
                                        ),
                                      ),
                                      child: ScaledText(
                                        'Cancel',
                                        baseFontSize:
                                            isWideScreen ? 16.0 : 15.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),

                                  // Create button
                                  GestureDetector(
                                    onLongPress:
                                        () => _speakText(
                                          _isSubmitting
                                              ? 'Creating...'
                                              : 'Create Discussion',
                                        ),
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isSubmitting ? null : _submitTopic,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              isWideScreen ? 24.0 : 20.0,
                                          vertical: isWideScreen ? 16.0 : 14.0,
                                        ),
                                        elevation: 3,
                                      ),
                                      icon:
                                          _isSubmitting
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : const Icon(
                                                Icons.create,
                                                size: 20,
                                              ),
                                      label: ScaledText(
                                        _isSubmitting
                                            ? 'Creating...'
                                            : 'Create Discussion',
                                        baseFontSize:
                                            isWideScreen ? 16.0 : 15.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
}
