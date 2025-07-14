import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import '../../common/common.dart';
import '../../common/custom_Elevated_button.dart';
import '../../routes/app_routes.dart';
import '../components/fade_in_animation.dart';

class PasswordChangesPage extends StatefulWidget {
  const PasswordChangesPage({super.key});

  @override
  State<PasswordChangesPage> createState() => _PasswordChangesPageState();
}

class _PasswordChangesPageState extends State<PasswordChangesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFE8ECF4),
      body: SafeArea(
        child: Column(
          children: [
            LottieBuilder.asset("assets/images/ticker.json"),
            FadeInAnimation(
              delay: 1,
              child: Text(
                "Password Changed!",
                style: Common().titleTheme,
              ),
            ),
            FadeInAnimation(
              delay: 1.5,
              child: Text(
                "Your password has been changed successfully",
                style: Common().mediumThemeBlack,
              ),
            ),
            SizedBox(
              height: 30,
            ),
            FadeInAnimation(
              delay: 2,
              child: CustomElevatedButton(
                message: "Back to Login",
                onPressed: () {
                  Get.toNamed(AppRoutes.login);
                },
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}