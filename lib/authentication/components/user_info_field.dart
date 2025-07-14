import 'package:flutter/material.dart';
import '../../constants/constants.dart';

class UserInfoField extends StatelessWidget {
  const UserInfoField({
    super.key,
    required TextEditingController controller,
    this.title,
    this.validator,
    this.obscureText = false,
    this.textInputType,
  }) : _emailController = controller;

  final TextEditingController _emailController;
  final String? title;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? textInputType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      controller: _emailController,
      keyboardType: textInputType,
      validator: validator,
      decoration: kTextFieldDecoration.copyWith(
        hintText: title,
      ),
    );
  }
}