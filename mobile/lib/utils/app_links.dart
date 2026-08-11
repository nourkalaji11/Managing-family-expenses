// import 'dart:developer';

// import 'package:app_links/app_links.dart';
// import 'package:flutter/material.dart';

// class AppLinksController {
//   final AppLinks _appLinks = AppLinks();

//   initAppLinks(BuildContext context) {
//     _appLinks.uriLinkStream.listen((Uri? uri) {
//       if (uri != null) {
//         _handleDeepLink(uri, context);
//       }
//     });
//   }

//   void _handleDeepLink(Uri uri, BuildContext context) {
//     log(uri.path);
//     if (uri.queryParameters.isEmpty) return;

//     Map<String, String> param = uri.queryParameters;

//     String receivedCode = param['code'] ?? '';

//     if (LocalsApp.user != null) return;

//     Navigator.pushReplacement(
//         DefaultSettings.mainNavigatorKey.currentContext!,
//         MaterialPageRoute(
//             builder: (_) => WelcomeScreen(referralCode: receivedCode)));
//   }
// }
