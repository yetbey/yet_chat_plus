import 'package:get/get.dart';

class PostModel {
  final int id;
  final String userId;
  final String? caption;
  final String? imageUrl;
  final DateTime createdAt;
  final String? userFullName;
  final String? userProfileImage;
  int commentCount;
  final String? username;

  final RxInt likes;
  final RxBool isLikedByCurrentUser;

  PostModel({
    required this.id,
    required this.userId,
    this.caption,
    this.imageUrl,
    required this.username,
    required this.createdAt,
    required int initialLikes,
    required bool initialIsLiked,
    required this.commentCount,
    this.userFullName,
    this.userProfileImage,
  }) : likes = initialLikes.obs,
       isLikedByCurrentUser = initialIsLiked.obs;

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    bool isLiked = false,
  }) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      imageUrl: json['image_url'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
      initialLikes: json['likes'] ?? 0,
      initialIsLiked: isLiked, // Beğeni durumunu dışarıdan alacağız
      userFullName: json['user_fullName'],
      commentCount: json['comment_count'] ?? 0,
      userProfileImage: json['user_profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'likes': likes.value,
      'comment_count': commentCount,
      'Users': {
        // Join'den gelen veriyi aynı formatta saklayalım
        'fullName': userFullName,
        'image_url': userProfileImage,
        'username': username,
      },
    };
  }
}
