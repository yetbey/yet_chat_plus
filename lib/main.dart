import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_chat_plus/routes/app_pages.dart';
import 'package:yet_chat_plus/routes/app_routes.dart';
import 'package:yet_chat_plus/services/push_notification_service.dart';
import 'package:yet_chat_plus/theme/app_theme.dart';
import 'package:yet_chat_plus/theme/theme_controller.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bindings/initial_binding.dart';

import 'firebase_options.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await initializeDateFormatting('tr_TR', null);

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint(
        'Environment file yüklenemedi, varsayılan değerler kullanılıyor',
      );
    }

    await GetStorage.init();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await PushNotificationService().initialize();

    runApp(YetChatPlus());
  } catch (e, stackTrace) {
    debugPrint('Uygulama başlatma hatası: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(const ErrorApp());
  }
}

class YetChatPlus extends StatefulWidget {
  const YetChatPlus({super.key});

  @override
  State<YetChatPlus> createState() => _YetChatPlusState();
}

class _YetChatPlusState extends State<YetChatPlus> {
  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YET Connect Plus',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.theme,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.authWrapper,
      getPages: AppPages.getPages,
      defaultTransition: Transition.fadeIn,
      enableLog: false,
      navigatorObservers: [],
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Uygulama başlatılırken bir hata oluştu',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Uygulamayı yeniden başlat
                  main();
                },
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
