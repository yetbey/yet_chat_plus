import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/controller/performance_controller.dart';

abstract class BaseController extends GetxController {
  final supabase = Supabase.instance.client;

  // Error handling
  final RxString lastError = ''.obs;
  final RxBool hasError = false.obs;
  final RxBool isLoading = false.obs;

  // Subscriptions için
  final List<StreamSubscription> _subscriptions = [];

  // Cache temizleme timer'ı
  Timer? _cacheCleanupTimer;

  // Cleanup callback
  late VoidCallback _cleanupCallback;

  @override
  void onInit() {
    super.onInit();

    // Error observer
    ever(hasError, (bool error) {
      if (error && lastError.value.isNotEmpty) {
        _handleError(lastError.value);
      }
    });

    // Cache temizleme timer'ı (her 5 dakikada bir)
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => cleanupCache(),
    );

    // Cleanup callback'i tanımla
    _cleanupCallback = () => cleanupCache();

    // Performance controller'a callback'i kaydet (güvenli şekilde)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerToPerformanceController();
    });
  }

  void _registerToPerformanceController() {
    try {
      // Get.find kullanmadan önce controller'ın var olup olmadığını kontrol et
      if (Get.isRegistered<PerformanceController>()) {
        final performanceController = Get.find<PerformanceController>();
        performanceController.registerCleanupCallback(_cleanupCallback);
      }
    } catch (e) {
      debugPrint('PerformanceController kayıt hatası: $e');
    }
  }

  @override
  void onClose() {
    // Performance controller'dan callback'i kaldır
    try {
      if (Get.isRegistered<PerformanceController>()) {
        final performanceController = Get.find<PerformanceController>();
        performanceController.unregisterCleanupCallback(_cleanupCallback);
      }
    } catch (e) {
      debugPrint('PerformanceController kayıt silme hatası: $e');
    }

    // Tüm subscription'ları temizle
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Timer'ı temizle
    _cacheCleanupTimer?.cancel();

    // Cache'i temizle
    cleanupCache();

    super.onClose();
  }

  // Subscription ekleme helper'ı
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  // Error handling
  void setError(String message) {
    debugPrint('Controller Error: $message');
    lastError.value = message;
    hasError.value = true;
    isLoading.value = false;
  }

  void clearError() {
    hasError.value = false;
    lastError.value = '';
  }

  void _handleError(String error) {
    // Override edilebilir error handling
    Get.snackbar(
      'Hata',
      error,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  // Safe async operation wrapper
  Future<T?> safeAsyncOperation<T>(
      Future<T> Function() operation, {
        String? errorMessage,
        bool showLoading = true,
      }) async {
    if (showLoading) isLoading.value = true;
    clearError();

    try {
      final result = await operation();
      return result;
    } on PostgrestException catch (e) {
      setError(errorMessage ?? 'Veritabanı hatası: ${e.message}');
      return null;
    } on SocketException catch (e) {
      setError('İnternet bağlantınızı kontrol edin');
      return null;
    } catch (e) {
      setError(errorMessage ?? 'Beklenmedik bir hata oluştu: $e');
      return null;
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // Safe performance tracking
  void startPerformanceTracking(String operationName) {
    try {
      if (Get.isRegistered<PerformanceController>()) {
        final performanceController = Get.find<PerformanceController>();
        performanceController.startOperation(operationName);
      }
    } catch (e) {
      debugPrint('Performance tracking start error: $e');
    }
  }

  void endPerformanceTracking(String operationName) {
    try {
      if (Get.isRegistered<PerformanceController>()) {
        final performanceController = Get.find<PerformanceController>();
        performanceController.endOperation(operationName);
      }
    } catch (e) {
      debugPrint('Performance tracking end error: $e');
    }
  }

  // Cache temizleme - override edilmeli
  void cleanupCache() {
    // Alt sınıflar bu metodu override etmeli
    debugPrint('${runtimeType}: Cache cleanup triggered');
  }

  // Retry mechanism
  Future<void> retryLastOperation() async {
    // Alt sınıflar bu metodu override etmeli
    debugPrint('${runtimeType}: Retry operation called');
  }
}