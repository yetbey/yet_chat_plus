import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_chat_plus/controller/notification_controller.dart';
import 'package:yet_chat_plus/main/screens/chat_screen.dart';
import 'package:yet_chat_plus/models/notification_model.dart';
import 'package:yet_chat_plus/main/screens/profile_screen.dart';
import 'package:yet_chat_plus/main/components/shimmer_notification_tile.dart';
import 'package:yet_chat_plus/main/components/empty_state_widget.dart';
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:yet_chat_plus/main/screens/detailed_post_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController notificationController = Get.find<NotificationController>();
  final PostController postController = Get.find<PostController>();

  @override
  void initState() {
    super.initState();
    notificationController.fetchNotifications();
    // Sayfa açıldığında tüm bildirimleri okundu olarak işaretle
    notificationController.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bildirimler')),
      body: Obx(() {
        if (notificationController.isLoading.value && notificationController.notifications.isEmpty) {
          return ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => const ShimmerNotificationTile(),
          );
        }
        if (notificationController.notifications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_off_outlined,
            title: 'Bildirim Yok',
            subtitle: 'Yeni bir etkileşim (beğeni, yorum, takip) olduğunda burada görünecek.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => notificationController.fetchNotifications(),
          child: ListView.builder(
            itemCount: notificationController.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationController.notifications[index];
              return Dismissible(
                key: Key(notification.id.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  notificationController.deleteNotification(notification.id);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white)),
                child: _buildNotificationTile(notification),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    String title = '';
    String time = timeago.format(notification.createdAt, locale: 'tr');
    IconData icon;

    switch (notification.type) {
      case 'follow':
        title = '${notification.fromUserName} seni takip etmeye başladı.';
        icon = Icons.person_add;
        break;
      case 'like':
        title = '${notification.fromUserName} gönderini beğendi.';
        icon = Icons.favorite;
        break;
      case 'comment':
        title = '${notification.fromUserName} gönderine yorum yaptı.';
        icon = Icons.comment;
        break;
      default:
        title = 'Yeni bir bildiriminiz var.';
        icon = Icons.notifications;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: notification.fromUserAvatar != null && notification.fromUserAvatar!.isNotEmpty
            ? NetworkImage(notification.fromUserAvatar!)
            : null,
        child: notification.fromUserAvatar == null || notification.fromUserAvatar!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text.rich(
          TextSpan(
              text: notification.fromUserName,
              // Yazı stilini temadan alıyoruz
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: ' ${title.replaceFirst(notification.fromUserName, '')}',
                  style: Theme.of(context).textTheme.bodyMedium, // Normal kalınlık
                )
              ]
          )
      ),
      subtitle: Text(
        time,
        // Yazı stilini ve rengini temadan alıyoruz
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      trailing: notification.postImageUrl != null
          ? ClipRRect( // Resim köşelerini yuvarlatmak için
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(notification.postImageUrl!, width: 50, height: 50, fit: BoxFit.cover),
      )
          : null,
      onTap: () async {
        // Bildirimin tipine göre yönlendirme yap
        switch (notification.type) {
          case 'follow':
            Get.to(() => ProfileScreen(userId: notification.fromUserId));
            break;

          case 'message':
          // Eğer mesaj bildirimi ise ve chatId varsa sohbete git
            if (notification.chatId != null) {
              // Get.to(() => ChatScreen(
              //   chatId: notification.chatId!,
              //   otherUser: notification.otherUser,
              // ));
            }
            break;

          case 'like':
          case 'comment':
          if (notification.postId != null) {
            // Önce gönderi verisini çek, sonra detay sayfasına git
            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            final post = await postController.getPostById(notification.postId!);
            Get.back(); // Yükleme animasyonunu kapat

            if (post != null) {
              Get.to(() => DetailedPostScreen(post: post));
            } else {
              Get.snackbar('Hata', 'Gönderi bulunamadı veya silinmiş.');
            }
          }
          break;
        }
      },
      tileColor: !notification.isRead ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
    );
  }
}