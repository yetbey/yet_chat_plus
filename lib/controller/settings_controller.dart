import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _box = GetStorage();

  // Ayarlar için reaktif değişkenler ve varsayılan değerleri
  final RxBool notificationsEnabled = true.obs;
  final RxDouble textSize = 16.0.obs;
  final RxString selectedLanguage = 'Türkçe'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Kayıtlı ayarları hafızadan yükleyen fonksiyon
  void loadSettings() {
    notificationsEnabled.value = _box.read('notifications_enabled') ?? true;
    textSize.value = _box.read('text_size') ?? 16.0;
    selectedLanguage.value = _box.read('language') ?? 'Türkçe';
    print("Ayarlar yüklendi.");
  }

  /// Bildirim ayarını değiştiren ve kaydeden fonksiyon
  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    _box.write('notifications_enabled', value);
  }

  /// Yazı boyutu ayarını değiştiren ve kaydeden fonksiyon
  void changeTextSize(double value) {
    textSize.value = value;
    _box.write('text_size', value);
  }

  /// Dil ayarını değiştiren ve kaydeden fonksiyon
  void changeLanguage(String value) {
    selectedLanguage.value = value;
    _box.write('language', value);
    Get.back(); // Dil seçimi yapıldıktan sonra alttaki menüyü kapat
  }
}