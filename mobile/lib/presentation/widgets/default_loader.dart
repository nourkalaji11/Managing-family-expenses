import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:family_expense_management/style/colors.dart';

class DefaultLoader extends StatelessWidget {
  final Color? color;

  const DefaultLoader({super.key, this.color = ColorsApp.red});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitThreeBounce(
        color: color!,
        size: 30.r,
        duration: Duration(milliseconds: 900),
      ),
    );
  }
}
