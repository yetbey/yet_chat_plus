import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/message_controller.dart';
import 'package:yet_chat_plus/controller/profile_controller.dart';
import 'package:yet_chat_plus/models/post_model.dart';

class SharePostSheet extends StatelessWidget {
  final PostModel post;
  const SharePostSheet({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find();
    final MessageController messageController = Get.find();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Takip Edilenler'), Tab(text: 'Takipçiler')]),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList(context, profileController.getFollowingList(profileController.supabase.auth.currentUser!.id)),
                  _buildUserList(context, profileController.getFollowerList(profileController.supabase.auth.currentUser!.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, Future<List<Map<String, dynamic>>> future) {
    final MessageController messageController = Get.find();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(user['image_url'] ?? '')),
              title: Text(user['fullName'] ?? ''),
              trailing: ElevatedButton(
                child: Text('Gönder'),
                onPressed: () async {
                  Get.back(); // Önce BottomSheet'i kapat
                  final chatId = await messageController.createOrGetChat(user['UID']);

                  // --- DEĞİŞİKLİK BURADA ---
                  // Controller'a artık 'sharedPost' olarak gönderinin kendisini veriyoruz
                  await messageController.sendMessage(
                    chatId: chatId,
                    otherUserId: user['UID'],
                    sharedPost: post,
                  );
                  Get.snackbar('Başarılı', '${user['fullName']} kişisine gönderildi.');
                },
              ),
            );
          },
        );
      },
    );
  }
}