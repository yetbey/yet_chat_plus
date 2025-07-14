import 'package:get/get.dart';
import 'package:yet_chat_plus/main/screens/settings_screen.dart';
import '../authentication/screens/auth_wrapper.dart';
import '../authentication/screens/authentication_ui.dart';
import '../authentication/screens/forget_password.dart';
import '../authentication/screens/login_screen.dart';
import '../authentication/screens/new_password_screen.dart';
import '../authentication/screens/otp_verification.dart';
import '../authentication/screens/password_changed.dart';
import '../authentication/screens/sign_up_screen.dart';
import '../main/screens/create_post_screen.dart';
import '../main/screens/search_screen.dart';
import '../main/screens/navigator_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final getPages = [
    GetPage(
      name: AppRoutes.authWrapper,
      page: () => const AuthWrapper(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => CreatePostScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      // Ayarlar için sağdan sola kayma efekti (iOS tarzı)
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => SignupPage(),
    ),
    GetPage(
      name: AppRoutes.authenticationUI,
      page: () => const AuthenticationUI(),
    ),
    GetPage(
      name: AppRoutes.forgetPassword,
      page: () => ForgetPasswordPage(),
    ),
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const NewPasswordPage(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => OtpVerificationPage(),
    ),
    GetPage(
      name: AppRoutes.passwordChanges,
      page: () => const PasswordChangesPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.navigatorScreen,
      page: () => const NavigatorScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}