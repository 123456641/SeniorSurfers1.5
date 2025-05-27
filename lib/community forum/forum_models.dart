// forum_models.dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ForumUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String? email;
  final bool isAdmin;

  ForumUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    this.email,
    this.isAdmin = false,
  });

  String get fullName => '$firstName $lastName';

  factory ForumUser.fromJson(Map<String, dynamic> json) {
    return ForumUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      email: json['email'],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture_url': profilePictureUrl,
      'email': email,
      'is_admin': isAdmin,
    };
  }
}

class ForumTopic {
  final String id;
  final String title;
  final String content;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final int viewCount;
  final String? category;
  ForumUser? user; // User who created the topic

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.viewCount = 0,
    this.category,
    this.user,
  });
}
