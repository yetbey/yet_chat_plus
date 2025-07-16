import 'dart:async';
import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/controller/user_controller.dart';
import '../authentication/services/auth_service.dart';
import '../routes/app_routes.dart';
import '../services/push_notification_service.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;
  final _notificationService = PushNotificationService();
  final _box = GetStorage();
  final _user = Rx<User?>(null);
  User? get user => _user.value;
  final AuthService _authService = Get.put(AuthService());
  final UserController userController = Get.find<UserController>();
  // final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final email = ''.obs;
  final isRegistering = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    _user.value = supabase.auth.currentUser;
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user.value = session?.user;

      if (event == AuthChangeEvent.signedIn) {
        _notificationService.getAndSaveToken();
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        if (Get.currentRoute != AppRoutes.newPassword) {
          Get.toNamed(AppRoutes.newPassword);
        }
      }
    });
    super.onInit();
  }

  Future<void> sigInWithGoogleFirebase() async {

  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phoneNumber,
    File? imageFile,
  }) async {
    isLoading.value = true;
    try {
      String? imageUrl;

      if (imageFile != null) {
        final filePath = 'avatar.png';

        await supabase.storage
            .from('profile-pictures')
            .upload(
              filePath,
              imageFile,
              fileOptions: FileOptions(
                contentType: lookupMimeType(imageFile.path),
                upsert: true,
              ),
            );
        imageUrl = supabase.storage
            .from('profile-pictures')
            .getPublicUrl(filePath);
      }

      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'fullName': fullName,
          'username': username,
          'image_url': imageUrl,
          'phoneNumber': phoneNumber,
        },
      );

      if (res.user != null) {
        Get.snackbar(
          'Başarılı',
          'Lütfen e-postanıza gönderilen kodu girerek hesabınızı doğrulayın.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.toNamed(AppRoutes.otpVerification, arguments: email);
      } else {
        handleError(
          'Kayıt sırasında bir hata oluştu. Lütfen bilgilerinizi kontrol ediniz.',
        );
      }
    } on AuthException catch (e) {
      handleError(e.message);
    } catch (e) {
      handleError('Beklenmedik bir hata luştu : $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: email,
      );

      if (res.session != null) {
        Get.offAllNamed(AppRoutes.navigatorScreen);
      } else {
        handleError('OTP doğrulanamadı. Lütfen tekrar deneyin.');
      }
    } on AuthException catch (e) {
      handleError(e.message);
    } catch (e) {
      handleError('Beklenmedik bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        Get.offAllNamed(AppRoutes.navigatorScreen);
      }
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        handleError('Lütfen giriş yapmadan önce e-postanızı doğrulayın.');
        Get.toNamed(AppRoutes.otpVerification, arguments: email);
      } else {
        handleError(e.message);
      }
    } catch (e) {
      handleError('Beklenmedik bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    isLoading.value = true;
    try {
      await supabase.auth.resetPasswordForEmail(email);
      Get.snackbar(
        'E-posta Gönderildi',
        'Şifrenizi sıfırlamak için e-posta adresinize bir link gönderdik.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Kullanıcıyı bilgilendirdikten sonra bir önceki ekrana dönebiliriz.
      Get.back();
    } on AuthException catch (e) {
      handleError(e.message);
    } catch (e) {
      handleError('Beklenmedik bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    isLoading.value = true;
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar(
        'Başarılı',
        'Şifreniz başarıyla güncellendi.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Kullanıcıyı ana ekrana veya giriş ekranına yönlendir.
      Get.offAllNamed(AppRoutes.navigatorScreen);
    } on AuthException catch (e) {
      handleError(e.message);
    } catch (e) {
      handleError('Beklenmedik bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------- \\

  // Send OTP With Email for users who forget password
  Future<void> sendOTP(String email) async {
    if (email.isEmpty) {
      errorMessage.value = 'Lütfen e-posta adresinizi girin';
      Get.snackbar(
        'Hata',
        'Lütfen e-posta adresinizi girin',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      isLoading.value = true;
      this.email.value = email;
      isRegistering.value = false;
      errorMessage.value = '';

      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );

      Get.snackbar(
        'Başarılı',
        'Doğrulama kodu e-posta adresinize gönderildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Kod gönderilirken bir hata oluştu: ${e.toString()}';
      Get.snackbar(
        'Hata',
        'Kod gönderilirken bir hata oluştu: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendOtpToPhone(String phoneNumber) async {
    isLoading.value = true;
    try {
      await _authService.signInWithOtp(phoneNumber);
      // Başarılı olursa OTP girme ekranına yönlendir
      Get.toNamed(AppRoutes.otpVerification, arguments: phoneNumber);
    } catch (e) {
      Get.snackbar(
        'OTP Gönderme Hatası',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _notificationService.removeFCMToken();
      await supabase.auth.signOut();
      // Önbelleği temizle
      await _box.erase();
      // Giriş ekranına yönlendir.
      Get.offAllNamed(AppRoutes.authenticationUI);
    } catch (e) {
      handleError('Çıkış yapılırken bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    isLoading.value = true;
    try {
      await _authService.deleteAccount();

      Get.snackbar(
        'Başarılı',
        'Hesabınız ve tüm verileriniz kalıcı olarak silindi.',
      );
      await signOut();
    } catch (e) {
      Get.snackbar('Hata', e.toString().replaceAll('Exception: ', ''));
      // Hata durumunda isLoading'i false yapalım ki buton tekrar aktif olsun
      isLoading.value = false;
    }
  }

  void handleError(String message) {
    Get.snackbar('Hata Var', message, backgroundColor: Colors.red);
  }
}
