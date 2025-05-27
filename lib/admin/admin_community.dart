// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class AdminCommunityScreen extends StatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  State<AdminCommunityScreen> createState() => _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends State<AdminCommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _forumTopics = [];
  List<Map<String, dynamic>> _forumReplies = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load users data
      final usersResponse = await supabase
          .from('users')
          .select(
            'id, email, created_at, first_name, last_name, phone, profile_picture_url, is_admin',
          )
          .order('created_at', ascending: false);

      // Load forum topics with user info
      final topicsResponse = await supabase
          .from('forum_topics')
          .select('''
            id, 
            title, 
            content,
            created_at, 
            updated_at,
            is_pinned,
            is_locked,
            view_count,
            category,
            user_id,
            users:user_id (first_name, last_name)
          ''')
          .order('created_at', ascending: false);

      // Load forum replies with user info and topic title
      final repliesResponse = await supabase
          .from('forum_replies')
          .select('''
            id,
            content,
            created_at,
            updated_at,
            is_solution,
            topic_id,
            user_id,
            users:user_id (first_name, last_name),
            forum_topics:topic_id (title)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(usersResponse);
        _forumTopics = List<Map<String, dynamic>>.from(topicsResponse);
        _forumReplies = List<Map<String, dynamic>>.from(repliesResponse);
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $error')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatFullDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getUserFullName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final fullName = _getUserFullName(user).toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredTopics() {
    if (_searchQuery.isEmpty) return _forumTopics;
    return _forumTopics.where((topic) {
      final title = (topic['title'] ?? '').toString().toLowerCase();
      final content = (topic['content'] ?? '').toString().toLowerCase();
      final category = (topic['category'] ?? '').toString().toLowerCase();
      final userFirstName =
          ((topic['users'] ?? {})['first_name'] ?? '').toString().toLowerCase();
      final userLastName =
          ((topic['users'] ?? {})['last_name'] ?? '').toString().toLowerCase();

      return title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase()) ||
          category.contains(_searchQuery.toLowerCase()) ||
          userFirstName.contains(_searchQuery.toLowerCase()) ||
          userLastName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredReplies() {
    if (_searchQuery.isEmpty) return _forumReplies;
    return _forumReplies.where((reply) {
      final content = (reply['content'] ?? '').toString().toLowerCase();
      final userFirstName =
          ((reply['users'] ?? {})['first_name'] ?? '').toString().toLowerCase();
      final userLastName =
          ((reply['users'] ?? {})['last_name'] ?? '').toString().toLowerCase();
      final topicTitle =
          ((reply['forum_topics'] ?? {})['title'] ?? '')
              .toString()
              .toLowerCase();

      return content.contains(_searchQuery.toLowerCase()) ||
          userFirstName.contains(_searchQuery.toLowerCase()) ||
          userLastName.contains(_searchQuery.toLowerCase()) ||
          topicTitle.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteForumTopic(String id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Delete the topic using the "Admins can delete any forum topic" policy
      await supabase.from('forum_topics').delete().eq('id', id);

      // Refresh data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic deleted successfully')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting topic: $error')));
      }
    }
  }

  Future<void> _deleteForumReply(String id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if reply exists before attempting to delete
      final replyExists =
          await supabase
              .from('forum_replies')
              .select('id, topic_id')
              .eq('id', id)
              .maybeSingle();

      if (replyExists == null) {
        throw Exception('Reply not found');
      }

      // Get current user ID and check admin status
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      print('User ID attempting delete: ${user.id}');

      // Check if user is admin
      final adminCheck =
          await supabase
              .from('users')
              .select('is_admin')
              .eq('id', user.id)
              .single();

      final isAdmin = adminCheck['is_admin'] ?? false;
      print('Is user admin? $isAdmin');

      if (!isAdmin) {
        throw Exception('User is not an admin - cannot delete reply');
      }

      // Directly execute the delete operation
      print('Attempting to delete reply: $id');
      try {
        await supabase.from('forum_replies').delete().eq('id', id);

        print('Delete operation completed without exceptions');
      } catch (deleteError) {
        print('Delete operation failed: $deleteError');
        throw Exception('Delete operation failed: $deleteError');
      }

      // Verify the reply was actually deleted
      final checkDeleted =
          await supabase
              .from('forum_replies')
              .select('id')
              .eq('id', id)
              .maybeSingle();

      if (checkDeleted != null) {
        print('Reply still exists after delete operation');
        throw Exception('Reply was not deleted - permission issue');
      } else {
        print('Reply successfully deleted');
      }

      // Refresh data after successful deletion
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply deleted successfully')),
        );
      }
    } catch (error) {
      print('Error in _deleteForumReply: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting reply: $error')));
      }
    }
  }

  Future<void> _editForumTopic(Map<String, dynamic> topic) async {
    // Show dialog to edit topic
    final titleController = TextEditingController(text: topic['title']);
    final contentController = TextEditingController(text: topic['content']);
    final categoryController = TextEditingController(
      text: topic['category'] ?? '',
    );
    bool isPinned = topic['is_pinned'] ?? false;
    bool isLocked = topic['is_locked'] ?? false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Edit Forum Topic'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Topic Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: contentController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Pin Topic'),
                          value: isPinned,
                          onChanged: (value) {
                            setDialogState(() {
                              isPinned = value ?? false;
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Lock Topic'),
                          value: isLocked,
                          onChanged: (value) {
                            setDialogState(() {
                              isLocked = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        try {
                          setState(() {
                            _isLoading = true;
                          });

                          // Update the topic using the "Admins can update any forum topic" policy
                          await supabase
                              .from('forum_topics')
                              .update({
                                'title': titleController.text,
                                'content': contentController.text,
                                'category': categoryController.text,
                                'is_pinned': isPinned,
                                'is_locked': isLocked,
                                'updated_at': DateTime.now().toIso8601String(),
                              })
                              .eq('id', topic['id']);

                          // Refresh data
                          await _loadData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Topic updated successfully'),
                              ),
                            );
                          }
                        } catch (error) {
                          setState(() {
                            _isLoading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating topic: $error'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B6EA5),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _editForumReply(Map<String, dynamic> reply) async {
    // Show dialog to edit reply
    final contentController = TextEditingController(text: reply['content']);
    bool isSolution = reply['is_solution'] ?? false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Edit Forum Reply'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Reply Content',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Mark as Solution'),
                        value: isSolution,
                        onChanged: (value) {
                          setDialogState(() {
                            isSolution = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        try {
                          setState(() {
                            _isLoading = true;
                          });

                          // Update the reply using the "Admins can update any forum reply" policy
                          await supabase
                              .from('forum_replies')
                              .update({
                                'content': contentController.text,
                                'is_solution': isSolution,
                                'updated_at': DateTime.now().toIso8601String(),
                              })
                              .eq('id', reply['id']);

                          // Refresh data
                          await _loadData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reply updated successfully'),
                              ),
                            );
                          }
                        } catch (error) {
                          setState(() {
                            _isLoading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating reply: $error'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B6EA5),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _viewUserDetails(Map<String, dynamic> user) async {
    final userId = user['id'];

    // Get user's topics count
    final topicsCount =
        _forumTopics.where((topic) => topic['user_id'] == userId).length;

    // Get user's replies count
    final repliesCount =
        _forumReplies.where((reply) => reply['user_id'] == userId).length;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('User: ${_getUserFullName(user)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user['profile_picture_url'] != null)
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        user['profile_picture_url'],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Email: ${user['email'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Phone: ${user['phone'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Admin: ${user['is_admin'] ? 'Yes' : 'No'}'),
                const SizedBox(height: 8),
                Text('Joined: ${_formatFullDateTime(user['created_at'])}'),
                const SizedBox(height: 8),
                Text('Topics created: $topicsCount'),
                const SizedBox(height: 8),
                Text('Replies posted: $repliesCount'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6EA5),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        title: const Padding(
          padding: EdgeInsets.only(bottom: 28.0, top: 28.0),
          child: Text(
            'Community Moderation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF27445D),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Topics'),
            Tab(text: 'Replies'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                                : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Users Tab
                          _buildUsersTab(),

                          // Topics Tab
                          _buildTopicsTab(),

                          // Replies Tab
                          _buildRepliesTab(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _getFilteredUsers();
    return filteredUsers.isEmpty
        ? const Center(child: Text('No users found'))
        : ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final fullName = _getUserFullName(user);
            final isAdmin = user['is_admin'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading:
                    user['profile_picture_url'] != null
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            user['profile_picture_url'],
                          ),
                        )
                        : const CircleAvatar(child: Icon(Icons.person)),
                title: Row(
                  children: [
                    Text(fullName.isEmpty ? 'No Name' : fullName),
                    if (isAdmin)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? 'No Email'),
                    Text('Joined ${_formatDateTime(user['created_at'])}'),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _viewUserDetails(user),
                ),
              ),
            );
          },
        );
  }

  Widget _buildTopicsTab() {
    final filteredTopics = _getFilteredTopics();
    return filteredTopics.isEmpty
        ? const Center(child: Text('No topics found'))
        : ListView.builder(
          itemCount: filteredTopics.length,
          itemBuilder: (context, index) {
            final topic = filteredTopics[index];
            final userInfo = topic['users'] ?? {};
            final authorName =
                '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'
                    .trim();
            final isPinned = topic['is_pinned'] ?? false;
            final isLocked = topic['is_locked'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.push_pin, size: 16),
                          ),
                        if (isLocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.lock, size: 16),
                          ),
                        Expanded(
                          child: Text(
                            topic['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topic['category'] != null &&
                            topic['category'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              topic['category'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'By: ${authorName.isEmpty ? 'Unknown User' : authorName}',
                        ),
                        Text('Posted: ${_formatDateTime(topic['created_at'])}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      topic['content'] ?? 'No content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editForumTopic(topic),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Topic'),
                                  content: const Text(
                                    'Are you sure you want to delete this topic? This will also delete all replies.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteForumTopic(topic['id']);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildRepliesTab() {
    final filteredReplies = _getFilteredReplies();
    return filteredReplies.isEmpty
        ? const Center(child: Text('No replies found'))
        : ListView.builder(
          itemCount: filteredReplies.length,
          itemBuilder: (context, index) {
            final reply = filteredReplies[index];
            final userInfo = reply['users'] ?? {};
            final authorName =
                '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'
                    .trim();
            final topicInfo = reply['forum_topics'] ?? {};
            final isSolution = reply['is_solution'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Text(
                          'Reply to: ${topicInfo['title'] ?? 'Unknown Topic'}',
                        ),
                        if (isSolution)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Solution',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By: ${authorName.isEmpty ? 'Unknown User' : authorName}',
                        ),
                        Text('Posted: ${_formatDateTime(reply['created_at'])}'),
                        if (reply['updated_at'] != reply['created_at'])
                          Text(
                            'Edited: ${_formatDateTime(reply['updated_at'])}',
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(reply['content'] ?? 'No content'),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editForumReply(reply),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Reply'),
                                  content: const Text(
                                    'Are you sure you want to delete this reply?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteForumReply(reply['id']);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
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
