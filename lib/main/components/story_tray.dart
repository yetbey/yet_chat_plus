import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/story_controller.dart';

import '../screens/story_screen.dart';

class StoryTray extends StatelessWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context) {
    final StoryController storyController = Get.find<StoryController>();
    final theme = Theme.of(context);

    return Obx(() {
      if (storyController.isStoriesLoading.value) {
        // Yüklenirken iskelet animasyonu da eklenebilir, şimdilik boş gösterelim
        return const SizedBox.shrink();
      }

      if (storyController.activeStories.isEmpty) {
        // Hiç hikaye yoksa, widget'ı tamamen gizle
        return const SizedBox.shrink();
      }
      return Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: storyController.activeStories.length,
          itemBuilder: (context, index) {
            final story = storyController.activeStories[index];
            return GestureDetector(
              onTap: () {
                Get.to(
                      () => StoryViewerScreen(
                    stories: storyController.activeStories.toList(), // Tüm hikaye listesini gönder
                    initialPage: index, // Hangi hikayeden başlayacağını belirt
                  ),
                  fullscreenDialog: true,
                  transition: Transition.fadeIn,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.red, Colors.purple],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        child: CircleAvatar(
                          radius: 27,
                          backgroundImage: story.userImageUrl != null
                              ? NetworkImage(story.userImageUrl!)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(story.userName, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}