import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemFunc {
  static dismissKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static Future<bool> requestCameraPermission() async {
    bool permission = false;

    permission = await Permission.camera.request().isGranted;
    if (!permission) {
      await Permission.camera.request();
      permission = await Permission.camera.status.isGranted;
    }

    if (!permission) {
      await openAppSettings();
    }
    return permission;
  }

  static Future<bool> requestPhotoPermission() async {
    bool permission = false;
    if (Platform.isAndroid) {
      permission = true;
      // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // print(androidInfo.version.sdkInt);
      // if (androidInfo.version.sdkInt >= 33) {
      //   permission = await Permission.photos.status.isGranted;
      //   if (!permission) {
      //     await Permission.photos.request();
      //     permission = await Permission.photos.status.isGranted;
      //   }
      // } else {
      //   permission = await Permission.storage.status.isGranted;
      //   if (!permission) {
      //     await Permission.storage.request();
      //     permission = await Permission.storage.status.isGranted;
      //   }
      // }
    } else {
      permission = await Permission.storage.request().isGranted;
      if (!permission) {
        await Permission.storage.request();
        permission = await Permission.storage.status.isGranted;
      }
    }

    if (!permission) {
      await openAppSettings();
    }
    return permission;
  }
}
