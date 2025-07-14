
import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'base_controller.dart';

import '../models/story_item_model.dart';
import '../models/story_model.dart';

class StoryController extends BaseController {
  final RxList<Story> activeStories = <Story>[].obs;
  final isStoriesLoading = false.obs;

  // HER STORY İÇİN AYRI STATE YÖNETİMİ
  final RxMap<int, List<StoryItem>> storyItemsMap = <int, List<StoryItem>>{}.obs;
  final RxMap<int, bool> storyItemsLoadingMap = <int, bool>{}.obs;

  // Cache için - story ID'sine göre organize edilmiş
  final Map<int, List<StoryItem>> _storyItemsCache = {};
  final Map<String, String> _uploadedFilesCache = {};

  // Aktif story tracking
  final RxInt currentActiveStoryId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('StoryController initialized');
  }

  Future<void> fetchStories() async {
    if (isStoriesLoading.value) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      setError('Kullanıcı oturum açmamış');
      return;
    }

    startPerformanceTracking('fetchStories');
    isStoriesLoading.value = true;

    final result = await safeAsyncOperation(
          () async {
        final twentyFourHoursAgo = DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String();

        final response = await supabase
            .from('stories')
            .select('''
              id,
              user_id,
              created_at,
              user:user_id(
                fullName,
                image_url,
                username
              )
            ''')
            .gte('created_at', twentyFourHoursAgo)
            .order('created_at', ascending: false)
            .limit(50);

        final stories = await compute(_parseStories, response as List);
        return stories;
      },
      errorMessage: 'Hikayeler yüklenirken sorun oluştu',
    );

    if (result != null) {
      activeStories.value = result;
      // Story listesi değiştiğinde cache'i temizle
      _clearStoryItemsCache();
    }

    endPerformanceTracking('fetchStories');
    isStoriesLoading.value = false;
  }

  static List<Story> _parseStories(List<dynamic> response) {
    return response.map((item) => Story.fromJson(item)).toList();
  }

  // SPECIFIC STORY İÇİN STORY ITEMS GETİR
  Future<void> fetchStoryItems(int storyId) async {
    // Bu story için loading durumunu kontrol et
    if (storyItemsLoadingMap[storyId] == true) return;

    // Cache kontrolü
    if (_storyItemsCache.containsKey(storyId)) {
      storyItemsMap[storyId] = _storyItemsCache[storyId]!;
      currentActiveStoryId.value = storyId;
      debugPrint('Story items loaded from cache for story: $storyId');
      return;
    }

    startPerformanceTracking('fetchStoryItems_$storyId');
    storyItemsLoadingMap[storyId] = true;

    // Bu story'nin mevcut items'ını temizle
    storyItemsMap[storyId] = [];

    final result = await safeAsyncOperation(
          () async {
        debugPrint('Fetching story items for story ID: $storyId');

        final response = await supabase
            .from('story_items')
            .select('*')
            .eq('story_id', storyId)
            .order('created_at', ascending: true)
            .limit(20);

        debugPrint('Story items response for $storyId: ${response.length} items');

        final storyItems = await compute(_parseStoryItems, response as List);
        return storyItems;
      },
      errorMessage: 'Hikaye öğeleri yüklenirken sorun oluştu',
    );

    if (result != null) {
      // Cache'e kaydet
      _storyItemsCache[storyId] = result;
      // Map'e kaydet
      storyItemsMap[storyId] = result;
      // Aktif story'yi güncelle
      currentActiveStoryId.value = storyId;

      debugPrint('Story items loaded for story $storyId: ${result.length} items');
    } else {
      // Hata durumunda boş liste ata
      storyItemsMap[storyId] = [];
      debugPrint('Failed to load story items for story: $storyId');
    }

    storyItemsLoadingMap[storyId] = false;
    endPerformanceTracking('fetchStoryItems_$storyId');
  }

  static List<StoryItem> _parseStoryItems(List<dynamic> response) {
    return response.map((item) => StoryItem.fromJson(item)).toList();
  }

  // SPECIFIC STORY'NİN ITEMS'LARINI GETİR
  List<StoryItem> getStoryItems(int storyId) {
    return storyItemsMap[storyId] ?? [];
  }

  // SPECIFIC STORY'NİN YÜKLENMİŞ OLUP OLMADIĞINI KONTROL ET
  bool isStoryItemsLoading(int storyId) {
    return storyItemsLoadingMap[storyId] ?? false;
  }

  // STORY DEĞIŞTIĞINDE ÇAĞIRILABİLİR
  void setActiveStory(int storyId) {
    currentActiveStoryId.value = storyId;
    debugPrint('Active story set to: $storyId');
  }

  Future<void> createStory(File mediaFile) async {
    if (isLoading.value) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      setError('Oturum açmanız gerekiyor');
      return;
    }

    // Dosya validasyonları
    final fileSize = await mediaFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      setError('Dosya boyutu 10MB\'dan küçük olmalıdır');
      return;
    }

    final fileExtension = path.extension(mediaFile.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.mp4', '.mov'].contains(fileExtension)) {
      setError('Desteklenmeyen dosya formatı');
      return;
    }

    startPerformanceTracking('createStory');

    final success = await safeAsyncOperation(
          () async {
        final twentyFourHoursAgo = DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String();

        final existingStories = await supabase
            .from('stories')
            .select('id')
            .eq('user_id', currentUser.id)
            .gte('created_at', twentyFourHoursAgo)
            .limit(1);

        int storyId;
        if (existingStories.isNotEmpty) {
          storyId = existingStories.first['id'];
        } else {
          final newStory = await supabase
              .from('stories')
              .insert({
            'user_id': currentUser.id,
            'created_at': DateTime.now().toIso8601String(),
          })
              .select('id')
              .single();
          storyId = newStory['id'];
        }

        final fileName = '${const Uuid().v4()}$fileExtension';
        final filePath = '${currentUser.id}/$fileName';

        final fileHash = mediaFile.path.hashCode.toString();
        String mediaUrl;

        if (_uploadedFilesCache.containsKey(fileHash)) {
          mediaUrl = _uploadedFilesCache[fileHash]!;
        } else {
          await supabase.storage
              .from('stories')
              .upload(filePath, mediaFile);

          mediaUrl = supabase.storage
              .from('stories')
              .getPublicUrl(filePath);

          _uploadedFilesCache[fileHash] = mediaUrl;
        }

        await _createStoryItem(storyId, mediaUrl, fileExtension);
        return true;
      },
      showLoading: true,
    );

    if (success == true) {
      // Tüm cache'i temizle çünkü yeni story eklendi
      cleanupCache();

      Get.back();
      Get.snackbar(
        'Başarılı',
        'Hikayen başarıyla paylaşıldı!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    }

    endPerformanceTracking('createStory');
  }

  Future<void> _createStoryItem(int storyId, String mediaUrl, String fileExtension) async {
    final type = ['.mp4', '.mov'].contains(fileExtension) ? 'video' : 'image';

    await supabase.from('story_items').insert({
      'story_id': storyId,
      'type': type,
      'media_url': mediaUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void _clearStoryItemsCache() {
    _storyItemsCache.clear();
    storyItemsMap.clear();
    storyItemsLoadingMap.clear();
    currentActiveStoryId.value = 0;
    debugPrint('Story items cache cleared');
  }

  @override
  void cleanupCache() {
    _clearStoryItemsCache();
    _uploadedFilesCache.clear();
    debugPrint('StoryController cache temizlendi');
  }

  @override
  Future<void> retryLastOperation() async {
    clearError();
    if (activeStories.isEmpty) {
      await fetchStories();
    }
  }

  // Debug için
  void printCacheStatus() {
    debugPrint('=== STORY CACHE STATUS ===');
    debugPrint('Active Stories: ${activeStories.length}');
    debugPrint('Cached Story Items: ${_storyItemsCache.keys.toList()}');
    debugPrint('Story Items Map: ${storyItemsMap.keys.toList()}');
    debugPrint('Current Active Story: ${currentActiveStoryId.value}');
    debugPrint('========================');
  }
}