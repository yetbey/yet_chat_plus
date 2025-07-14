import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/models/notification_model.dart' as app_models;

class NotificationController extends GetxController {
  final supabase = Supabase.instance.client;

  final notifications = <app_models.NotificationModel>[].obs;
  final isLoading = false.obs;
  final hasUnread = false.obs;


  RealtimeChannel? _notificationsChannel;


  @override
  void onClose() {
    _notificationsChannel?.unsubscribe();
    super.onClose();
  }

  Future<void> fetchNotifications() async {
    if (supabase.auth.currentUser == null) return;
    try {
      isLoading.value = true;
      final response = await supabase
          .from('notifications')
          .select('''
            *,
            from_user:from_user_id ( fullName, image_url ),
            post:post_id ( image_url )
          ''')
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      // --- DEĞİŞİKLİK 3: Gelen veriyi kendi modelimize dönüştürürken takma adı kullanıyoruz ---
      final List<app_models.NotificationModel> fetchedNotifs = (response as List)
          .map((item) => app_models.NotificationModel.fromJson(item))
          .toList();

      notifications.value = fetchedNotifs;
      checkUnread();

    } catch (e) {
      print('Bildirimleri getirme hatası: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void subscribeToNotifications() {
    if (supabase.auth.currentUser == null) return;
    _notificationsChannel = supabase.channel('public:notifications');
    _notificationsChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: supabase.auth.currentUser!.id,
      ),
      callback: (payload) {
        // Yeni bildirim geldiğinde listeyi yenile
        fetchNotifications();
      },
    ).subscribe();
  }

  void checkUnread() {
    hasUnread.value = notifications.any((n) => !n.isRead);
  }

  Future<void> markAllAsRead() async {
    final unreadIds = notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      try {
        // --- DEĞİŞİKLİK BURADA: .in_() yerine .filter() kullanıyoruz ---
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .filter('id', 'in', unreadIds); // .in_ yerine bu satırı kullan

        for (var notif in notifications) {
          if (!notif.isRead) {
            notif.isRead = true;
          }
        }
        notifications.refresh();
        checkUnread();

      } catch (e) {
        print('Okundu olarak işaretleme hatası: $e');
      }
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      // Anlık UI güncellemesi için önce lokal listeden kaldır
      notifications.removeWhere((n) => n.id == notificationId);

      // Sonra veritabanından kalıcı olarak sil
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      // Okunmamış bildirim durumunu yeniden kontrol et
      checkUnread();

    } catch (e) {
      Get.snackbar('Hata', 'Bildirim silinirken bir sorun oluştu.');
      print('Bildirim silme hatası: $e');
      // Hata durumunda, tutarlılık için listeyi yeniden çek
      fetchNotifications();
    }
  }

}