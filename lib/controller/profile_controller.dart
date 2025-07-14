import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:yet_chat_plus/controller/user_controller.dart';
import 'dart:io';

class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  final UserController userController = Get.find<UserController>();

  final RxInt followerCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxBool isFollowing = false.obs;
  final RxInt postCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    // Controller kapanırken observable'ları temizle
    followerCount.close();
    followingCount.close();
    isFollowing.close();
    postCount.close();
    super.onClose();
  }

  Future<void> updateUserProfile({
    required String fullName,
    File? newImageFile,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      String? finalImageUrl;

      if (newImageFile != null) {
        final userId = currentUser.id;
        final filePath = '$userId/avatar.png';

        await supabase.storage
            .from('profile-pictures')
            .upload(
              filePath,
              newImageFile,
              fileOptions: FileOptions(
                contentType: lookupMimeType(newImageFile.path),
                upsert: true,
              ),
            );

        finalImageUrl =
            '${supabase.storage.from('profile-pictures').getPublicUrl(filePath)}?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final Map<String, dynamic> updates = {'fullName': fullName};

      if (finalImageUrl != null) {
        updates['image_url'] = finalImageUrl;
      }

      await supabase.from('Users').update(updates).eq('UID', currentUser.id);

      Get.back();
      Get.snackbar('Başarılı', 'Profilin başarıyla güncellendi.');

      userController.fetchUserData();

      // final userProvider = provider.Provider.of<UserProvider>(
      //   Get.context!,
      //   listen: false,
      // );
      // await userProvider.fetchUserData();
    } catch (e) {
      Get.back();
      Get.snackbar('Hata', 'Profil güncellenirken bir sorun oluştu.');
      print("Profil güncelleme hatası: $e");
    }
  }

  Future<void> getProfileData(String profileUserId) async {
    // Bu metodun başında isLoading'i true yapmıyoruz çünkü toggleFollow içinde
    // anlık bir güncelleme yapıyoruz, tam ekran yükleme animasyonu istenmiyor.
    // Sadece ilk yüklemede veya refresh'te isLoading kullanılmalı.
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final results = await Future.wait<dynamic>([
        supabase
            .from('followers')
            .select('count')
            .eq('following_id', profileUserId)
            .single()
            .then((response) => (response['count'] as int?) ?? 0),
        supabase
            .from('followers')
            .select('count')
            .eq('follower_id', profileUserId)
            .single()
            .then((response) => (response['count'] as int?) ?? 0),
        supabase
            .from('Posts')
            .select('count')
            .eq('user_id', profileUserId)
            .single()
            .then((response) => (response['count'] as int?) ?? 0),
        supabase
            .from('followers')
            .select()
            .eq('follower_id', currentUser.id)
            .eq('following_id', profileUserId)
            .maybeSingle(),
      ]);

      followerCount.value = results[0] as int;
      followingCount.value = results[1] as int;
      postCount.value = results[2] as int;
      isFollowing.value = (results[3] as Map?) != null;
    } catch (e) {
      print('Profil verisi getirme hatası: $e');
      Get.snackbar('Hata', 'Profil bilgileri güncellenirken bir sorun oluştu.');
      // HATA DÜZELTMESİ: Yakalanan hatayı bir üst katmana fırlatıyoruz.
      // Bu, toggleFollow'un catch bloğunun çalışmasını sağlar.
      rethrow;
    }
  }

  Future<void> checkIfFollowing(String userId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null || currentUser.id == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          isFollowing.value = false;
        }
      });
      return;
    }

    final response = await supabase
        .from('followers')
        .count(CountOption.exact)
        .eq('follower_id', currentUser.id)
        .eq('following_id', userId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        isFollowing.value = response > 0;
      }
    });
  }

  Future<void> toggleFollow(String followingId) async {
    // HATA DÜZELTMESİ: Hata anında geri dönebilmek için orijinal değerleri saklıyoruz.
    final originalFollowStatus = isFollowing.value;
    final originalFollowerCount = followerCount.value;

    // İyimser Arayüz Güncellemesi (Optimistic UI Update)
    isFollowing.value = !originalFollowStatus;
    if (isFollowing.value) {
      followerCount.value++;
    } else {
      followerCount.value--;
    }

    try {
      final response = await supabase.functions.invoke(
        'toggle-follow',
        body: {'following_id': followingId},
      );

      if (response.status != 200) {
        throw 'Sunucu hatası: ${response.status} - ${response.data}';
      }

      // İşlem başarılı olduğu için sunucudaki en güncel veriyle arayüzü
      // tekrar senkronize etmek iyi bir pratiktir.
      await getProfileData(followingId);
    } catch (e) {
      // HATA DÜZELTMESİ: Hata durumunda arayüzü hesaplama yapmak yerine
      // doğrudan orijinal değerlere geri döndürüyoruz.
      isFollowing.value = originalFollowStatus;
      followerCount.value = originalFollowerCount;

      print('Takip işlemi hatası: $e');
      Get.snackbar('Hata', 'İşlem sırasında bir sorun oluştu.');
    }
  }

  Future<List<Map<String, dynamic>>> getFollowerList(String userId) async {
    final response = await supabase
        .from('followers')
        .select('follower:follower_id(*)')
        .eq('following_id', userId);

    return (response as List)
        .map((item) => item['follower'] as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFollowingList(String userId) async {
    final response = await supabase
        .from('followers')
        .select('following:following_id(*)')
        .eq('follower_id', userId);

    return (response as List)
        .map((item) => item['following'] as Map<String, dynamic>)
        .toList();
  }
}
