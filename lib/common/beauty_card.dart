import 'package:flutter/material.dart';
import 'package:yet_chat_plus/constants/constants.dart';

class BeautyCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String email;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const BeautyCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.email,
    required this.isDarkMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.all(0),
        elevation: 0,
        color: isDarkMode ? Colors.black54 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ) : CircleAvatar(child: Icon(Icons.person),)
                  ),
                  Container(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 5),
                        Text(
                          name,
                          style: TextStyle(fontSize: 22,
                              color: isDarkMode ? kScaffoldBackgroundColor : Colors.black),
                        ),
                        Container(height: 5),
                        Text(
                          email,
                          style: TextStyle(fontSize: 14,
                              color: isDarkMode ? kScaffoldBackgroundColor : Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
