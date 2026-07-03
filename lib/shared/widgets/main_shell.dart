import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override Widget build(BuildContext context) =>
    context.isDesktop ? DesktopShell(child: child) : MobileShell(child: child);
}
