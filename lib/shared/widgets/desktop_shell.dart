import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/cart/bloc/cart_bloc.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  // Routes whose pages already build their own Scaffold + top nav
  // (e.g. StorefrontTopNavBar). DesktopShell must NOT add a second
  // nav bar on top of these — it should just pass the child through.
  static const _selfNavRoutePrefixes = [
    '/home',
    '/products',
    '/categories',
    '/category',
    '/cart',
    '/checkout',
    '/orders',
    '/account',
    '/subscriptions',
  ];

  bool _hasOwnNav(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return _selfNavRoutePrefixes.any((p) => loc == p || loc.startsWith('$p/'));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasOwnNav(context)) {
      // Page already renders its own Scaffold + StorefrontTopNavBar.
      return child;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const _TopNavBar(),
      body: child,
    );
  }
}

class _TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopNavBar();
  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.red, size: 20)),
          const SizedBox(width: 12),
          const Text('Sign Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: const Text('Are you sure you want to sign out of Bathan Mart?',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthLogoutEvent());
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final auth = context.watch<AuthBloc>().state;
    final isAuth = auth is AuthAuthenticatedState;
    final user = isAuth ? (auth as AuthAuthenticatedState).user : null;
    final cart = context.watch<CartBloc>().state;
    final cnt = cart is CartLoadedState ? cart.cart.itemCount : 0;
    final isAdmin = user?.isAdmin == true || user?.isStaff == true;

    return Container(
      height: 64,
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              bottom:
                  BorderSide(color: AppColors.border.withAlpha(120), width: 1)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              // Logo
              GestureDetector(
                  onTap: () => context.go(isAdmin ? '/admin-home' : '/'),
                  child: Row(children: [
                    Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: const Icon(Icons.local_mall_rounded,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bathan Mart', style: AppText.h3()),
                          Text('Local & Global Products',
                              style: AppText.caption()),
                        ]),
                  ])),
              const SizedBox(width: 32),

              // Nav links — different for admin vs customer
              if (!isAdmin) ...[
                _link(context, 'Home', '/home', loc),
                _link(context, 'Products', '/products', loc),
                _link(context, 'Subscribe', '/subscriptions', loc),
              ],
              if (isAdmin) ...[
                _link(context, 'Dashboard', '/admin', loc),
                _link(context, 'Orders', '/admin/orders', loc),
                _link(context, 'Inventory', '/admin/inventory', loc),
                _link(context, 'Products', '/admin/products', loc),
                _link(context, 'Reports', '/admin/reports', loc),
              ],
              const Spacer(),

              // Right side
              if (!isAuth) ...[
                TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Sign In',
                        style: AppText.bodyMd(color: AppColors.textSecondary))),
                const SizedBox(width: 8),
                SizedBox(
                    width: 130,
                    child: ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20)),
                        child: const Text('Get Started'))),
              ] else ...[
                // Cart for customers
                if (!isAdmin)
                  Stack(clipBehavior: Clip.none, children: [
                    IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () => context.go('/cart'),
                        color: AppColors.textPrimary,
                        tooltip: 'Cart'),
                    if (cnt > 0)
                      Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle),
                              child: Center(
                                  child: Text('$cnt',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800))))),
                  ]),
                IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                    color: AppColors.textSecondary,
                    tooltip: 'Notifications'),
                const SizedBox(width: 4),
                // User dropdown
                PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'logout') _confirmLogout(context);
                      if (v == 'orders') context.go('/orders');
                      if (v == 'admin') context.go('/admin-home');
                      if (v == 'rider') context.go('/rider-home');
                      if (v == 'home') context.go('/home');
                    },
                    offset: const Offset(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.border)),
                    elevation: 8,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: AppColors.border)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                  (user!.name.isNotEmpty ? user.name[0] : 'U')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                          const SizedBox(width: 8),
                          Text(user.name.split(' ').first,
                              style: AppText.bodyMd()),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: AppColors.textHint),
                        ])),
                    itemBuilder: (_) => [
                          if (isAdmin)
                            _menuItem(
                                'admin',
                                Icons.admin_panel_settings_outlined,
                                'Admin Panel'),
                          if (!isAdmin)
                            _menuItem('home', Icons.home_outlined, 'My Home'),
                          if (!isAdmin)
                            _menuItem(
                                'orders', Icons.receipt_outlined, 'My Orders'),
                          if (user.role == 'rider')
                            _menuItem('rider', Icons.delivery_dining_outlined,
                                'Rider App'),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                              value: 'logout',
                              child: Row(children: [
                                Icon(Icons.logout,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: 10),
                                Text('Sign Out',
                                    style:
                                        AppText.bodyMd(color: AppColors.error))
                              ])),
                        ]),
              ],
            ])),
      )),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
          value: value,
          child: Row(children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: AppText.bodyMd())
          ]));

  Widget _link(BuildContext ctx, String label, String route, String loc) {
    final active = loc == route || (route.length > 1 && loc.startsWith(route));
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextButton(
            onPressed: () => ctx.go(route),
            style: TextButton.styleFrom(
                foregroundColor:
                    active ? AppColors.primary : AppColors.textSecondary,
                backgroundColor:
                    active ? AppColors.primarySoft : Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                minimumSize: const Size(0, 36)),
            child: Text(label,
                style: AppText.bodyMd(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    weight: active ? FontWeight.w700 : FontWeight.w500))));
  }
}
