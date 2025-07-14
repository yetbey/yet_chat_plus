import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_chat_plus/controller/message_controller.dart';
import 'package:yet_chat_plus/models/chat_model.dart';
import 'package:yet_chat_plus/main/screens/chat_screen.dart';
import 'package:yet_chat_plus/main/components/shimmer_chat_tile.dart';
import 'package:yet_chat_plus/main/components/empty_state_widget.dart';

class ModernUsersScreen extends StatefulWidget {
  const ModernUsersScreen({super.key});

  @override
  State<ModernUsersScreen> createState() => _ModernUsersScreenState();
}

class _ModernUsersScreenState extends State<ModernUsersScreen> {
  final MessageController messageController = Get.find<MessageController>();

  @override
  void initState() {
    super.initState();
    messageController.fetchChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sohbetler")),
      body: Obx(() {
        if (messageController.isLoadingChats.value && messageController.chats.isEmpty) {
          return ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => const ShimmerChatTile(),
          );
        }
        if (messageController.chats.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.chat_bubble_outline,
            title: 'Henüz Sohbet Yok',
            subtitle: 'Yeni bir sohbet başlatmak için bir kullanıcının profiline gidip mesaj gönderin.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => messageController.fetchChats(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: messageController.chats.length,
            separatorBuilder:(context, index) => Divider(
              height: 1,
              thickness: 1,
              indent: 80, // Sol taraftan boşluk
              endIndent: 16, // Sağ taraftan boşluk
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final Chat chat = messageController.chats[index];
              final String formattedTime = chat.lastMessageTime != null
                  ? timeago.format(chat.lastMessageTime!, locale: 'tr')
                  : '';
              return Dismissible(
                key: Key(chat.id.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction){
                  messageController.deleteChat(chat.id);
                  Get.snackbar(
                    'Sohbet Silindi!',
                    '${chat.otherUserName} ile olan sohbetiniz silinmişir.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: chat.otherUserImageUrl != null ? NetworkImage(chat.otherUserImageUrl!) : null,
                    child: chat.otherUserImageUrl == null ? Icon(Icons.person) : null,
                  ),
                  title: Text(chat.otherUserName, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    chat.lastMessage ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formattedTime, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      // --- OKUNMAMIŞ MESAJ ROZETİ (BADGE) ---
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                    ],
                  ),
                  onTap: () {
                    Get.to(() => ChatScreen(
                      chatId: chat.id,
                      otherUser: chat.otherUser,
                    ));
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}