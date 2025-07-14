import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/profile_controller.dart';
import 'package:yet_chat_plus/main/screens/profile_screen.dart';

class FollowerListScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex; // 0: Takipçiler, 1: Takip Edilenler

  const FollowerListScreen({
    super.key,
    required this.userId,
    required this.initialTabIndex,
  });

  @override
  State<FollowerListScreen> createState() => _FollowerListScreenState();
}

class _FollowerListScreenState extends State<FollowerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcılar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(profileController.getFollowerList(widget.userId)),
          _buildUserList(profileController.getFollowingList(widget.userId)),
        ],
      ),
    );
  }

  Widget _buildUserList(Future<List<Map<String, dynamic>>> future) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Henüz kullanıcı yok.'));
        }

        final users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['image_url'] != null
                    ? NetworkImage(user['image_url'])
                    : null,
                child: user['image_url'] == null ? Icon(Icons.person) : null,
              ),
              title: Text(user['fullName'] ?? 'Kullanıcı'),
              onTap: () {
                // Tıklanan kullanıcının profiline git
                Get.to(() => ProfileScreen(userId: user['UID']));
              },
            );
          },
        );
      },
    );
  }
}