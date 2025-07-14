import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/controller/message_controller.dart';
import 'package:yet_chat_plus/models/message_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../models/post_model.dart';
import 'detailed_post_screen.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageController messageController = Get.find<MessageController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  Message? _replyingToMessage;

  String get otherUserId => widget.otherUser['UID'];
  String get otherUserName => widget.otherUser['fullName'];
  String get otherUserImageUrl => widget.otherUser['image_url'];

  @override
  void initState() {
    super.initState();
    // Veri yükleme ve kaydırma işlemlerini yönetecek yeni fonksiyonu çağır
    _loadInitialMessagesAndScroll();

    // Anlık yeni mesajları dinle
    messageController.joinChatScreenChannel(widget.chatId);

    messageController.messages.stream.listen((list) {
      if (mounted &&
          _listKey.currentState != null &&
          _listKey.currentState!.widget.initialItemCount < list.length) {
        try {
          _listKey.currentState!.insertItem(list.length - 1, duration: const Duration(milliseconds: 300));
        } catch (e) {
          print("AnimatedList hatası (normal olabilir): $e");
        }
      }
      // Yeni bir mesaj geldiğinde de en alta kaydır
      _scrollToBottom(isAnimated: true);
    });
  }

  Future<void> _loadInitialMessagesAndScroll() async {
    // Önce ekranın boş olduğundan emin ol
    messageController.messages.clear();
    // 1. Geçmiş mesajları çek ve bu işlemin bitmesini bekle
    await messageController.fetchMessages(widget.chatId);

    // 2. Veri çekildikten ve UI'ın ilk çizimi bittikten sonra en alta kaydır.
    // Bu, en güvenilir yöntemdir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(isAnimated: false); // İlk açılışta animasyonsuz kaydır
    });
  }

  @override
  void dispose() {
    messageController.leaveChatScreenChannel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);

    if (image != null) {
      // Resim gönderirken 'imageFile'ı veriyoruz
      await messageController.sendMessage(
        chatId: widget.chatId,
        otherUserId: otherUserId,
        imageFile: File(image.path),
        replyingTo: _replyingToMessage,
      );
      _cancelReply();
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      // Artık sadece bu birleştirilmiş fonksiyonu kullanıyoruz
      messageController.sendMessage(
        chatId: widget.chatId,
        otherUserId: otherUserId,
        content: _textController.text.trim(), // Metin gönderirken 'content'i veriyoruz
        replyingTo: _replyingToMessage,
      );
      _textController.clear();
      _cancelReply();
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _scrollToBottom({bool isAnimated = true}) {
    if (!_scrollController.hasClients) return;

    final bottomOffset = _scrollController.position.maxScrollExtent;

    // Eğer animasyonlu olacaksa, pürüzsüz bir şekilde kaydır
    if (isAnimated) {
      _scrollController.animateTo(
        bottomOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // İlk açılışta anında en altta başlaması için doğrudan atla
      _scrollController.jumpTo(bottomOffset);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    String dateText;
    if (dateToCompare == today) {
      dateText = 'Bugün';
    } else if (dateToCompare == yesterday) {
      dateText = 'Dün';
    } else {
      dateText = DateFormat.yMMMMd('tr_TR').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary  ,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (messageController.isLoadingMessages.value &&
                  messageController.messages.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return AnimatedList(
                key: _listKey,
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                initialItemCount: messageController.messages.length,
                itemBuilder: (context, index, animation) {
                  if (index >= messageController.messages.length) return SizedBox.shrink();
                  final message = messageController.messages[index];
                  final bool showDateSeparator = index == 0 || !_isSameDay(
                    message.createdAt,
                    messageController.messages[index - 1].createdAt,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: Column(
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message.createdAt),
                        Slidable(
                          key: ValueKey(message.id),
                          startActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) { setState(() { _replyingToMessage = message; }); },
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                icon: Icons.reply,
                                label: 'Yanıtla',
                              ),
                            ],
                          ),
                          child: _MessageBubble(
                            message: message,
                            otherUserName: otherUserName,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          if (_replyingToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingToMessage!.senderId ==
                                  Supabase.instance.client.auth.currentUser!.id
                              ? "Siz"
                              : otherUserName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          _replyingToMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close), onPressed: _cancelReply),
                ],
              ),
            ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: _pickAndSendImage, // Yeni resim seçme fonksiyonunu çağır
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Mesaj yaz...", border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }


}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.otherUserName});
  final Message message;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.senderId == Supabase.instance.client.auth.currentUser!.id;
    final bool isReply = message.repliedToMessage != null;

    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
      bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
    );

    // --- TÜM RENKLERİ ARTIK TEMADAN ALIYORUZ ---
    final bubbleColor = isMe ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.onTertiary;
    final textColor = isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant;
    final timeColor = isMe ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);
    final replyBackgroundColor = isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
    final replyTextColor = isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: bubbleRadius,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReply)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: replyBackgroundColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.repliedToMessage!.senderId == Supabase.instance.client.auth.currentUser!.id ? "Siz" : otherUserName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: replyTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.repliedToMessage!.content,
                      style: TextStyle(fontSize: 13, color: replyTextColor.withOpacity(0.9)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            if (message.type == 'text')
            // --- DEĞİŞİKLİK BURADA: Fazladan 'isMe' parametresini kaldırdık ---
              _buildTextMessage(textColor, timeColor)
            else if (message.type == 'image')
              _buildImageMessage(context)
            else if (message.type == 'post_share' && message.sharedPost != null)
                _buildSharedPostMessage(context, message.sharedPost!, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(Color textColor, Color timeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.Hm('tr_TR').format(message.createdAt),
            style: TextStyle(fontSize: 10, color: timeColor),
          ),
        ],
      ),
    );
  }

  // Resim mesajlarını çizen metod
  Widget _buildImageMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.content,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildSharedPostMessage(BuildContext context, PostModel post, Color textColor) {
    return GestureDetector(
      onTap: () => Get.to(() => DetailedPostScreen(post: post)),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(post.userProfileImage ?? '')),
                const SizedBox(width: 8),
                Text(post.userFullName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            if(post.imageUrl != null && post.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.imageUrl!),
              ),
            if(post.caption != null && post.caption!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(post.caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

}


