import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yet_chat_plus/authentication/screens/authentication_ui.dart';
import 'package:yet_chat_plus/authentication/screens/sign_up_screen.dart';
import 'package:yet_chat_plus/common/common.dart';
import 'package:yet_chat_plus/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../../common/custom_Elevated_button.dart';
import '../../controller/auth_controller.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final authController = Get.put(AuthController());
  final isPasswordVisible = false.obs;

  Future<void> login() async {
    try {
      Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Get.toNamed(AppRoutes.navigatorScreen);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Get.to(AuthenticationUI(), transition: Transition.leftToRight);
                  },
                  icon: const Icon(CupertinoIcons.back, size: 35),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.welcomeAgain,
                        style: Common().titleTheme,
                      ),
                      Text(AppConstants.appName, style: Common().titleTheme),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    child: Column(
                      children: [
                        CustomTextFormField(
                          controller: _emailController,
                          hintText: AppConstants.enterEmail,
                          obscureText: false,
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => TextFormField(
                            obscureText: !isPasswordVisible.value,
                            // onFieldSubmitted: (_) => _handleLogin(),
                            controller: _passwordController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(18),
                              hintText: AppConstants.enterPassword,
                              hintStyle: Common().hintText,
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => isPasswordVisible.toggle(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.forgetPassword);
                            },
                            child: Text(
                              AppConstants.forgetPassword,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppConstants.urbanSemi,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              authController.signInWithEmail(email: email, password: password);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white70,
                              foregroundColor: Colors.black54,
                            ),
                            child: Text('Giriş Yap'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text(
                          AppConstants.withoutLogin,
                          style: Common().semiBoldBlack,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            right: 30,
                            left: 30,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset("images/facebook_ic (1).svg"),
                              SvgPicture.asset("images/google_ic-1.svg"),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppConstants.noAccountYet,
                                style: Common().hintText,
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.to(SignupPage(), transition: Transition.rightToLeft);
                                },
                                child: Text(
                                  AppConstants.register,
                                  style: Common().mediumTheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
