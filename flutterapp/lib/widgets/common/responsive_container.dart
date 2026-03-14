import 'package:flutter/material.dart';
import 'package:flutterapp/utils/responsive.dart';
import 'package:flutterapp/constants/app_colors.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? color;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: maxWidth != null
            ? BoxConstraints(maxWidth: maxWidth!)
            : null,
        padding: padding ?? Responsive.getScreenPadding(context),
        color: color,
        decoration: decoration,
        child: child,
      ),
    );
  }
}
