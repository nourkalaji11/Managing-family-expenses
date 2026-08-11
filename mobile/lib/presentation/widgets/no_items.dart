import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

class NoItems extends StatelessWidget {
  final bool showImage;
  final String? message;
  final String? message2;
  final Function()? reload;
  const NoItems({
    super.key,
    this.message,
    this.message2,
    this.showImage = true,
    this.reload,
  });

  @override
  Widget build(BuildContext context) {
    return reload == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showImage) ...[
                  SvgPicture.asset("assets/images/no_items.svg"),
                  Spaces.height30,
                ],
                Text(
                  message ?? "no_items".tr(),
                  style: TextStyleApp.black14700,
                  textAlign: TextAlign.center,
                ),
                if (message2 != null) ...[
                  Spaces.height10,
                  Text(
                    message2!,
                    style: TextStyleApp.grey14300,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
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
            onRefresh: () async {
              reload!();
              await Future.delayed(const Duration(seconds: 2));
            },
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showImage) ...[
                        SvgPicture.asset("assets/images/no_items.svg"),
                        Spaces.height30,
                      ],
                      Text(
                        message ?? "no_items".tr(),
                        style: TextStyleApp.black14700,
                        textAlign: TextAlign.center,
                      ),
                      if (message2 != null) ...[
                        Spaces.height10,
                        Text(
                          message2!,
                          style: TextStyleApp.grey14300,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height),
                  ],
                ),
              ],
            ),
          );
  }
}
