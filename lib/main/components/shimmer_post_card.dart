import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı profili iskeleti
            Row(
              children: [
                const CircleAvatar(radius: 20),
                const SizedBox(width: 8),
                Container(width: 120, height: 16, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            // Gönderi metni iskeleti
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: MediaQuery.of(context).size.width * 0.7, height: 14, color: Colors.white),
            const SizedBox(height: 12),
            // Gönderi resmi iskeleti
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}