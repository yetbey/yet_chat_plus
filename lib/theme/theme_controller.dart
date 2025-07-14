import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _box.read(_key) ?? false;
  }

  void changeThemeMode(bool value) {
    isDarkMode.value = value;
    _box.write(_key, value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}