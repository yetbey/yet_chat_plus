import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/notification_controller.dart';
import '../controller/notification_handler_controller.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _fcm.requestPermission();
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    await _initLocalNotifications();
    _initPushNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
  }

  /// Bildirime tıklandığında, yönlendirme işini doğrudan yapmak yerine,
  /// veriyi daha sonra işlenmek üzere NotificationHandlerController'a kaydeder.
  void _handleNotificationTap(RemoteMessage message) {
    log("Notification tapped with data: ${message.data}");
    if (message.data.isNotEmpty) {
      Get.find<NotificationHandlerController>().setPayload(message.data);
    }
  }

  void _initPushNotifications() {
    // Android için yüksek öncelikli bildirim kanalı oluşturur.
    // Bu, bildirimlerin banner olarak görünmesini sağlar.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Uygulama kapalıyken (terminated) açıldığında gelen bildirimi yönet
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // Uygulama arka plandayken bildirim tıklandığında tetiklenir
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Uygulama ön plandayken (açıkken) bildirim geldiğinde tetiklenir
    FirebaseMessaging.onMessage.listen((message) {
      log("Foreground App: Notification received -> ${message.notification?.title}");
      final notification = message.notification;
      if (notification != null) {
        // Yerel bildirimi göstererek banner'ın çıkmasını sağla
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher', // veya özel bir ikon adı
            ),
          ),
        );
      }
      // Mevcut bildirim listesini yenile
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchNotifications();
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Token yönetimi metodları aynı kalıyor
  Future<void> getAndSaveToken() async {
    final token = await _fcm.getToken();
    log("FCM Token requested for current user: $token");
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        await _supabase
            .from('Users')
            .update({'fcm_token': token})
            .eq('UID', currentUser.id);
        log("FCM Token saved successfully for user ${currentUser.id}.");
      } catch (e) {
        log("Error saving FCM token: $e");
      }
    }
  }

  Future<void> removeFCMToken() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        await _supabase
            .from('Users')
            .update({'fcm_token': null})
            .eq('UID', currentUser.id);
        log("FCM Token removed successfully for user ${currentUser.id}.");
      } catch (e) {
        log("Error removing FCM token: $e");
      }
    }
  }
}
