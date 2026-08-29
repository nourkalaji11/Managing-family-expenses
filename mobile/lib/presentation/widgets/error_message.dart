import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

class ErrorMessage extends StatelessWidget {
  final Function()? reload;
  final Failure failure;
  final bool showImage;
  const ErrorMessage({
    super.key,
    this.reload,
    required this.failure,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return reload == null
        ? Center(
            child: Padding(
              padding: EdgeInsetsApp.symmetricH20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showImage)
                    Center(
                      child: SvgPicture.asset(
                        failure is ConnectionFailure
                            ? "assets/images/connection_error.svg"
                            : "assets/images/global_error.svg",
                        height: 0.3.sh,
                        fit: BoxFit.contain,
                      ),
                    ),
                  Spaces.height10,
                  Flexible(
                    child: Text(
                      failure.message,
                      style: TextStyleApp.black14700,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          )
        : CustomMaterialIndicator(
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
            onRefresh: () {
              reload!();
              return Future.delayed(const Duration(seconds: 0));
            },
            child: Center(
              child: Padding(
                padding: EdgeInsetsApp.symmetricH20,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showImage)
                          Center(
                            child: SvgPicture.asset(
                              failure is ConnectionFailure
                                  ? "assets/images/connection_error.svg"
                                  : "assets/images/global_error.svg",
                              height: 0.3.sh,
                              fit: BoxFit.contain,
                            ),
                          ),
                        Spaces.height10,
                        Flexible(
                          child: Text(
                            failure.message,
                            style: TextStyleApp.black14700,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    ListView(),
                  ],
                ),
              ),
            ),
          );
  }
}
