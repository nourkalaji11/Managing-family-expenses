import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LocalStorage {
  Future<void> saveUser(String userToken) async {
    final box = await Hive.openBox('app_name');
    box.put("token", userToken);
  }

  Future<String?> getUser() async {
    final box = await Hive.openBox('app_name');
    return box.get("token");
  }

  void removeUser() async {
    final box = await Hive.openBox('app_name');
    box.delete('token');
  }

  void saveLanguage(Locale locale) async {
    final box = await Hive.openBox('app_name');
    box.put('lang', locale.languageCode);
  }

  Future<Locale> getLanguage() async {
    final box = await Hive.openBox('app_name');
    String? lang = box.get('lang');
    log(lang ?? "", name: "Locale App");
    if ((lang != null && lang == "ar") ||
        (Platform.localeName.substring(0, 2) == "ar")) {
      return const Locale('ar');
    } else {
      return Locale(lang ?? "en");
    }
  }

  Future<void> saveOnBoarding(bool? isDone) async {
    final box = await Hive.openBox('app_name');
    if (isDone != null) {
      box.put("welcome_screen", isDone);
    } else {
      box.delete('welcome_screen');
    }
  }

  Future<bool?> getOnBoarding() async {
    final box = await Hive.openBox('app_name');
    return box.get("welcome_screen");
  }

  void saveFCMToken(String token) async {
    final box = await Hive.openBox('app_name');
    box.put('fcm_token', token);
  }

  Future<String> getFCMToken() async {
    final box = await Hive.openBox('app_name');
    return box.get('fcm_token') ?? "";
  }
}
