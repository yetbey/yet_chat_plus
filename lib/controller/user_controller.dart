import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();

  final supabase = Supabase.instance.client;

  // --- Reaktif Değişkenler ---
  final Rxn<String> userId = Rxn<String>();
  final Rxn<String> userName = Rxn<String>();
  final Rxn<String> email = Rxn<String>();
  final Rxn<String> phoneNumber = Rxn<String>();
  final Rxn<String> imageUrl = Rxn<String>();
  final Rxn<String> info = Rxn<String>();
  final Rxn<int> followers = Rxn<int>();
  final Rxn<int> following = Rxn<int>();
  final Rxn<int> postCount = Rxn<int>();

  // Bu liste, oturum açan kullanıcının sohbet ettiği diğer kullanıcıların bilgilerini tutar.
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;

  StreamSubscription<AuthState>? _authSubscription;

  // --- Helper ---
  User? get _currentUser => supabase.auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        fetchUserData();
        loadChatUsers();
      } else if (event == AuthChangeEvent.signedOut) {
        clearAllUserData();
      }
    });

    if (_currentUser != null) {
      fetchUserData();
      loadChatUsers();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void clearAllUserData() {
    users.clear();
    userName.value = null;
    email.value = null;
    phoneNumber.value = null;
    imageUrl.value = null;
    userId.value = null;
  }

  /// Kullanıcıyı sohbet listesinden ve veritabanından siler.
  Future<void> removeUserByEmail(String email) async {
    try {
      final user = _currentUser;
      if (user == null) return;

      final otherUser = users.firstWhereOrNull((u) => u['email'] == email);
      if (otherUser == null || otherUser['UID'] == null) {
        Get.snackbar('Hata', 'Kullanıcı bilgisi bulunamadı.');
        return;
      }
      final otherUserId = otherUser['UID'];

      // **DÜZELTME:** .or() filtresi, koşulları içeren tek bir string alır.
      // Koşullar virgülle ayrılır.
      await supabase.from('chats').delete().or(
        'and(user1_id.eq.${user.id},user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.${user.id})',
      );

      users.removeWhere((u) => u['email'] == email);
      Get.snackbar('Başarılı', 'Sohbet silindi.');
    } catch (error) {
      Get.snackbar('Hata', 'Sohbet silinemedi: $error');
    }
  }

  /// Oturum açan kullanıcının dahil olduğu tüm sohbetleri ve
  /// bu sohbetlerdeki diğer kullanıcıların bilgilerini yükler.
  Future<void> loadChatUsers() async {
    try {
      final user = _currentUser;
      if (user == null) return;

      final response = await supabase
          .from('chats')
          .select('user1_id, user2_id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}');

      if (response.isEmpty) {
        users.clear();
        return;
      }

      final otherUserIds = response.map((chat) {
        return chat['user1_id'] == user.id
            ? chat['user2_id']
            : chat['user1_id'];
      }).toSet().toList();

      if (otherUserIds.isEmpty) {
        users.clear();
        return;
      }

      // **DÜZELTME:** .in_() filtresi bu şekilde doğru kullanılır.
      // Eğer hala hata alıyorsanız, lütfen 'flutter pub get' komutunu çalıştırarak
      // supabase_flutter paketini güncellediğinizden emin olun.
      final usersData = await supabase
          .from('Users')
          .select('UID, fullName, email, image_url').inFilter('UID', otherUserIds);

      users.assignAll(usersData);
    } catch (error) {
      Get.snackbar('Hata', 'Sohbetler yüklenemedi: $error');
    }
  }

  /// Tüm kullanıcıları keşfetmek için çeker.
  Future<void> fetchAllUsers() async {
    try {
      final response = await supabase
          .from('Users')
          .select('fullName, email, image_url, created_at')
          .order('created_at', ascending: true);
      users.value = (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      Get.snackbar('Hata', 'Kullanıcılar çekilemedi: $error');
    }
  }

  /// Email ile bir kullanıcı bulur ve onunla yeni bir sohbet başlatır.
  Future<bool> addUserByEmail(String email) async {
    try {
      // **DÜZELTME:** Null kontrolü daha güvenli hale getirildi.
      final user = _currentUser;
      if (user == null) return false; // Önce user'ın null olup olmadığını kontrol et.

      // Sonra user'ın email'ine güvenle eriş.
      if (user.email == email) {
        Get.snackbar('Hata', 'Kendinizle sohbet başlatamazsınız.');
        return false;
      }

      final targetUserResponse = await supabase
          .from('Users')
          .select('UID, fullName, email, image_url')
          .eq('email', email)
          .maybeSingle();

      if (targetUserResponse == null) {
        Get.snackbar('Bulunamadı', 'Bu e-posta adresine sahip bir kullanıcı yok.');
        return false;
      }
      final targetUserId = targetUserResponse['UID'];

      // **DÜZELTME:** .or() filtresi, koşulları içeren tek bir string alır.
      final existingChat = await supabase
          .from('chats')
          .select('id')
          .or(
        'and(user1_id.eq.${user.id},user2_id.eq.$targetUserId),and(user1_id.eq.$targetUserId,user2_id.eq.${user.id})',
      )
          .maybeSingle();

      if (existingChat != null) {
        Get.snackbar('Bilgi', 'Bu kullanıcı ile zaten bir sohbetiniz var.');
        if (!users.any((u) => u['UID'] == targetUserId)) {
          users.add(targetUserResponse);
        }
        return true;
      }

      await supabase.from('chats').insert({
        'user1_id': user.id,
        'user2_id': targetUserId,
      });

      users.add(targetUserResponse);
      Get.snackbar('Başarılı', 'Sohbet başlatıldı.');
      return true;
    } catch (error) {
      Get.snackbar('Hata', 'Sohbet başlatılamadı: $error');
      return false;
    }
  }

  /// Oturum açmış kullanıcının profil verilerini çeker.
  Future<void> fetchUserData() async {
    try {
      final user = _currentUser;
      if (user == null) return;

      final response =
      await supabase.from('Users').select().eq('UID', user.id).single();

      userId.value = user.id;
      userName.value = response['username'] as String?;
      email.value = response['email'] as String?;
      phoneNumber.value = response['phoneNumber'] as String?;
      imageUrl.value = response['image_url'] as String?;
    } catch (error) {
      print('Kullanıcı verisi çekilirken hata oluştu: $error');
    }
  }

  /// Kullanıcının profil resmini günceller.
  Future<void> updateImage(XFile imageFile) async {
    try {
      final user = _currentUser;
      if (user == null) return;

      final file = File(imageFile.path);
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'profile-pictures/$fileName';

      await supabase.storage.from('profile-pictures').upload(filePath, file);
      final String newImageUrl =
      supabase.storage.from('profile-pictures').getPublicUrl(filePath);

      await supabase
          .from('Users')
          .update({'image_url': newImageUrl}).eq('UID', user.id);

      imageUrl.value = newImageUrl;

      Get.snackbar('Başarılı', 'Profil resminiz güncellendi.');
    } catch (error) {
      Get.snackbar('Hata', 'Resim yüklenemedi: $error');
    }
  }
}