import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/story_controller.dart';
import 'package:yet_chat_plus/models/story_item_model.dart';
import 'package:yet_chat_plus/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialPage;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialPage,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  bool _isDisposed = false;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addObserver(this);

    // System UI ayarları
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // İlk story'yi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed && widget.stories.isNotEmpty) {
        final currentStory = widget.stories[_currentStoryIndex];
        _loadStoryItems(currentStory.id);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _loadStoryItems(int storyId) async {
    final storyController = Get.find<StoryController>();
    debugPrint('Loading story items for story: $storyId');
    await storyController.fetchStoryItems(storyId);
    storyController.printCacheStatus(); // Debug için
  }

  void _nextUserStory() {
    if (_isDisposed || !_pageController.hasClients) return;

    if (_currentStoryIndex < widget.stories.length - 1) {
      _currentStoryIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void _previousUserStory() {
    if (_isDisposed || !_pageController.hasClients) return;

    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            _currentStoryIndex = index;
            final currentStory = widget.stories[index];
            _loadStoryItems(currentStory.id);
          },
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            return SingleUserStoryView(
              key: ValueKey('story_${story.id}'),
              story: story,
              onComplete: _nextUserStory,
              onPrevious: _previousUserStory,
              isActive: index == _currentStoryIndex,
            );
          },
        ),
      ),
    );
  }
}

class SingleUserStoryView extends StatefulWidget {
  final Story story;
  final VoidCallback onComplete;
  final VoidCallback onPrevious;
  final bool isActive;

  const SingleUserStoryView({
    super.key,
    required this.story,
    required this.onComplete,
    required this.onPrevious,
    required this.isActive,
  });

  @override
  State<SingleUserStoryView> createState() => _SingleUserStoryViewState();
}

class _SingleUserStoryViewState extends State<SingleUserStoryView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final StoryController _storyController = Get.find<StoryController>();
  late PageController _pageController;
  late AnimationController _animationController;

  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isPaused = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeStory();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  void _initializeStory() {
    if (!widget.isActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _checkAndLoadStoryItems();
      }
    });
  }

  @override
  void didUpdateWidget(SingleUserStoryView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Story değiştiğinde yeniden yükle
    if (oldWidget.story.id != widget.story.id ||
        (oldWidget.isActive != widget.isActive && widget.isActive)) {
      _checkAndLoadStoryItems();
    }
  }

  void _checkAndLoadStoryItems() {
    // Bu story için items var mı kontrol et
    final storyItems = _storyController.getStoryItems(widget.story.id);
    final isLoading = _storyController.isStoryItemsLoading(widget.story.id);

    debugPrint('Checking story ${widget.story.id}: ${storyItems.length} items, loading: $isLoading');

    if (storyItems.isNotEmpty && !isLoading) {
      // Items zaten yüklü, direkt başlat
      _isInitialized = true;
      _playStory(0);
    } else if (!isLoading) {
      // Items yüklü değil ve loading da değil, yükle
      _loadStoryItems();
    }
    // Eğer loading ise, Obx widget'ı otomatik update edecek
  }

  Future<void> _loadStoryItems() async {
    if (_isDisposed) return;

    try {
      await _storyController.fetchStoryItems(widget.story.id);

      if (mounted && !_isDisposed) {
        final storyItems = _storyController.getStoryItems(widget.story.id);
        if (storyItems.isNotEmpty) {
          _isInitialized = true;
          _playStory(0);
        }
      }
    } catch (e) {
      debugPrint('Story items yükleme hatası: $e');
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (_isDisposed) return;

    if (status == AnimationStatus.completed && !_isPaused) {
      _nextStoryItem();
    }
  }

  void _playStory(int index) {
    if (_isDisposed || !_isInitialized) return;

    _animationController.stop();
    _animationController.reset();

    final storyItems = _storyController.getStoryItems(widget.story.id);
    if (index >= storyItems.length) return;

    final item = storyItems[index];

    Duration duration;
    if (item.type == 'video') {
      duration = const Duration(seconds: 10);
    } else {
      duration = const Duration(seconds: 5);
    }

    _animationController.duration = duration;
    _animationController.forward();

    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _nextStoryItem() {
    if (_isDisposed) return;

    final storyItems = _storyController.getStoryItems(widget.story.id);
    if (_currentIndex < storyItems.length - 1) {
      final nextIndex = _currentIndex + 1;
      _navigateToStoryItem(nextIndex);
    } else {
      widget.onComplete();
    }
  }

  void _previousStoryItem() {
    if (_isDisposed) return;

    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      _navigateToStoryItem(prevIndex);
    } else {
      // İlk story item'daysa önceki user'a geç
      widget.onPrevious();
    }
  }

  void _navigateToStoryItem(int index) {
    if (_isDisposed || !_pageController.hasClients) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    _playStory(index);
  }

  void _pauseStory() {
    if (_isDisposed || _isPaused) return;

    _isPaused = true;
    _animationController.stop();
  }

  void _resumeStory() {
    if (_isDisposed || !_isPaused) return;

    _isPaused = false;
    _animationController.forward();
  }

  void _handleTap(TapDownDetails details) {
    if (_isDisposed) return;

    final width = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < width / 3) {
      _previousStoryItem();
    } else if (tapX > 2 * width / 3) {
      _nextStoryItem();
    } else {
      if (_isPaused) {
        _resumeStory();
      } else {
        _pauseStory();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.removeStatusListener(_onAnimationStatusChanged);
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final storyItems = _storyController.getStoryItems(widget.story.id);
      final isLoading = _storyController.isStoryItemsLoading(widget.story.id);

      debugPrint('Building story ${widget.story.id}: ${storyItems.length} items, loading: $isLoading');

      if (isLoading && storyItems.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      }

      if (storyItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hikaye bulunamadı",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadStoryItems(),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTapDown: _handleTap,
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: storyItems.length,
              itemBuilder: (context, index) => _buildStoryContent(storyItems[index]),
            ),
            _buildUIOverlay(storyItems),
          ],
        ),
      );
    });
  }

  Widget _buildStoryContent(StoryItem item) {
    return Center(
      child: Hero(
        tag: 'story_${item.id}',
        child: CachedNetworkImage(
          imageUrl: item.mediaUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          memCacheWidth: MediaQuery.of(context).size.width.toInt(),
          memCacheHeight: MediaQuery.of(context).size.height.toInt(),
        ),
      ),
    );
  }

  Widget _buildUIOverlay(List<StoryItem> storyItems) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Column(
        children: [
          Row(
            children: storyItems.asMap().entries.map((entry) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedProgressBar(
                    animationController: _animationController,
                    position: entry.key,
                    currentIndex: _currentIndex,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Hero(
                tag: 'avatar_${widget.story.userId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: widget.story.userImageUrl != null
                      ? CachedNetworkImageProvider(widget.story.userImageUrl!)
                      : null,
                  child: widget.story.userImageUrl == null
                      ? Text(
                    widget.story.userName.isNotEmpty
                        ? widget.story.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.story.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Get.back(),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Progress bar widget'ı aynı kalabilir
class AnimatedProgressBar extends StatelessWidget {
  final AnimationController animationController;
  final int position;
  final int currentIndex;

  const AnimatedProgressBar({
    super.key,
    required this.animationController,
    required this.position,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: 3.0,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            if (position < currentIndex)
              Container(
                width: double.infinity,
                height: 3.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            if (position == currentIndex)
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return Container(
                    width: constraints.maxWidth * animationController.value,
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}