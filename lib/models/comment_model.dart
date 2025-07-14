// lib/models/comment_model.dart

class CommentModel {
  final int id;
  final int postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String userName;
  final String? userProfileImage;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.userName,
    this.userProfileImage,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      // Yorum yapan kullanıcının bilgilerini iç içe geçmiş 'Users' nesnesinden alıyoruz
      userName: json['Users']?['fullName'] ?? 'Bilinmeyen Kullanıcı',
      userProfileImage: json['Users']?['image_url'],
    );
  }
}