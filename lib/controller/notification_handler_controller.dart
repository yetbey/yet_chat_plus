import 'dart:developer';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:yet_chat_plus/main/screens/detailed_post_screen.dart';

import '../models/post_model.dart';

class NotificationHandlerController extends GetxController {
  // İşlenmeyi bekleyen bildirim verisini tutacak olan reaktif değişken.
  final Rx<Map<String, dynamic>?> _pendingNotificationPayload = Rx(null);

  @override
  void onInit() {
    super.onInit();
    // _pendingNotificationPayload değişkenini sürekli dinle.
    // Değeri her değiştiğinde (ve null olmadığında) içindeki fonksiyon çalışır.
    ever(_pendingNotificationPayload, (payload) {
      if (payload != null) {
        log("Payload detected by 'ever' worker: $payload");
        _processPayload(payload);
        // İşlendikten sonra payload'ı hemen temizle ki tekrar tetiklenmesin.
        clearPayload();
      }
    });
  }

  /// Gelen bildirim verisini ayarlar, bu da 'ever' worker'ını tetikler.
  void setPayload(Map<String, dynamic> data) {
    _pendingNotificationPayload.value = data;
  }

  /// Veriyi temizler.
  void clearPayload() {
    _pendingNotificationPayload.value = null;
  }

  /// Gelen veriyi işleyip doğru sayfaya yönlendiren ana mantık.
  Future<void> _processPayload(Map<String, dynamic> data) async {
    final String? type = data['type'];

    // Yönlendirme yapmadan önce tüm controller'ların hazır olması için kısa bir gecikme eklemek
    // uygulamanın yeni açıldığı durumlar için daha güvenilirdir.
    await Future.delayed(const Duration(milliseconds: 500));

    if (type == 'new_like') {
      final String? postIdString = data['postId'];
      if (postIdString != null) {
        try {
          final int postId = int.parse(postIdString);
          final PostController postController = Get.find();
          final PostModel? post = await postController.fetchPostById(postId);
          if (post != null) {
            Get.to(DetailedPostScreen(post: post));
          }
        } catch (e) {
          log("Error navigating from notification: $e");
        }
      }
    }
    // TODO: Diğer bildirim türleri (yeni yorum, yeni mesaj vs.) için
    // else if blokları buraya eklenebilir.
  }
}
