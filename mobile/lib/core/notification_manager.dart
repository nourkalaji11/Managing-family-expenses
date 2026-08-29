import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:family_expense_management/core/default_settings.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class OneSignalNotificationManager {
  static int? conversationId;
  static bool _clickListenerAdded = false;
  static bool _foregroundListenerAdded = false;

  static Future<void> initialize() async {
    try {
      OneSignal.initialize(DefaultSettings.oneSignalAppId);

      await requestNotificationPermission();

      await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      await OneSignal.Debug.setAlertLevel(OSLogLevel.none);

      final pushSubscription = OneSignal.User.pushSubscription;
      pushSubscription.addObserver((state) async {
        // final id = state.current.id;
        // final token = state.current.token;
        // final optedIn = state.current.optedIn;
        // log("Observer -> ID: $id | Token: $token | OptedIn: $optedIn");

        await OneSignal.User.getOnesignalId().then((value) {
          LocalsApp.deviceToken = value;
          log(LocalsApp.deviceToken ?? "null", name: "Device Token:");
        });
      });

      if (pushSubscription.optedIn ?? false) {
        await OneSignal.User.getOnesignalId().then((value) {
          LocalsApp.deviceToken = value;
          log(LocalsApp.deviceToken ?? "null", name: "Device Token:");
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  static requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        PermissionStatus status = await Permission.notification.status;
        print(status);

        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.notification.status;
      print(status);

      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  static addClickListener() {
    try {
      if (_clickListenerAdded == false) {
        OneSignal.Notifications.addClickListener((event) async {
          log(
            'NOTIFICATION CLICK LISTENER CALLED WITH EVENT: ${event.jsonRepresentation()}',
            name: event.notification.additionalData!['category'],
          );
          _clickListenerAdded = true;
          EasyLoading.dismiss();
        });
      }
      if (_foregroundListenerAdded == false) {
        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          print(event.jsonRepresentation());
          _foregroundListenerAdded = true;
          print("notificationForeground");
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
