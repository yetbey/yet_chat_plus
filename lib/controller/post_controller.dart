import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:yet_chat_plus/constants/error_constants.dart';

class PostController extends GetxController {
  var logger = Logger(
    // filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
    printer: PrettyPrinter(),
  );
  final supabase = Supabase.instance.client;
  final _box = GetStorage();
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  int _allPostsCurrentPage = 1;
  final RxBool allPostsHasMore = true.obs;
  final RxBool isAllPostsLoadingMore = false.obs;

  final RxList<PostModel> followingPosts = <PostModel>[].obs;
  int _followingPostsCurrentPage = 1;
  final RxBool followingPostsHasMore = true.obs;
  final RxBool isFollowingPostsLoadingMore = false.obs;

  final RxList<PostModel> profilePosts = <PostModel>[].obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final int postsPerPage = 10;

  @override
  void onInit() {
    super.onInit();
    loadPostsFromCache();
  }

  Future<void> loadPostsFromCache() async {
    if (_box.hasData('all_posts_cache')) {
      final cachedData = _box.read<List<dynamic>>('all_posts_cache') ?? [];
      if (cachedData.isNotEmpty) {
        final likedPostIds = await _getLikedPostIds();
        allPosts.value = _mapResponseToPosts(cachedData, likedPostIds);
      }
    }
    if (_box.hasData('following_posts_cache')) {
      final cachedData =
          _box.read<List<dynamic>>('following_posts_cache') ?? [];
      if (cachedData.isNotEmpty) {
        final likedPostIds = await _getLikedPostIds();
        followingPosts.value = _mapResponseToPosts(cachedData, likedPostIds);
      }
    }
  }

  Future<Set<int>> _getLikedPostIds() async {
    if (supabase.auth.currentUser == null) return {};
    final response = await supabase
        .from('post_likes')
        .select('post_id')
        .eq('user_id', supabase.auth.currentUser!.id);
    return (response as List).map((like) => like['post_id'] as int).toSet();
  }

  Future<PostModel?> getPostById(int postId) async {
    try {
      // First check if this post exists in existing lists (for performance)
      var post =
          allPosts.firstWhereOrNull((p) => p.id == postId) ??
          followingPosts.firstWhereOrNull((p) => p.id == postId);
      if (post != null) return post;

      // If not in the lists, pull from the database
      final response =
          await supabase
              .from('Posts')
              .select(
                '*, comment_count, Users!user_id(UID, fullName, image_url, username)',
              )
              .eq('id', postId)
              .single();

      if (response.isEmpty) return null;

      final likedPostIds = await _getLikedPostIds();
      return _mapResponseToPosts([response], likedPostIds).first;
    } catch (e) {
      logger.e(ErrorConstants.uniqueError, error: e);
      return null;
    }
  }

  List<PostModel> _mapResponseToPosts(
    List<dynamic> response,
    Set<int> likedPostIds,
  ) {
    return response.map((item) {
      final Map<String, dynamic> typedItem = Map<String, dynamic>.from(item);
      final postData = {
        ...typedItem,
        'user_fullName': typedItem['Users']?['fullName'],
        'user_profile_image': typedItem['Users']?['image_url'],
        'username': typedItem['Users']?['username'],
      };
      return PostModel.fromJson(
        postData,
        isLiked: likedPostIds.contains(typedItem['id']),
      );
    }).toList();
  }

