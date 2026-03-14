import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class Responsive {
  // Breakpoints
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static double getFormWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) {
      return width * 0.9;
    } else if (width < desktop) {
      return 500;
    } else {
      return 400;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(AppDimensions.paddingL);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(AppDimensions.paddingXL);
    } else {
      return const EdgeInsets.all(AppDimensions.paddingXXL);
    }
  }
}

// Адаптивный билдер
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < Responsive.mobile;
        final isTablet = width >= Responsive.mobile && width < Responsive.desktop;
        final isDesktop = width >= Responsive.desktop;

        return builder(context, isMobile, isTablet, isDesktop);
      },
    );
  }
}
