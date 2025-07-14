import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/common.dart';
import 'package:get/get.dart';
import '../../common/custom_Elevated_button.dart';
import '../../controller/auth_controller.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _usernameController = TextEditingController();

  File? _imageFile;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
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
                    Get.back();
                  },
                  icon: const Icon(CupertinoIcons.back, size: 35),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kayıt Olmaya Başlayalım",
                        style: Common().titleTheme,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextFormField(
                          hintText: 'Tam Adınız',
                          obscureText: false,
                          controller: _fullNameController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'Email',
                          obscureText: false,
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          hintText: 'Kullanıcı Adı',
                          obscureText: false,
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          hintText: 'Parola',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          hintText: 'Telefon Numarası',
                          obscureText: false,
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _pickImage,
                          child: Text('Resim Seç'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _authController.signUpWithEmail(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                fullName: _fullNameController.text.trim(),
                                username: _usernameController.text.trim(),
                                phoneNumber: _phoneNumberController.text.trim(),
                                imageFile: _imageFile,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white70,
                            foregroundColor: Colors.black54,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Kayıt Ol'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text("Yada Devam Et", style: Common().semiBoldBlack),
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SvgPicture.asset("images/facebook_ic (1).svg"),
                              SvgPicture.asset("images/google_ic-1.svg"),
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

// class SignupPage extends StatefulWidget {
//   const SignupPage({super.key});
//   @override
//   State<SignupPage> createState() => _SignupPageState();
// }
//
// class _SignupPageState extends State<SignupPage> {
//   final AuthController authController = Get.find<AuthController>();
//   final supabase = Supabase.instance.client;
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _fullNameController = TextEditingController();
//   final _phoneNumberController = TextEditingController();
//   final _usernameController = TextEditingController();
//   File? _imageFile;
//   final isPasswordVisible = false.obs;
//   final isConfirmPasswordVisible = false.obs;
//
//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _fullNameController.dispose(); // <-- YENİ
//     _emailController.dispose();
//     _phoneNumberController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   void _onSignUpPressed() {
//     // Formun geçerli olup olmadığını kontrol et
//     if (_formKey.currentState?.validate() ?? false) {
//       authController.signUp(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         fullName: _fullNameController.text.trim(),
//         username: _usernameController.text.trim(),
//         phoneNumber: _phoneNumberController.text.trim(),
//         imageFile: _imageFile,
//       );
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   onPressed: () {
//                     Get.back();
//                   },
//                   icon: const Icon(CupertinoIcons.back, size: 35),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Kayıt Olmaya Başlayalım",
//                         style: Common().titleTheme,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         CustomTextFormField(
//                           hintText: 'Tam Adınız',
//                           obscureText: false,
//                           controller: _fullNameController,
//                         ),
//                         const SizedBox(height: 10),
//                         CustomTextFormField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           hintText: 'Email',
//                           obscureText: false,
//                         ),
//                         const SizedBox(height: 10),
//                         CustomTextFormField(
//                           hintText: 'Kullanıcı Adı',
//                           obscureText: false,
//                           controller: _usernameController,
//                         ),
//                         const SizedBox(height: 10),
//                         CustomTextFormField(
//                           hintText: 'Parola',
//                           obscureText: true,
//                           controller: _passwordController,
//                         ),
//                         const SizedBox(height: 10),
//                         CustomTextFormField(
//                           hintText: 'Telefon Numarası',
//                           obscureText: false,
//                           controller: _phoneNumberController,
//                           keyboardType: TextInputType.number,
//                         ),
//                         const SizedBox(height: 10),
//                         TextButton(onPressed: _pickImage, child: Text('Resim Seç')),
//                         const SizedBox(height: 10),
//                         Obx(
//                           () =>
//                               authController.isLoading.value
//                                   ? Center(child: CircularProgressIndicator())
//                                   : ElevatedButton(
//                                     onPressed: _onSignUpPressed,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.white70,
//                                       foregroundColor: Colors.black54,
//                                       minimumSize: Size(double.infinity, 50),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(
//                                           12,
//                                         ),
//                                       ),
//                                     ),
//                                     child:
//                                         authController.isLoading.value
//                                             ? SizedBox(
//                                               width: 24,
//                                               height: 24,
//                                               child:
//                                                   CircularProgressIndicator(
//                                                     color: Colors.white,
//                                                   ),
//                                             )
//                                             : Text('Kayıt Ol'),
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: SizedBox(
//                     height: 160,
//                     width: double.infinity,
//                     child: Column(
//                       children: [
//                         Text(
//                           "Yada Devam Et",
//                           style: Common().semiBoldBlack,
//                         ),
//                         const SizedBox(height: 20),
//                         Padding(
//                           padding: const EdgeInsets.only(
//                             top: 10,
//                             bottom: 10,
//                             right: 30,
//                             left: 30,
//                           ),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               SvgPicture.asset("images/facebook_ic (1).svg"),
//                               SvgPicture.asset("images/google_ic-1.svg"),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
