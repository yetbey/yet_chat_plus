import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yet_chat_plus/controller/profile_controller.dart';
import 'package:yet_chat_plus/main/screens/settings_screen.dart';
import 'package:get/get.dart';
import 'feed_screen.dart';
import 'modern_users_screen.dart';
import 'notification_screen.dart';
import 'package:yet_chat_plus/controller/ui_controller.dart';

class NavigatorScreen extends StatefulWidget {
  static const String id = 'navigator_screen';
  const NavigatorScreen({super.key});
  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  int _selectedIndex = 0;
  final UIController uiController = Get.find<UIController>();
  final ProfileController profileController = Get.put(ProfileController());
  DateTime? lastBackPressed;

  final List<Widget> _widgetOptions = [
    FeedScreen(),
    ModernUsersScreen(),
    NotificationScreen(),
    SettingsPage(),
    // ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height:
              uiController.isNavBarVisible.value
                  ? kBottomNavigationBarHeight + 30
                  : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                color: theme.bottomAppBarTheme.color,
                boxShadow: [
                  BoxShadow(blurRadius: 20, color: Colors.black.withAlpha(26)),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 8,
                  ),
                  child: GNav(
                    rippleColor: theme.colorScheme.secondary.withAlpha(26),
                    hoverColor: theme.colorScheme.secondary.withAlpha(26),
                    haptic: true,
                    tabBorderRadius: 15,
                    tabActiveBorder: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1,
                    ),
                    tabBackgroundColor: theme.colorScheme.primary.withAlpha(26),
                    duration: const Duration(milliseconds: 400),
                    gap: 6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    color: theme.iconTheme.color?.withAlpha(204),
                    activeColor: theme.colorScheme.primary,

                    tabs: [
                      const GButton(
                        icon: Iconsax.home_hashtag,
                        text: 'Feed / Akış',
                      ),
                      const GButton(icon: Iconsax.message, text: 'Sohbetler'),
                      GButton(icon: Iconsax.notification, text: 'Bildirimler'),
                      const GButton(icon: Iconsax.setting, text: 'Ayarlar'),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
