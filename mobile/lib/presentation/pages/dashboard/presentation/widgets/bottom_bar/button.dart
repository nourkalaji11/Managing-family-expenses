import 'dart:math' show pow;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/style/text_style.dart';

class Button extends StatefulWidget {
  const Button({
    Key? key,
    required this.tab,
    this.iconSize,
    this.leading,
    this.iconActiveColor,
    this.iconColor,
    this.gap,
    this.color,
    this.rippleColor,
    this.hoverColor,
    required this.onPressed,
    this.duration,
    this.curve,
    this.padding,
    this.margin,
    required this.active,
    this.debug,
    this.gradient,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.shadow,
    this.textSize,
  }) : super(key: key);

  final MainTabs tab;
  final double? iconSize;
  final Widget? leading;
  final Color? iconActiveColor;
  final Color? iconColor;
  final Color? color;
  final Color? rippleColor;
  final Color? hoverColor;
  final double? gap;
  final bool? active;
  final bool? debug;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Duration? duration;
  final Curve? curve;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Border? activeBorder;
  final List<BoxShadow>? shadow;
  final double? textSize;

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with TickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController expandController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.active!;

    expandController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    expandController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var curveValue = expandController
        .drive(
          CurveTween(curve: _expanded ? widget.curve! : widget.curve!.flipped),
        )
        .value;
    var _colorTween = ColorTween(
      begin: widget.iconColor,
      end: widget.iconActiveColor,
    );
    var _colorTweenAnimation = _colorTween.animate(
      CurvedAnimation(
        parent: expandController,
        curve: _expanded ? Curves.easeInExpo : Curves.easeOutCirc,
      ),
    );

    _expanded = !widget.active!;
    if (_expanded)
      expandController.reverse();
    else
      expandController.forward();

    Widget icon =
        widget.leading ??
        SvgPicture.asset(
          widget.tab.icon,
          height: widget.iconSize,
          width: widget.iconSize,
          colorFilter: ColorFilter.mode(
            _colorTweenAnimation.value!,
            BlendMode.srcIn,
          ),
        );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        highlightColor: widget.hoverColor,
        splashColor: widget.rippleColor,
        borderRadius: widget.borderRadius,
        onTap: widget.onPressed,
        child: Container(
          padding: widget.margin,
          child: AnimatedContainer(
            curve: Curves.easeOut,
            padding: widget.padding,
            duration: widget.duration!,
            decoration: BoxDecoration(
              boxShadow: widget.shadow,
              border: widget.active!
                  ? (widget.activeBorder ?? widget.border)
                  : widget.border,
              gradient: widget.gradient,
              color: _expanded
                  ? widget.color!.withOpacity(0)
                  : widget.debug!
                  ? Colors.red
                  : widget.gradient != null
                  ? Colors.white
                  : widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Builder(
                builder: (_) {
                  return Stack(
                    children: [
                      if (widget.tab.text != '')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Opacity(opacity: 0, child: icon),
                            Align(
                              alignment: Alignment.centerRight,
                              widthFactor: curveValue,
                              child: Opacity(
                                opacity: _expanded
                                    ? pow(expandController.value, 13) as double
                                    : expandController
                                          .drive(
                                            CurveTween(curve: Curves.easeIn),
                                          )
                                          .value,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left:
                                        widget.gap! +
                                        8 -
                                        (8 *
                                            expandController
                                                .drive(
                                                  CurveTween(
                                                    curve: Curves.easeOutSine,
                                                  ),
                                                )
                                                .value),
                                    right:
                                        8 *
                                        expandController
                                            .drive(
                                              CurveTween(
                                                curve: Curves.easeOutSine,
                                              ),
                                            )
                                            .value,
                                  ),
                                  child: Text(
                                    widget.tab.text.tr(),
                                    style: TextStyleApp.white12500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      Align(alignment: Alignment.centerLeft, child: icon),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