  Future<void> fetchPostsForUser(String userId) async {
    if (supabase.auth.currentUser == null) return;
    profilePosts.clear();
    try {
      final response = await supabase
          .from('Posts')
          .select(
            '*, comment_count, Users!user_id(UID, fullName, image_url, username)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final likedPostIds = await _getLikedPostIds();
      profilePosts.assignAll(_mapResponseToPosts(response, likedPostIds));
    } catch (e) {
      logger.e(ErrorConstants.fetchUserError, error: e);
    }
  }

  Future<void> fetchAllPosts({bool isRefresh = false}) async {
    if (supabase.auth.currentUser == null) return;
    if (isRefresh) {
      _allPostsCurrentPage = 1;
      allPostsHasMore.value = true;
      allPosts.clear();
    }
    if (!allPostsHasMore.value || isAllPostsLoadingMore.value) return;

    try {
      if (_allPostsCurrentPage == 1) isLoading.value = true;
      isAllPostsLoadingMore.value = true;

      final response = await supabase
          .from('Posts')
          .select(
            '*, comment_count, Users!user_id(UID, fullName, image_url, username)',
          )
          .order('created_at', ascending: false)
          .range(
            (_allPostsCurrentPage - 1) * postsPerPage,
            _allPostsCurrentPage * postsPerPage - 1,
          );

      final likedPostIds = await _getLikedPostIds();
      final List<PostModel> fetchedPosts = _mapResponseToPosts(
        response,
        likedPostIds,
      );

      if (fetchedPosts.length < postsPerPage) allPostsHasMore.value = false;
      allPosts.addAll(fetchedPosts);
      _allPostsCurrentPage++;

      if (_allPostsCurrentPage == 1) {
        await _box.write(
          'all_posts_cache',
          fetchedPosts.map((p) => p.toJson()).toList(),
        );
      }
    } catch (e) {
      logger.e(ErrorConstants.fetchAllPostsError, error: e);
    } finally {
      isLoading.value = false;
      isAllPostsLoadingMore.value = false;
    }
  }

  Future<void> fetchFollowingPosts({bool isRefresh = false}) async {
    if (supabase.auth.currentUser == null) return;
    if (isRefresh) {
      _followingPostsCurrentPage = 1;
      followingPostsHasMore.value = true;
      followingPosts.clear();
    }
    if (!followingPostsHasMore.value || isFollowingPostsLoadingMore.value) return;

    try {
      if (_followingPostsCurrentPage == 1) isLoading.value = true;
      isFollowingPostsLoadingMore.value = true;

      final followingResponse = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', supabase.auth.currentUser!.id);
      final List<String> followingIds =
          (followingResponse as List)
              .map((row) => row['following_id'] as String)
              .toList();

      if (followingIds.isEmpty) {
        followingPosts.clear();
        followingPostsHasMore.value = false;
        return;
      }

      final response = await supabase
          .from('Posts')
          .select(
            '*, comment_count, Users!user_id(UID, fullName, image_url, username)',
          )
          .filter('user_id', 'in', followingIds)
          .order('created_at', ascending: false)
          .range(
            (_followingPostsCurrentPage - 1) * postsPerPage,
            _followingPostsCurrentPage * postsPerPage - 1,
          );

      final likedPostIds = await _getLikedPostIds();
      final List<PostModel> fetchedPosts = _mapResponseToPosts(
        response,
        likedPostIds,
      );

      if (fetchedPosts.length < postsPerPage) followingPostsHasMore.value = false;
      followingPosts.addAll(fetchedPosts);
      _followingPostsCurrentPage++;

      if (_followingPostsCurrentPage == 1) {
        await _box.write(
          'following_posts_cache',
          fetchedPosts.map((p) => p.toJson()).toList(),
        );
      }
    } catch (e) {
      logger.e(ErrorConstants.fetchAllPostsError, error: e);
    } finally {
      isLoading.value = false;
      isFollowingPostsLoadingMore.value = false;
    }
  }

  Future<List<CommentModel>> getComments(int postId) async {
    try {
      final response = await supabase
          .from('post_comments')
          .select('*, Users!user_id(fullName, image_url, username)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((comment) => CommentModel.fromJson(comment))
          .toList();
    } catch (e) {
      logger.e(ErrorConstants.getCommentError, error: e);
      return [];
    }
  }

  Future<void> updatePost({
    required int postId,
    required String oldImageUrl,
    required String caption,
    File? newImageFile,
  }) async {
    isLoading.value = true;
    try {
      String? finalImageUrl = oldImageUrl;

      // If a new image is selected, upload it
      if (newImageFile != null) {
        final fileExtension = path.extension(newImageFile.path);
        final fileName = '${Uuid().v4()}$fileExtension';

        await supabase.storage
            .from('post-images')
            .upload(fileName, newImageFile);
        finalImageUrl = supabase.storage
            .from('post-images')
            .getPublicUrl(fileName);

        // Delete old image from Storage (if available)
        if (oldImageUrl.isNotEmpty) {
          final oldFileName = Uri.parse(oldImageUrl).pathSegments.last;
          await supabase.storage.from('post-images').remove([oldFileName]);
        }
      }

      // Update the record in the Posts table
      final response =
          await supabase
              .from('Posts')
              .update({'caption': caption, 'image_url': finalImageUrl})
              .eq('id', postId)
              .select(
                '*, comment_count, Users!user_id(UID, fullName, image_ur, username)',
              )
              .single();

      // Update post in local lists with new data
      final likedPostIds = await _getLikedPostIds();
      final updatedPost = _mapResponseToPosts([response], likedPostIds).first;

      // update allPosts list
      int allPostsIndex = allPosts.indexWhere((p) => p.id == postId);
      if (allPostsIndex != -1) {
        allPosts[allPostsIndex] = updatedPost;
      }
      // update followingPosts list
      int followingPostsIndex = followingPosts.indexWhere(
        (p) => p.id == postId,
      );
      if (followingPostsIndex != -1) {
        followingPosts[followingPostsIndex] = updatedPost;
      }

      Get.back();
      Get.snackbar(ErrorConstants.success, ErrorConstants.updatePostSuccess);
    } catch (e) {
      Get.snackbar(ErrorConstants.error, ErrorConstants.updatePostUnsuccessMessage);
      logger.e(ErrorConstants.updatePostUnsuccess, error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment(int postId, String content) async {
    if (content.trim().isEmpty) return;
    try {
      await supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': supabase.auth.currentUser!.id,
        'content': content.trim(),
      });
      // Trigger will increase the number automatically
      // We can manually increase the number of related posts to update the UI on the fly
      final postIndex = allPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        allPosts[postIndex].commentCount++;
        allPosts.refresh();
      }
    } catch (e) {
      logger.e(ErrorConstants.addCommentError, error: e);
      Get.snackbar(ErrorConstants.error, ErrorConstants.addCommentUnsuccess);
    }
  }

  Future<void> toggleLike(PostModel post) async {
    final currentUserId = supabase.auth.currentUser!.id;

    if (post.isLikedByCurrentUser.value) {
      post.likes.value--;
      post.isLikedByCurrentUser.value = false;

      await supabase.from('post_likes').delete().match({
        'post_id': post.id,
        'user_id': currentUserId,
      });
    } else {
      HapticFeedback.lightImpact();
      post.likes.value++;
      post.isLikedByCurrentUser.value = true;

      await supabase.from('post_likes').insert({
        'post_id': post.id,
        'user_id': currentUserId,
      });
    }

    await supabase
        .from('Posts')
        .update({'likes': post.likes.value})
        .eq('id', post.id);
  }

  Future<void> createPost(String? caption, File? imageFile) async {
    if ((caption?.isEmpty ?? true) && imageFile == null) {
      Get.snackbar(ErrorConstants.error, ErrorConstants.addCaptionImage);
      return;
    }

    try {
      isLoading.value = true;
      String? imageUrl;

      // İmage is exist, load
      if (imageFile != null) {
        final fileExtension = path.extension(imageFile.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}${Uuid().v4()}$fileExtension';
        final mimeType = lookupMimeType(imageFile.path);

        // Upload Image to Storage
        await supabase.storage
            .from('post-images')
            .uploadBinary(
              fileName,
              await imageFile.readAsBytes(),
              fileOptions: FileOptions(contentType: mimeType),
            );

        // Get Image Url
        imageUrl = supabase.storage.from('post-images').getPublicUrl(fileName);
      }

      // Insert Post to Supabase
      await supabase.from('Posts').insert({
        'user_id': supabase.auth.currentUser!.id,
        'caption': caption,
        'image_url': imageUrl,
      });

      Get.back();

      // Show success Message
      Get.snackbar(
        ErrorConstants.success,
        ErrorConstants.successShare,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Re-Post
      await fetchAllPosts();
    } catch (e) {
      logger.e(ErrorConstants.createPostUnsuccess, error: e);
      Get.snackbar(
        ErrorConstants.error,
        ErrorConstants.createPostUnsuccessMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }


  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<void> deletePost(int postId) async {
    try {
      // Delete post from Supabase
      await supabase.from('Posts').delete().eq('id', postId);

      // After successful deletion, remove the post from all lists on the screen
      allPosts.removeWhere((post) => post.id == postId);
      followingPosts.removeWhere((post) => post.id == postId);
      profilePosts.removeWhere((post) => post.id == postId);

      Get.snackbar(ErrorConstants.success, ErrorConstants.deleteSuccess);
    } catch (e) {
      Get.snackbar(ErrorConstants.error, ErrorConstants.deleteUnsuccessMessage);
      logger.e(ErrorConstants.deleteUnsuccess, error: e);
    }
  }

  Future<PostModel?> fetchPostById(int postId) async {
    isLoading.value = true;
    try {
      final response =
          await supabase
              .from('posts')
              .select(
                '*, user:Users!posts_user_id_fkey(*)',
              ) // Pull user data too
              .eq('id', postId)
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      logger.e(ErrorConstants.loadPostUnsuccess, error: e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
