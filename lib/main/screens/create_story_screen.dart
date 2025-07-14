import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/story_controller.dart';

class CreateStoryScreen extends StatelessWidget {
  final File imageFile;
  const CreateStoryScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final StoryController storyController = Get.find<StoryController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Seçilen resmi tam ekran göster
          Center(
            child: Image.file(imageFile),
          ),
          // "Paylaş" butonu
          Positioned(
            bottom: 30,
            right: 30,
            child: Obx(() => storyController.isLoading.value
                ? const CircularProgressIndicator()
                : FloatingActionButton.extended(
              onPressed: () {
                storyController.createStory(imageFile);
              },
              label: const Text('Hikaye Olarak Paylaş'),
              icon: const Icon(Icons.send),
            )),
          ),
        ],
      ),
    );
  }
}