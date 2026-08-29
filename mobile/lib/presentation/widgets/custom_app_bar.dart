import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/text_style.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool? showBackButton;
  final Widget? leading;
  final String? title;
  final Function()? onPressedBack;
  final Color? backgroundColor;
  const CustomAppBar({
    super.key,
    this.leading,
    this.showBackButton = true,
    this.title,
    this.onPressedBack,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      actions: leading != null
          ? [Padding(padding: EdgeInsetsApp.symmetricH20, child: leading!)]
          : [],
      title: title != null
          ? InkWell(
              focusColor: Colors.transparent,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                if (Navigator.of(context).canPop() && showBackButton == true) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(title ?? "", style: TextStyleApp.black20500),
            )
          : null,
      centerTitle: true,
      leadingWidth: 50.w,
      leading: showBackButton == true
          ? IconButton(
              onPressed:
                  onPressedBack ??
                  () {
                    Navigator.of(context).pop();
                  },
              padding: EdgeInsetsApp.symmetricH20,
              icon: Icon(
                Icons.arrow_back_ios,
                color: backgroundColor == ColorsApp.black
                    ? ColorsApp.white
                    : ColorsApp.black,
                size: 20.r,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50.h);
}
