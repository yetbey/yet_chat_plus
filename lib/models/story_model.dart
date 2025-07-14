class Story {
  final int id;
  final String userId;
  final String userName;
  final String fullName;
  final String? userImageUrl;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.fullName,
    this.userImageUrl,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['user']?['fullName'] ?? 'Kullanıcı',
      userName: json['user']?['username'] ?? 'Kullanıcı',
      userImageUrl: json['user']?['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}