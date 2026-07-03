import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/cart/bloc/cart_bloc.dart';

class MobileShell extends StatefulWidget {
  final Widget child;
  const MobileShell({super.key, required this.child});
  @override State<MobileShell> createState() => _MobileShellState();
}
class _MobileShellState extends State<MobileShell> {
  int _idx = 0;
  static const _routes = ['/home', '/products', '/cart', '/orders', '/subscriptions'];
  static const _labels = ['Home', 'Shop', 'Cart', 'Orders', 'Subscribe'];
  static const _icons  = [Icons.home_rounded, Icons.storefront_rounded, Icons.shopping_bag_rounded, Icons.receipt_long_rounded, Icons.repeat_rounded];
  static const _icons2 = [Icons.home_outlined, Icons.storefront_outlined, Icons.shopping_bag_outlined, Icons.receipt_long_outlined, Icons.repeat_outlined];

  @override Widget build(BuildContext context) => Scaffold(
    body: widget.child,
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, -4))]),
      child: SafeArea(child: BlocBuilder<CartBloc, CartState>(builder: (ctx, cs) {
        final count = cs is CartLoadedState ? cs.cart.itemCount : 0;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final sel = _idx == i;
              return GestureDetector(
                onTap: () { setState(() => _idx = i); ctx.go(_routes[i]); },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(width: 64, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: sel ? BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.full)) : null,
                    child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                      Icon(sel ? _icons[i] : _icons2[i], size: 22, color: sel ? AppColors.primary : AppColors.textHint),
                      if (i == 2 && count > 0)
                        Positioned(top: -6, right: -10, child: Container(width: 16, height: 16,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))),
                    ])),
                  const SizedBox(height: 3),
                  Text(_labels[i], style: TextStyle(
                    fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? AppColors.primary : AppColors.textHint)),
                ])));
            })));
      }))),
  );
}
