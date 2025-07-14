import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerNotificationTile extends StatelessWidget {
  const ShimmerNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceVariant;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        leading: const CircleAvatar(radius: 25, backgroundColor: Colors.white),
        title: Container(
          height: 14,
          width: MediaQuery.of(context).size.width * 0.6,
          color: Colors.white,
        ),
        subtitle: Container(
          height: 12,
          width: MediaQuery.of(context).size.width * 0.3,
          color: Colors.white,
        ),
        trailing: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}