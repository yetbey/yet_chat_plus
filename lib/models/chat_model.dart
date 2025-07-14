class Chat {
  final int id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  final Map<String, dynamic> user1;
  final Map<String, dynamic> user2;
  final String currentUserId;

  Chat({
    required this.id,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.user1,
    required this.user2,
    required this.currentUserId,
  });

  Map<String, dynamic> get otherUser {
    if (user1.isEmpty) return user2;
    if (user2.isEmpty) return user1;
    return user1['UID'] == currentUserId ? user2 : user1;
  }

  String get otherUserId => otherUser['UID'] ?? '';
  String get otherUserName => otherUser['fullName'] ?? 'Kullanıcı';
  String? get otherUserImageUrl => otherUser['image_url'];

  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    return Chat(
      id: json['id'],
      lastMessage: json['last_message']?['content'],
      lastMessageTime: json['last_message']?['created_at'] != null
          ? DateTime.parse(json['last_message']['created_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      user1: json['user1'] ?? {},
      user2: json['user2'] ?? {},
      currentUserId: currentUserId,
    );
  }
}