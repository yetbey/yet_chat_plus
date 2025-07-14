import 'package:get/get.dart';

class UIController extends GetxController {
  // Navigasyon barının görünürlüğünü tutan reaktif değişken.
  // Başlangıçta görünür (true) olmalı.
  final RxBool isNavBarVisible = true.obs;

  /// Navigasyon barını gösterir.
  void showNavBar() {
    // Sadece zaten gizliyse durumunu değiştirir.
    if (!isNavBarVisible.value) {
      isNavBarVisible.value = true;
    }
  }

  /// Navigasyon barını gizler.
  void hideNavBar() {
    // Sadece zaten görünürse durumunu değiştirir.
    if (isNavBarVisible.value) {
      isNavBarVisible.value = false;
    }
  }
}