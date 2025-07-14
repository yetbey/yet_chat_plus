// lib/models/notification_model.dart
class NotificationModel {
  final int id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserAvatar;
  final String type;
  final int? postId;
  final int? chatId;
  final String? postImageUrl;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.type,
    this.postId,
    this.chatId,
    this.postImageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      fromUserId: json['from_user_id'],
      fromUserName: json['from_user']?['fullName'] ?? 'Bir kullanıcı',
      fromUserAvatar: json['from_user']?['image_url'],
      type: json['type'],
      postId: json['post_id'],
      chatId: json['chat_id'],
      postImageUrl: json['post']?['image_url'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}