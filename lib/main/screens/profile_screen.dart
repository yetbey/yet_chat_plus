import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/controller/message_controller.dart';
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:yet_chat_plus/controller/profile_controller.dart';
import 'package:yet_chat_plus/main/components/post_card.dart';
import 'package:yet_chat_plus/main/components/shimmer_profile.dart';
import 'package:yet_chat_plus/main/screens/chat_screen.dart';
import 'package:yet_chat_plus/main/screens/edit_profile_screen.dart';
import 'package:yet_chat_plus/main/screens/follower_list_screen.dart';
import 'detailed_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final PostController postController = Get.find<PostController>();
  final MessageController messageController = Get.find<MessageController>();
  final supabase = Supabase.instance.client;

  // late final'ı kaldırıp, null olabilen bir String yapıyoruz.
  String? _profileUserId;
  bool _isLoading = true;
  Map<String, dynamic>? _profileUserData;

  @override
  void initState() {
    super.initState();

    // 1. ÖNCE ID'yi ata. currentUser null ise ?. operatörü sayesinde çökmeyecek.
    _profileUserId = widget.userId ?? supabase.auth.currentUser?.id;

    // 2. SONRA, ID'nin geçerli olduğundan emin olup veri çekmeyi başlat.
    // Ekrana ilk kare çizildikten sonra güvenli bir şekilde çağırıyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_profileUserId != null) {
        _fetchProfileData();
      } else {
        // Gösterilecek bir kullanıcı ID'si bulunamadıysa (örneğin kullanıcı giriş yapmamışsa)
        if (mounted) {
          setState(() => _isLoading = false);
          Get.snackbar("Hata", "Kullanıcı profili bulunamadı.");
        }
      }
    });
  }

  // Veri çekme fonksiyonu
  Future<void> _fetchProfileData() async {
    // _profileUserId null ise hiçbir şey yapma
    if (_profileUserId == null) return;

    // Sadece ilk yüklemede tam ekran animasyon göster
    if (mounted && _profileUserData == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Tüm veri çekme işlemlerini paralel olarak, tek seferde başlat
      final results = await Future.wait([
        supabase.from('Users').select().eq('UID', _profileUserId!).single(),
        profileController.getProfileData(_profileUserId!),
        postController.fetchPostsForUser(_profileUserId!),
      ]);

      // Gelen verileri state'e ata
      if (mounted) {
        setState(() {
          _profileUserData = results[0] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("Profil verisi çekme hatası: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Her ihtimale karşı postları temizleyelim ki başka profile gidince eskileri görünmesin
    postController.profilePosts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          _isLoading ? 'Profil' : (_profileUserData?['username'] ?? 'Profil'),
        ),
      ),
      body:
          _isLoading
              ? const ShimmerProfile()
              : RefreshIndicator(
                onRefresh: _fetchProfileData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildProfileHeader(),
                      ),
                    ),
                    Obx(() {
                      final userPosts = postController.profilePosts;
                      if (userPosts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Text(
                                'Bu kullanıcının henüz gönderisi yok.',
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: PostCard(
                              postModel: userPosts[index],
                              onTap:
                                  () => Get.to(
                                    () => DetailedPostScreen(
                                      post: userPosts[index],
                                    ),
                                  ),
                            ),
                          ),
                          childCount: userPosts.length,
                        ),
                      );
                    }),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    final bool isCurrentUserProfile =
        _profileUserId == supabase.auth.currentUser!.id;
    final String userIdToToggle = _profileUserId!;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      _profileUserData?['image_url'] != null
                          ? NetworkImage(_profileUserData!['image_url'])
                          : null,
                  child:
                      _profileUserData?['image_url'] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                ),
                Spacer(),
                Column(
                  children: [
                    Text(
                      _profileUserData?['fullName'] ?? 'Kullanıcı Adı',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Obx(
                          () => _buildStatColumn(
                            'Gönderi',
                            profileController.postCount.value.toString(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Obx(
                          () => _buildStatColumn(
                            'Takipçi',
                            profileController.followerCount.value.toString(),
                            onTap: () {
                              Get.to(
                                () => FollowerListScreen(
                                  userId: _profileUserId!,
                                  initialTabIndex: 0,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Obx(
                          () => _buildStatColumn(
                            'Takip',
                            profileController.followingCount.value.toString(),
                            onTap: () {
                              Get.to(
                                () => FollowerListScreen(
                                  userId: _profileUserId!,
                                  initialTabIndex: 1,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                // Expanded(
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //     children: [
                //       Obx(() => _buildStatColumn('Gönderi', profileController.postCount.value.toString())),
                //       Obx(() => _buildStatColumn('Takipçi', profileController.followerCount.value.toString(), onTap: () {
                //         Get.to(() => FollowerListScreen(userId: _profileUserId!, initialTabIndex: 0));
                //       })),
                //       Obx(() => _buildStatColumn('Takip', profileController.followingCount.value.toString(), onTap: () {
                //         Get.to(() => FollowerListScreen(userId: _profileUserId!, initialTabIndex: 1));
                //       })),
                //     ],
                //   ),
                // ),
              ],
            ),
            // const SizedBox(height: 12),
            // Text(
            //   _profileUserData?['fullName'] ?? 'Kullanıcı Adı',
            //   style: Theme.of(context).textTheme.titleLarge,
            // ),
            const SizedBox(height: 16),
            _buildActionButtons(isCurrentUserProfile, userIdToToggle),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isCurrentUserProfile, String userIdToToggle) {
    if (isCurrentUserProfile) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Get.to(() => const EditProfileScreen()),
          child: const Text('Profili Düzenle'),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Obx(
              () =>
                  profileController.isFollowing.value
                      ? OutlinedButton(
                        onPressed:
                            () =>
                                profileController.toggleFollow(userIdToToggle),
                        child: const Text('Takipten Çık'),
                      )
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            () =>
                                profileController.toggleFollow(userIdToToggle),
                        child: const Text('Takip Et'),
                      ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.message_outlined, size: 16),
              label: const Text('Mesaj'),
              onPressed: () async {
                final chatId = await messageController.createOrGetChat(
                  _profileUserId!,
                );
                Get.to(
                  () =>
                      ChatScreen(chatId: chatId, otherUser: _profileUserData!),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatColumn(String label, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
