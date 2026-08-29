import 'package:flutter/material.dart';
import 'package:family_expense_management/style/decorations.dart';
import 'package:family_expense_management/style/padding.dart';

import 'gbutton.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onTabChange,
    this.gap = 0,
    this.padding = const EdgeInsets.all(25),
    this.activeColor,
    this.color,
    this.rippleColor = Colors.transparent,
    this.hoverColor = Colors.transparent,
    this.backgroundColor = Colors.transparent,
    this.tabBackgroundColor = Colors.transparent,
    this.tabBorderRadius = 100.0,
    this.iconSize,
    this.textStyle,
    this.curve = Curves.easeInCubic,
    this.tabMargin = EdgeInsets.zero,
    this.debug = false,
    this.duration = const Duration(milliseconds: 500),
    this.tabBorder,
    this.tabActiveBorder,
    this.tabShadow,
    this.haptic = true,
    this.tabBackgroundGradient,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.textSize,
  });

  final List<GButton> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChange;
  final double gap;
  final double tabBorderRadius;
  final double? iconSize;
  final Color? activeColor;
  final Color backgroundColor;
  final Color tabBackgroundColor;
  final Color? color;
  final Color rippleColor;
  final Color hoverColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry tabMargin;
  final TextStyle? textStyle;
  final Duration duration;
  final Curve curve;
  final bool debug;
  final bool haptic;
  final Border? tabBorder;
  final Border? tabActiveBorder;
  final List<BoxShadow>? tabShadow;
  final Gradient? tabBackgroundGradient;
  final MainAxisAlignment mainAxisAlignment;
  final double? textSize;

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late int selectedIndex;
  bool clickable = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsApp.symmetricV10H20,
      decoration: Decorations.whiteBorderTop,
      child: Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        children: widget.tabs
            .map(
              (t) => GButton(
                mainTab: t.mainTab,
                textSize: widget.textSize,
                key: t.key,
                border: t.border ?? widget.tabBorder,
                activeBorder: t.activeBorder ?? widget.tabActiveBorder,
                shadow: t.shadow ?? widget.tabShadow,
                borderRadius:
                    t.borderRadius ??
                    BorderRadius.all(Radius.circular(widget.tabBorderRadius)),
                debug: widget.debug,
                margin: t.margin ?? widget.tabMargin,
                active: selectedIndex == widget.tabs.indexOf(t),
                gap: t.gap ?? widget.gap,
                iconActiveColor: t.iconActiveColor ?? widget.activeColor,
                iconColor: t.iconColor ?? widget.color,
                iconSize: t.iconSize ?? widget.iconSize,
                textColor: t.textColor ?? widget.activeColor,
                rippleColor: t.rippleColor ?? widget.rippleColor,
                hoverColor: t.hoverColor ?? widget.hoverColor,
                padding: t.padding ?? widget.padding,
                haptic: widget.haptic,
                leading: t.leading,
                curve: widget.curve,
                backgroundGradient:
                    t.backgroundGradient ?? widget.tabBackgroundGradient,
                backgroundColor: t.backgroundColor ?? widget.tabBackgroundColor,
                duration: widget.duration,
                onPressed: () {
                  if (!clickable) return;
                  setState(() {
                    selectedIndex = widget.tabs.indexOf(t);
                    clickable = false;
                  });

                  t.onPressed?.call();

                  widget.onTabChange?.call(selectedIndex);

                  Future.delayed(widget.duration, () {
                    if (context.mounted) {
                      setState(() {
                        clickable = true;
                      });
                    }
                  });
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
