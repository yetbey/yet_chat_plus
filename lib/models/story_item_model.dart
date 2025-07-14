class StoryItem {
  final int id;
  final int storyId;
  final String type;
  final String mediaUrl;
  final DateTime createdAt;

  StoryItem({
    required this.id,
    required this.storyId,
    required this.type,
    required this.mediaUrl,
    required this.createdAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'],
      storyId: json['story_id'],
      type: json['type'],
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}