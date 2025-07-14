import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';

class ForgetPasswordPage extends StatelessWidget {
  ForgetPasswordPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Text(
                  'Şifreni Sıfırla',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                    'Kayıtlı e-posta adresinizi girin, size şifrenizi sıfırlamanız için bir link göndereceğiz.'),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value!.isEmail ? null : 'Geçerli bir e-posta girin',
                ),
                const SizedBox(height: 40),
                Obx( () => ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _authController.sendPasswordResetEmail(
                        email: _emailController.text.trim(),
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
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
