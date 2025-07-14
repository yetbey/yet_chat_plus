import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerChatTile extends StatelessWidget {
  const ShimmerChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        leading: const CircleAvatar(radius: 30, backgroundColor: Colors.white),
        title: Container(
          height: 16,
          width: MediaQuery.of(context).size.width * 0.4,
          color: Colors.white,
        ),
        subtitle: Container(
          height: 14,
          width: MediaQuery.of(context).size.width * 0.6,
          color: Colors.white,
        ),
        trailing: Container(
          height: 12,
          width: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}