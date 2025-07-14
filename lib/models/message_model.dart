import 'post_model.dart';
import 'dart:io';

class Message {
  final int id;
  final int chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String type;
  final int? replyToMessageId;
  Message? repliedToMessage;
  final int? sharedPostId;
  PostModel? sharedPost;
  final File? localImageFile;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.type,
    this.replyToMessageId,
    this.repliedToMessage,
    this.sharedPostId,
    this.sharedPost,
    this.localImageFile,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final repliedMessageData = json['replied_message'];
    final sharedPostData = json['shared_post'];
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'] ?? 'text',
      replyToMessageId: json['reply_to_message_id'],
      repliedToMessage:
          repliedMessageData != null
              ? Message.fromJson(repliedMessageData)
              : null,
      sharedPostId: json['shared_post_id'],
      sharedPost:
          sharedPostData != null
              ? PostModel.fromJson(sharedPostData, isLiked: false)
              : null,
    );
  }
}
