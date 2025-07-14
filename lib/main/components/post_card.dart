import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:yet_chat_plus/main/components/share_post_sheet.dart';
import 'package:yet_chat_plus/main/components/shimmer_post_card.dart';
import 'package:yet_chat_plus/main/screens/create_post_screen.dart';
import 'package:yet_chat_plus/main/screens/profile_screen.dart';
import 'package:yet_chat_plus/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel postModel;
  final PostController postController = Get.find<PostController>();
  final Function()? onTap;
  final bool isDetailView;

  PostCard({
    super.key,
    required this.postModel,
    this.onTap,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String formattedTime = timeago.format(
      postModel.createdAt,
      locale: 'tr',
    );
    final bool isOwner = postModel.userId == supabase.auth.currentUser?.id;
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final bool hasAvatar =
        postModel.userProfileImage != null &&
        postModel.userProfileImage!.isNotEmpty;
    final bool hasPostImage =
        postModel.imageUrl != null && postModel.imageUrl!.isNotEmpty;

    final user = postModel.userFullName;
    if (user == null) {
      return const ShimmerPostCard();
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 0.0),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isOwner) {
                        Get.to(() => ProfileScreen(userId: postModel.userId));
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage:
                          hasAvatar
                              ? CachedNetworkImageProvider(
                                postModel.userProfileImage!,
                              )
                              : null,
                      child: !hasAvatar ? const Icon(Icons.person) : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    postModel.userFullName ?? 'Kullanıcı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  isOwner
                      ? IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed:
                            () => _showOptionsMenu(context, postController),
                      )
                      : Text(postModel.username!),
                  SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 8),
              if (postModel.caption != null && postModel.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 10),
                  child: ReadMoreText(
                    postModel.caption!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    trimLines: 2,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' ...daha fazla',
                    trimExpandedText: ' daha az',
                    moreStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    lessStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),

              if (hasPostImage) ...[
                const SizedBox(height: 12),
                isDetailView
                    ? Padding(
                      padding: const EdgeInsets.only(
                        left: 2,
                        right: 12,
                        bottom: 14,
                      ),
                      child: _buildImageView(),
                    )
                    : AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          right: 8,
                          bottom: 14,
                        ),
                        child: _buildImageView(),
                      ),
                    ),
              ],
              const SizedBox(height: 8),

              Row(
                children: [
                  Obx(
                    () => _buildActionButton(
                      context: context,
                      icon:
                          postModel.isLikedByCurrentUser.value
                              ? Icons.favorite
                              : Iconsax.like_14,
                      color:
                          postModel.isLikedByCurrentUser.value
                              ? Colors.red
                              : Theme.of(context).iconTheme.color,
                      text: postModel.likes.value.toString(),
                      onTap: () => postController.toggleLike(postModel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    context: context,
                    icon: Iconsax.message1,
                    text: postModel.commentCount.toString(),
                    onTap: onTap,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    context: context,
                    icon: Iconsax.send1,
                    text: '',
                    onTap: () {
                      Get.bottomSheet(SharePostSheet(post: postModel));
                    },
                  ),
                  const Spacer(),
                  Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(width: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, PostController postController) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Gönderiyi Düzenle'),
              onTap: () {
                Get.back();
                Get.to(() => CreatePostScreen(postToEdit: postModel));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(
                'Gönderiyi Sil',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                Get.back();
                Get.defaultDialog(
                  title: "Emin misiniz?",
                  middleText:
                      "Bu gönderiyi kalıcı olarak silmek istediğinizden emin misiniz?",
                  textConfirm: "Evet, Sil",
                  textCancel: "İptal",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back();
                    postController.deletePost(postModel.id);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: postModel.imageUrl!,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        errorWidget:
            (context, url, error) => const Center(child: Icon(Icons.error)),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  color ??
                  Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            if (text.isNotEmpty) const SizedBox(width: 6),
            if (text.isNotEmpty)
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
