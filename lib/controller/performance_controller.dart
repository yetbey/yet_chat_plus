
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

class PerformanceController extends GetxController {
  static PerformanceController get to => Get.find<PerformanceController>();

  // Controller'ın aktif olup olmadığını takip et
  bool _isActive = false;

  // Memory usage tracking
  final RxDouble memoryUsage = 0.0.obs;
  final RxInt activeTasks = 0.obs;
  final RxBool isLowMemoryWarning = false.obs;

  // Frame performance tracking
  final RxDouble averageFrameTime = 0.0.obs;
  final RxInt droppedFrames = 0.obs;
  final RxBool isPerformanceGood = true.obs;

  // Network monitoring
  final RxBool isOffline = false.obs;
  final RxString connectionType = 'unknown'.obs;

  Timer? _memoryTimer;
  Timer? _networkTimer;
  Timer? _frameTimer;

  // Performance metrics
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};

  // Cache cleanup listeners
  final List<VoidCallback> _cleanupCallbacks = [];

  // Frame timing için
  final List<Duration> _frameTimes = [];
  // int _frameCount = 0;

  @override
  void onInit() {
    super.onInit();
    _isActive = true;
    _startMonitoring();
    _setupFrameTracking();
  }

  @override
  void onClose() {
    _isActive = false;
    _memoryTimer?.cancel();
    _networkTimer?.cancel();
    _frameTimer?.cancel();
    _cleanupCallbacks.clear();
    SchedulerBinding.instance.removeTimingsCallback(_onReportTimings);
    super.onClose();
  }

  void _startMonitoring() {
    // Memory monitoring - daha az sıklıkta
    _memoryTimer = Timer.periodic(
      const Duration(minutes: 1), // 30 saniye yerine 1 dakika
          (_) => _checkMemoryUsageAsync(),
    );

    // Network monitoring - daha az sıklıkta
    _networkTimer = Timer.periodic(
      const Duration(seconds: 30), // 10 saniye yerine 30 saniye
          (_) => _checkNetworkStatusAsync(),
    );

    // Frame performance monitoring
    _frameTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _analyzeFramePerformance(),
    );

    // İlk kontroller - async olarak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMemoryUsageAsync();
      _checkNetworkStatusAsync();
    });
  }

  void _setupFrameTracking() {
    // Flutter'ın frame timing callback'ini kullan
    SchedulerBinding.instance.addTimingsCallback(_onReportTimings);
  }

  void _onReportTimings(List<FrameTiming> timings) {
    if (!_isActive) return;

    // Ana thread'i bloke etmemek için batch processing
    if (_frameTimes.length > 100) {
      _frameTimes.removeRange(0, 50); // Eski frame'leri temizle
    }

    for (final timing in timings) {
      final duration = timing.totalSpan;
      _frameTimes.add(duration);

      // 16.67ms'den (60 FPS) fazla ise dropped frame
      if (duration.inMicroseconds > 16670) {
        droppedFrames.value++;
      }
    }
  }

  void _analyzeFramePerformance() {
    if (!_isActive || _frameTimes.isEmpty) return;

    // Average hesapla
    final totalMicroseconds = _frameTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);

    averageFrameTime.value = totalMicroseconds / _frameTimes.length / 1000; // ms cinsinden

    // Performance durumunu güncelle
    isPerformanceGood.value = averageFrameTime.value < 20.0; // 20ms altı iyi

    // Kötü performans durumunda optimizasyon tetikle
    if (!isPerformanceGood.value) {
      _handlePoorPerformance();
    }

    // Frame times listesini temizle
    _frameTimes.clear();
  }

  // Async memory check - ana thread'i bloke etmesin
  Future<void> _checkMemoryUsageAsync() async {
    if (!_isActive) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Isolate'te çalıştır
        final usage = await compute(_getMemoryUsage, null);
        if (_isActive) {
          memoryUsage.value = usage;

          if (usage > 0.85) {
            isLowMemoryWarning.value = true;
            _handleLowMemory();
          } else {
            isLowMemoryWarning.value = false;
          }
        }
      } else {
        // Desktop/Web için simüle edilmiş değer
        if (_isActive) {
          memoryUsage.value = 0.3;
        }
      }
    } catch (e) {
      debugPrint('Memory usage check failed: $e');
      if (_isActive) {
        memoryUsage.value = 0.3;
      }
    }
  }

  // Static method for isolate
  static Future<double> _getMemoryUsage(dynamic _) async {
    try {
      if (Platform.isAndroid) {
        // Android specific memory check
        final MethodChannel channel = const MethodChannel('performance/memory');
        return await channel.invokeMethod('getMemoryUsage') ?? 0.3;
      } else if (Platform.isIOS) {
        // iOS specific memory check
        final MethodChannel channel = const MethodChannel('performance/memory');
        return await channel.invokeMethod('getMemoryUsage') ?? 0.3;
      }
      return 0.3;
    } catch (e) {
      return 0.3;
    }
  }

  // Async network check
  Future<void> _checkNetworkStatusAsync() async {
    if (!_isActive) return;

    try {
      final isConnected = await compute(_checkNetworkConnection, null);
      if (_isActive) {
        isOffline.value = !isConnected;
      }
    } catch (e) {
      debugPrint('Network check failed: $e');
      if (_isActive) {
        isOffline.value = true;
      }
    }
  }

  // Static method for isolate
  static Future<bool> _checkNetworkConnection(dynamic _) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _handlePoorPerformance() {
    if (!_isActive) return;

    debugPrint('Poor performance detected - triggering optimization');

    // Agresif cache temizleme
    _handleLowMemory();

    // Performance log
    debugPrint('Performance warning: Average frame time: ${averageFrameTime.value}ms');
  }

  void _handleLowMemory() {
    if (!_isActive) return;

    debugPrint('Low memory warning triggered');

    // Callback'leri batch olarak çağır - ana thread'i bloke etmesin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isActive) return;

      for (final callback in _cleanupCallbacks) {
        try {
          callback();
        } catch (e) {
          debugPrint('Cleanup callback error: $e');
        }
      }
    });

    // Dart GC'yi tetikle (eğer debug modundaysa)
    if (kDebugMode) {
      debugPrint('Triggering garbage collection');
    }
  }

  // Controller'ların cleanup callback'lerini kaydetmesi için
  void registerCleanupCallback(VoidCallback callback) {
    if (!_cleanupCallbacks.contains(callback)) {
      _cleanupCallbacks.add(callback);
    }
  }

  void unregisterCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.remove(callback);
  }

  // Optimized operation timing - batch processing
  void startOperation(String operationName) {
    if (!_isActive) return;

    _operationStartTimes[operationName] = DateTime.now();
    activeTasks.value++;
  }

  void endOperation(String operationName) {
    if (!_isActive) return;

    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      _operationStartTimes.remove(operationName);
      activeTasks.value = activeTasks.value > 0 ? activeTasks.value - 1 : 0;

      // Slow operation warning - sadece çok yavaş olanlar için
      if (duration.inSeconds > 10) {
        debugPrint('Very slow operation detected: $operationName took ${duration.inSeconds}s');
      }
    }
  }

  // Performance metrics getter
  Map<String, Duration> get operationMetrics => Map.from(_operationDurations);

  // Manual cleanup trigger
  void forceCleanup() {
    if (_isActive) {
      _handleLowMemory();
    }
  }

  // Performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'memoryUsage': '${(memoryUsage.value * 100).toStringAsFixed(1)}%',
      'averageFrameTime': '${averageFrameTime.value.toStringAsFixed(1)}ms',
      'droppedFrames': droppedFrames.value,
      'activeTasks': activeTasks.value,
      'isPerformanceGood': isPerformanceGood.value,
      'isOffline': isOffline.value,
      'isActive': _isActive,
    };
  }

  // Test için
  void triggerLowMemoryForTesting() {
    if (_isActive) {
      isLowMemoryWarning.value = true;
      _handleLowMemory();
    }
  }

  // Debug için controller durumunu kontrol et
  bool get isControllerActive => _isActive;
}