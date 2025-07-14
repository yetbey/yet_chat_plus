import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/notification_handler_controller.dart';
import '../authentication/services/auth_service.dart';
import '../controller/auth_controller.dart';
import '../controller/message_controller.dart';
import '../controller/notification_controller.dart';
import '../controller/performance_controller.dart';
import '../controller/post_controller.dart';
import '../controller/profile_controller.dart';
import '../controller/settings_controller.dart';
import '../controller/story_controller.dart';
import '../controller/ui_controller.dart';
import '../controller/user_controller.dart';
import '../theme/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PerformanceController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => ThemeController(), fenix: true);
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => StoryController(), fenix: true);
    Get.lazyPut(() => UIController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => PostController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => MessageController(), fenix: true);
    Get.put(NotificationHandlerController());
  }
}