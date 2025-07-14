import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yet_chat_plus/authentication/screens/authentication_ui.dart';
import 'package:yet_chat_plus/controller/auth_controller.dart';
import 'package:yet_chat_plus/main/screens/navigator_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthController authController = Get.find();

  @override
  void initState() {
    super.initState();
    // Bu kontrolü, build metodu çalışmadan, güvenli bir şekilde initState içinde yapıyoruz
    _checkFirstRunAndClearSession();
  }

  void _checkFirstRunAndClearSession() {
    final box = GetStorage();
    // Hafızada 'first_run_completed' diye bir anahtar var mı diye bak.
    // Eğer yoksa (yani null ise), bu uygulamanın ilk açılışıdır.
    final bool hasRunBefore = box.read('first_run_completed') ?? false;

    if (!hasRunBefore) {
      print("İLK AÇILIŞ TESPİT EDİLDİ: Tüm oturumlar temizleniyor.");
      // Bunun ilk açılış olduğunu anladık.
      // Her ihtimale karşı Supabase'deki 'hayalet oturumu' temizlemek için signOut çağır.
      authController.signOut();

      // Gelecekteki açılışların ilk olmadığını anlamak için işareti hafızaya yaz.
      box.write('first_run_completed', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Artık normal Obx mantığına tamamen güvenebiliriz.
    // Eğer ilk çalıştırmaysa, signOut çağrıldığı için authController.user null olacak ve LoginScreen'e gidecek.
    // Eğer ilk çalıştırma değilse, mevcut session durumuna göre doğru ekranı gösterecek.
    return Obx(() {
      if (authController.user != null) {
        return const NavigatorScreen();
      } else {
        return const AuthenticationUI();
      }
    });
  }
}
