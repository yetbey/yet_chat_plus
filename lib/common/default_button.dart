import 'package:flutter/material.dart';

import '../constants/constants.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    this.bgColor = kPrimaryColor,
    this.fgColor = kScaffoldBackgroundColor,
    this.label = 'Default',
    this.axisAlignment = true,
    required this.onPressed,
  });

  final String label;
  final Color bgColor;
  final Color fgColor;
  final bool axisAlignment;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
