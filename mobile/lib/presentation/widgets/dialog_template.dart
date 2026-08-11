import 'package:flutter/material.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/radius.dart';

class DialogTemplate extends StatelessWidget {
  final Widget child;
  const DialogTemplate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 30,
      insetPadding: EdgeInsetsApp.symmetricV10H20,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusApp.radius32),
      child: Padding(padding: EdgeInsetsApp.symmetricH12, child: child),
    );
  }
}
