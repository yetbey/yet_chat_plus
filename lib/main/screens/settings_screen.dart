import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/constants/app_constants.dart';
import 'package:yet_chat_plus/controller/user_controller.dart';
import 'package:yet_chat_plus/main/screens/profile_screen.dart';
import 'package:yet_chat_plus/yet_bank/bank_profile_screen.dart';
import '../../controller/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final SettingsController settingsController = Get.put(SettingsController());
    final AuthController authController = Get.find<AuthController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final UserController userController = Get.find<UserController>();

    bool notificationsEnabled = true;
    bool vibrationEnabled = false;
    String selectedLanguage = 'Türkçe';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: InkWell(
                onTap: () {
                  if (authController.user?.id != null) {
                    Get.to(() => ProfileScreen(userId: authController.user?.id));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Obx( () => Row(
                      children: [
                        Obx(() {
                          return CircleAvatar(
                            radius: 35,
                            backgroundImage:
                            userController.imageUrl.value != null
                                ? NetworkImage(userController.imageUrl.value!)
                                : null,
                            child:
                            userController.imageUrl.value == null
                                ? const Icon(Icons.person, size: 35)
                                : null,
                          );
                        }),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userController.userName.value ?? "Kullanıcı Adı",
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authController.user?.email ?? "E-posta",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildSectionHeader('Ayarlar', Iconsax.setting, context),
            _buildMaterialSwitchTile(
              title: 'Karanlık Mod',
              subtitle: 'Koyu tema kullan',
              value: themeController.isDarkMode.value,
              onChanged: (value) {
                themeController.changeThemeMode(value);
              },
              icon: Icons.dark_mode_outlined,
            ),
            _buildLanguageTile(selectedLanguage, context, (language) => selectedLanguage = language ),

            _buildMaterialSwitchTile(
              title: 'Bildirimler',
              subtitle: 'Tüm bildirimleri etkinleştir',
              value: notificationsEnabled,
              onChanged: (value) {
                  notificationsEnabled = value;
              },
              icon: Icons.notifications_active_outlined,
            ),
            _buildMaterialTile(
              title: 'Bildirim Sesi',
              subtitle: 'Varsayılan',
              icon: Icons.volume_up_outlined,
              onTap: () {},
            ),
            _buildMaterialSwitchTile(
              title: 'Titreşim',
              subtitle: 'Bildirimler için titreşim',
              value: vibrationEnabled,
              onChanged: (value) {
                  vibrationEnabled = value;
              },
              icon: Icons.vibration_outlined,
            ),
            _buildMaterialTile(
              title: 'Gizlilik Ayarları',
              subtitle: 'Veri paylaşımı ve izinler',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
            _buildMaterialTile(
              title: 'Şifre Değiştir',
              subtitle: 'En son 30 gün önce değiştirildi',
              icon: Icons.password_outlined,
              onTap: () {},
            ),
            _buildMaterialTile(
              title: 'İki Faktörlü Doğrulama',
              subtitle: 'Hesabınızı daha güvenli hale getirin',
              icon: Icons.security_outlined,
              onTap: () {},
            ),

            // _buildSectionHeader('Hakkında', Icons.info_outline),
            _buildMaterialTile(
              title: 'Uygulama Versiyonu',
              subtitle: AppConstants.appVersion,
              icon: Icons.info_outline,
              onTap: () {},
            ),
            _buildMaterialTile(
              title: 'Lisanslar',
              subtitle: 'Açık kaynak lisansları',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            _buildMaterialTile(
              title: 'YET Bank',
              subtitle: 'Çok yakında...',
              icon: Iconsax.card,
              onTap:
                  () => Get.to(
                BankProfileScreen(),
                transition: Transition.rightToLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Supabase.instance.client.auth.signOut();
                    Get.offAllNamed(AppRoutes.authWrapper);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Text('Çıkış Yap'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: () {
                  // İşlemin geri alınamaz olduğunu belirtmek için bir onay kutusu göster
                  Get.defaultDialog(
                    backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                    title: "Emin misiniz?",
                    titleStyle: TextStyle(fontWeight: FontWeight.bold),
                    middleText:
                    "Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve profiliniz, gönderileriniz, sohbetleriniz dahil tüm verileriniz kalıcı olarak silinecektir.",
                    textConfirm: "Evet, Hesabımı Sil",
                    textCancel: "İptal",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    cancelTextColor: Colors.white,
                    onConfirm: () {
                      // Dialog'u kapat ve silme işlemini başlat
                      Get.back();
                      authController.deleteAccount();
                    },
                  );
                },
                label: Text(
                  'Hesabı Sil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                icon: Icon(Iconsax.trash, size: 20),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  foregroundColor: WidgetStateProperty.all(Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Widget _buildSectionHeader(String title, IconData icon, BuildContext conttext) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Row(
      children: [
        // Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            // color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMaterialSwitchTile({
  required String title,
  required String subtitle,
  required bool value,
  required Function(bool) onChanged,
  required IconData icon,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    elevation: 0,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
        activeColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Widget _buildMaterialTile({
  required String title,
  required String subtitle,
  required IconData icon,
  required Function() onTap,
}) {
  return Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Widget _buildLanguageTile(String selectedLanguage, BuildContext context, Function(String) onSelect) {
  return Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: ListTile(
        selectedColor: Colors.black,
        title: const Text('Dil'),
        subtitle: Text(selectedLanguage),
        leading: const Icon(Icons.language_outlined),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Dil Seçin',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildLanguageOption('Türkçe', selectedLanguage, context, onSelect),
                    _buildLanguageOption('English', selectedLanguage, context, onSelect),
                    _buildLanguageOption('Deutsch', selectedLanguage, context, onSelect),
                    _buildLanguageOption('Français', selectedLanguage, context, onSelect),
                    _buildLanguageOption('Español', selectedLanguage, context, onSelect),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

Widget _buildLanguageOption(String language, String selectedLanguage, BuildContext context, Function(String) onSelect) {
  final isSelected = selectedLanguage == language;
  return ListTile(
    title: Text(language),
    trailing:
    isSelected
        ? Icon(
      Icons.check_circle,
      color: Theme.of(context).colorScheme.primary,
    )
        : null,
    onTap: () {
        selectedLanguage = language;
      Navigator.pop(context);
    },
    tileColor:
    isSelected
        ? Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.3)
        : null,
  );
}
