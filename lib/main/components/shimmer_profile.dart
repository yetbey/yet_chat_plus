import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil başlığı iskeleti
              Row(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPlaceholder(),
                        _buildStatPlaceholder(),
                        _buildStatPlaceholder(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // İsim ve buton iskeleti
              Container(width: 150, height: 20, color: Colors.white),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 24),
              // Gönderi listesi iskeleti
              Container(width: double.infinity, height: 1, color: Colors.grey),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPlaceholder() {
    return Column(
      children: [
        Container(width: 30, height: 18, color: Colors.white),
        const SizedBox(height: 4),
        Container(width: 50, height: 14, color: Colors.white),
      ],
    );
  }
}