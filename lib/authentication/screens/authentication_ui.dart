import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yet_chat_plus/authentication/screens/login_screen.dart';
import 'package:yet_chat_plus/authentication/screens/sign_up_screen.dart';
import '../../constants/app_constants.dart';
import '../../constants/assets_constants.dart';

class AuthenticationUI extends StatefulWidget {
  const AuthenticationUI({super.key});

  @override
  State<AuthenticationUI> createState() => _AuthenticationUIState();
}

class _AuthenticationUIState extends State<AuthenticationUI> {
  Future<void> _requestPermissions() async {
    if (await Permission.bluetooth.status.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothConnect.status.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetoothScan.status.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.location.status.isDenied) {
      await Permission.location.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              AssetsConstants.mainImage,
              filterQuality: FilterQuality.high,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => Get.to(
                            LoginPage(),
                            transition: Transition.rightToLeft,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Giriş Yap'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(
                          SignupPage(),
                          transition: Transition.rightToLeft,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        AppConstants.register,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppConstants.urbanSemi,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: AppConstants.urban,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
