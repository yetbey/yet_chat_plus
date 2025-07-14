import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchController extends GetxController {
  final supabase = Supabase.instance.client;

  final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasSearched = false.obs; // Kullanıcının arama yapıp yapmadığını tutar

  Timer? _debounce;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // Kullanıcıları arayan ana fonksiyon
  Future<void> searchUsers(String query) async {
    // Arama kutusu boşsa listeyi temizle ve çık
    if (query.isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;

    try {
      // Supabase'de 'ilike' ile büyük/küçük harf duyarsız arama yapıyoruz
      // '%' wildcard'ları, kelimenin herhangi bir yerinde geçmesini sağlar
      final response = await supabase
          .from('Users')
          .select()
          .ilike('fullName', '%$query%')
          .limit(20); // Sonuçları sınırlandıralım

      searchResults.value = (response as List).map((e) => e as Map<String, dynamic>).toList();

    } catch (e) {
      print('Arama hatası: $e');
      Get.snackbar('Hata', 'Arama yapılırken bir sorun oluştu.');
    } finally {
      isLoading.value = false;
    }
  }

  // Her tuşa basıldığında veritabanını yormamak için "debouncing" tekniği
  void onSearchChanged(String query) {
    // Mevcut bir zamanlayıcı varsa iptal et
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Yeni bir arama yapmak için yarım saniye bekle
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchUsers(query);
    });
  }

  void clearSearch() {
    searchResults.clear();
    hasSearched.value = false;
  }
}