// lib/authentication/screens/otp_verification.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../controller/auth_controller.dart';

class OtpVerificationPage extends StatelessWidget {
  OtpVerificationPage({super.key});

  final _authController = Get.find<AuthController>();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Argüman olarak gönderilen e-posta adresini al
  final String email = Get.arguments as String;

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  'Doğrulama Kodu',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '$email adresine gönderilen 6 haneli kodu girin.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration?.copyWith(
                      color: const Color.fromRGBO(234, 239, 243, 1),
                    ),
                  ),
                  validator: (s) {
                    return s?.length == 6 ? null : 'Lütfen 6 haneli kodu girin';
                  },
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _authController.verifyEmailOtp(
                        email: email,
                        token: _pinController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white70,
                    foregroundColor: Colors.black54,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: Text('Kayıt Ol'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // TODO: Yeniden OTP gönderme fonksiyonunu ekle
                    Get.snackbar('Bilgi', 'Yeniden kod gönderme özelliği eklenecek.');
                  },
                  child: const Text('Kodu tekrar gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
