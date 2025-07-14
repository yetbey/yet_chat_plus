import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:yet_chat_plus/controller/ui_controller.dart';
import 'package:yet_chat_plus/main/components/empty_state_widget.dart';
import 'package:yet_chat_plus/main/components/post_card.dart';
import 'package:yet_chat_plus/main/components/shimmer_post_card.dart';
import 'package:yet_chat_plus/main/components/story_tray.dart';
import 'package:yet_chat_plus/main/screens/create_post_screen.dart';
import 'package:yet_chat_plus/main/screens/detailed_post_screen.dart';
import 'package:yet_chat_plus/models/post_model.dart';
import 'package:yet_chat_plus/routes/app_routes.dart';
import '../../controller/story_controller.dart';
import 'create_story_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final PostController postController = Get.find<PostController>();
  final UIController uiController = Get.find<UIController>();
  final StoryController storyController = Get.find<StoryController>();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        postController.fetchAllPosts(isRefresh: true);
        postController.fetchFollowingPosts(isRefresh: true);
        storyController.fetchStories();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    BuildContext context,
  ) {
    // 1. Bottom NavBar'ı gizleme/gösterme işlemi
    if (notification is UserScrollNotification) {
      final direction = notification.direction;

      // State güncellemesini mevcut frame bittikten sonraya zamanlıyoruz.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Callback çalıştığında widget'ın hala ağaçta olduğundan emin olalım.
        if (!mounted) return;

        if (direction == ScrollDirection.reverse &&
            uiController.isNavBarVisible.value) {
          uiController.hideNavBar();
        } else if (direction == ScrollDirection.forward &&
            !uiController.isNavBarVisible.value) {
          uiController.showNavBar();
        }
      });
    }

    // 2. Sayfa sonuna gelince yeni veri çekme (Pagination) işlemi
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 300) {
      // State güncellemesini mevcut frame bittikten sonraya zamanlıyoruz.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_tabController.index == 0) {
          // Zaten yükleme yapılıyorsa tekrar tetiklemeyi önle
          if (!postController.isFollowingPostsLoadingMore.value) {
            postController.fetchFollowingPosts();
          }
        } else {
          // Zaten yükleme yapılıyorsa tekrar tetiklemeyi önle
          if (!postController.isAllPostsLoadingMore.value) {
            postController.fetchAllPosts();
          }
        }
      });
    }

    return true;
  }

  Future<void> _pickAndCreateStory() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Get.to(() => CreateStoryScreen(imageFile: File(image.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (builderContext) {
          return NotificationListener<ScrollNotification>(
            onNotification:
                (notification) =>
                    _handleScrollNotification(notification, builderContext),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    title: const Text('Akış'),
                    centerTitle: true,
                    pinned: true,
                    floating: true,
                    snap: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => Get.toNamed(AppRoutes.search),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Hikaye Ekle',
                        onPressed: _pickAndCreateStory,
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: [Tab(text: 'Takip Edilenler'), Tab(text: 'Keşfet')],
                    ),
                  ),
                  const SliverToBoxAdapter(child: StoryTray()),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostList(
                    posts: postController.followingPosts,
                    onRefresh:
                        () =>
                            postController.fetchFollowingPosts(isRefresh: true),
                    emptyListMessage:
                        "Takip ettiğiniz kişilerin gönderileri burada görünecek.",
                  ),
                  _buildPostList(
                    posts: postController.allPosts,
                    onRefresh:
                        () => postController.fetchAllPosts(isRefresh: true),
                    emptyListMessage: "Henüz hiç gönderi yok.",
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        onPressed: () => Get.to(() => CreatePostScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- DEĞİŞİKLİK BURADA: Metodun tanımını sadeleştiriyoruz ---
  Widget _buildPostList({
    required RxList<PostModel> posts,
    required Future<void> Function() onRefresh,
    required String emptyListMessage,
  }) {
    return Obx(() {
      final isLoadingMore =
          (posts == postController.allPosts)
              ? postController.isAllPostsLoadingMore.value
              : postController.isFollowingPostsLoadingMore.value;
      final hasMore =
          (posts == postController.allPosts)
              ? postController.allPostsHasMore.value
              : postController.followingPostsHasMore.value;

      if (postController.isLoading.value && posts.isEmpty) {
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: 5,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => const ShimmerPostCard(),
        );
      }
      if (posts.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.explore_outlined,
          title: 'Gönderi Yok',
          subtitle: emptyListMessage,
        );
      }
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(0.0),
          itemCount: posts.length + (hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return isLoadingMore
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : const SizedBox.shrink();
            }
            final post = posts[index];
            return PostCard(
              postModel: post,
              onTap: () => Get.to(() => DetailedPostScreen(post: post)),
            );
          },
        ),
      );
    });
  }
}
