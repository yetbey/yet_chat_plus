import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Bilinmeyen bir hata oluştu.');
    }
  }

  // Kayıt olma fonksiyonu (SENİN KODUNA GÖRE TAMAMEN DÜZELTİLDİ)
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phoneNumber,
    File? imageFile,
  }) async {
    try {
      final usernameCheck = await _supabase
          .from('Users')
          .select('username')
          .eq('username', username.trim().toLowerCase());

      if (usernameCheck.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten alınmış.');
      }

      final authResponse = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw Exception("Kullanıcı oluşturulamadı.");
      }

      final userId = authResponse.user!.id;
      String? imageUrl;

      if (imageFile != null) {
        final filePath = '$userId/avatar.png';
        final fileExtension = path.extension(imageFile.path);
        final fileName = '${Uuid().v4()}$fileExtension';
        final mimeType = lookupMimeType(imageFile.path);

        await _supabase.storage.from('profile-pictures').upload(
          filePath,
          imageFile,
          fileOptions: FileOptions(contentType: lookupMimeType(imageFile.path), upsert: true),
        );
        imageUrl = _supabase.storage.from('profile-pictures').getPublicUrl(filePath);
      }

        await _supabase.from('Users').insert({
          'UID': userId,
          'email': email.trim(),
          'fullName': fullName.trim(),
          'username': username.trim().toLowerCase(),
          'phoneNumber': phoneNumber.trim(),
          'image_url': imageUrl,
        });
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Bilinmeyen bir hata oluştu.');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Çıkış yapılırken bir hata oluştu.');
    }
  }

  Future<void> signInWithOtp(String phoneNumber) async {
    try {
      // Telefon numarasının başına ülke kodu eklemeyi unutma (örneğin +90)
      // Bu kısmı UI'da veya burada formatlayabilirsin.
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } on AuthException catch (e) {
      print('OTP gönderme hatası (AuthService): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Beklenmedik OTP gönderme hatası (AuthService): $e');
      throw Exception('OTP gönderilirken bilinmeyen bir hata oluştu.');
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: otp,
      );
      // Başarılı doğrulama sonrası onAuthStateChange stream'i otomatik olarak
      // 'signedIn' event'ini tetikleyecektir.
    } on AuthException catch (e) {
      print('OTP doğrulama hatası (AuthService): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Beklenmedik OTP doğrulama hatası (AuthService): $e');
      throw Exception('OTP doğrulanırken bilinmeyen bir hata oluştu.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final response = await _supabase.functions.invoke('delete-user', method: HttpMethod.post);
      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Hesap silinirken bir sunucu hatası oluştu.');
      }
    } catch (e) {
      print('Hesap silme hatası (AuthService): $e');
      throw Exception('Hesap silinirken bir hata oluştu.');
    }
  }

}
