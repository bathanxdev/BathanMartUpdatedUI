import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile  = 600;
  static const double tablet  = 960;
  static const double desktop = 1280;
  static const double wide    = 1600;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth  => MediaQuery.sizeOf(this).width;
  bool get isMobile  => screenWidth < Breakpoints.mobile;
  bool get isTablet  => screenWidth >= Breakpoints.mobile  && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;
  bool get isWide    => screenWidth >= Breakpoints.desktop;

  double get contentWidth {
    final w = screenWidth;
    if (w >= Breakpoints.wide)    return 1440;
    if (w >= Breakpoints.desktop) return 1200;
    if (w >= Breakpoints.tablet)  return 900;
    return w;
  }

  double get pagePadding {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return 40;
    if (w >= Breakpoints.tablet)  return 28;
    return 16;
  }

  int get productColumns {
    final w = screenWidth;
    if (w >= Breakpoints.wide)    return 5;
    if (w >= Breakpoints.desktop) return 4;
    if (w >= Breakpoints.tablet)  return 3;
    return 2;
  }

  int get kpiColumns {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return 4;
    if (w >= Breakpoints.tablet)  return 3;
    return 2;
  }
}

class PageContainer extends StatelessWidget {
  final Widget child; final EdgeInsets? padding; final double? maxWidth;
  const PageContainer({super.key, required this.child, this.padding, this.maxWidth});
  @override Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth ?? context.contentWidth),
    child: Padding(padding: padding ?? EdgeInsets.symmetric(horizontal: context.pagePadding), child: child)));
}
