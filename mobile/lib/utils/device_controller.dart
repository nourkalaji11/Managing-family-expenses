import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceController {
  Future<bool> isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kDebugMode) {
      return false;
    }

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isEmulator = !androidInfo.isPhysicalDevice ||
          androidInfo.brand.toLowerCase().contains('generic') ||
          androidInfo.device.toLowerCase().contains('generic');
      return isEmulator;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final isSimulator = !iosInfo.isPhysicalDevice;
      return isSimulator;
    }

    return false; // Fallback for other platforms
  }
}
