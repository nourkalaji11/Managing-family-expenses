import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:family_expense_management/style/colors.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Function() reload;
  final Widget child;
  final int secondsDelay;
  const AppRefreshIndicator({
    super.key,
    required this.reload,
    required this.child,
    this.secondsDelay = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMaterialIndicator(
      indicatorBuilder: (context, controller) {
        return CircleAvatar(
          backgroundColor: ColorsApp.offwhite,
          child: Center(
            child: SpinKitFadingCircle(
              size: 30.r,
              color: ColorsApp.red,
              duration: Duration(milliseconds: 900),
            ),
          ),
        );
      },
      onRefresh: () async {
        reload();
        await Future.delayed(Duration(seconds: secondsDelay));
      },
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [SizedBox(height: MediaQuery.of(context).size.height)],
          ),
          child,
        ],
      ),
    );
  }
}
