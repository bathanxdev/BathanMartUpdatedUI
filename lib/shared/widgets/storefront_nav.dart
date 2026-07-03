import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Adjust these two relative paths if you place this file somewhere other
// than lib/shared/widgets/ — they assume that location.
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'app_widgets.dart' show PageContainer;

// ────────────────────────────────────────────────────────────
// CATEGORY ICON / COLOR HELPERS
// Single source of truth — was previously copy-pasted in
// customer_landing_page.dart, all_categories_screen.dart and
// category_products_screen.dart.
// ────────────────────────────────────────────────────────────
IconData iconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('grocer') || n.contains('food') || n.contains('pantry')) {
    return Icons.local_grocery_store_outlined;
  }
  if (n.contains('electron') || n.contains('tech') || n.contains('gadget')) {
    return Icons.devices_other_outlined;
  }
  if (n.contains('cloth') || n.contains('fashion') || n.contains('apparel')) {
    return Icons.checkroom_outlined;
  }
  if (n.contains('home') ||
      n.contains('decor') ||
      n.contains('furniture') ||
      n.contains('living')) {
    return Icons.chair_outlined;
  }
  if (n.contains('beauty') ||
      n.contains('cosmetic') ||
      n.contains('skincare')) {
    return Icons.face_retouching_natural_outlined;
  }
  if (n.contains('toy')) return Icons.toys_outlined;
  if (n.contains('sport') || n.contains('outdoor') || n.contains('fitness')) {
    return Icons.sports_basketball_outlined;
  }
  if (n.contains('baby') || n.contains('kid')) {
    return Icons.child_friendly_outlined;
  }
  if (n.contains('kitchen') || n.contains('dining') || n.contains('cookware')) {
    return Icons.kitchen_outlined;
  }
  if (n.contains('pet')) return Icons.pets_outlined;
  if (n.contains('book') || n.contains('stationery')) {
    return Icons.menu_book_outlined;
  }
  if (n.contains('health') || n.contains('wellness') || n.contains('medic')) {
    return Icons.health_and_safety_outlined;
  }
  return Icons.category_outlined;
}

const List<Color> kCategoryPalette = [
  Color(0xFFFDE8B8),
  Color(0xFFC9E6FB),
  Color(0xFFFBD6E4),
  Color(0xFFD3E9D6),
  Color(0xFFFBDCEE),
  Color(0xFFFCE0C6),
  Color(0xFFD9E0FB),
  Color(0xFFF6D8D8),
  Color(0xFFE3D6F7),
  Color(0xFFFDF0B8),
];

Color colorForCategoryIndex(int i) =>
    kCategoryPalette[i % kCategoryPalette.length];

// ────────────────────────────────────────────────────────────
// TOP NAV BAR — logo · Categories+search pill · Deals · Pickup ·
// Account · Cart. One implementation, used by every customer screen.
// ────────────────────────────────────────────────────────────
class StorefrontTopNavBar extends StatelessWidget
    implements PreferredSizeWidget {
  final dynamic user;
  final int cartCount;
  final bool isDesktop;
  final List<dynamic> categories;

  const StorefrontTopNavBar({
    super.key,
    required this.user,
    required this.cartCount,
    required this.isDesktop,
    required this.categories,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: PageContainer(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/'),
                    child: Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Text('B',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Text('Bathan Mart',
                          style: AppText.h3(color: AppColors.primary)),
                    ]),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 520, minWidth: 280),
                          child: _CategoriesSearchBar(categories: categories),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _NavIconText(
                        icon: Icons.local_offer_outlined,
                        label: 'Deals',
                        onTap: () => context.go('/products?sort=discount')),
                    const SizedBox(width: 14),
                    _NavIconText(
                        icon: Icons.local_shipping_outlined,
                        label: 'Pickup & delivery',
                        onTap: () {}),
                    const SizedBox(width: 14),
                    _NavIconText(
                        icon: Icons.person_outline,
                        label: 'Account',
                        onTap: () => context.go('/account')),
                  ] else
                    const Spacer(),
                  const SizedBox(width: 10),
                  if (user?.isStaff == true || user?.isAdmin == true)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined,
                          color: AppColors.textPrimary),
                      onPressed: () => context.go('/admin-home'),
                    ),
                  _CartIcon(count: cartCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Categories mega-menu + inline search, merged into ONE pill.
//
// FIX (item 2 / item 3 in the request): redesigned to the compact
// two-tone pill from the reference — white "Categories" segment,
// muted search segment, single continuous border. The old version had
// a stray blue focus box around just the TextField (Flutter's default
// focused-border decoration bleeding through even though the input
// used `border: InputBorder.none`, because `focusedBorder` wasn't
// explicitly cleared). This version clears every border state on the
// TextField and drives the *entire* pill's highlight color off one
// `active` flag (menu open OR field focused), in accent orange.
class _CategoriesSearchBar extends StatefulWidget {
  final List<dynamic> categories;
  const _CategoriesSearchBar({required this.categories});

  @override
  State<_CategoriesSearchBar> createState() => _CategoriesSearchBarState();
}

class _CategoriesSearchBarState extends State<_CategoriesSearchBar> {
  final LayerLink _link = LayerLink();
  final FocusNode _searchFocus = FocusNode();
  OverlayEntry? _entry;
  Timer? _closeTimer;
  bool _open = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() => _focused = _searchFocus.hasFocus);
    });
  }

  void _cancelClose() => _closeTimer?.cancel();

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), _close);
  }

  void _openMenu() {
    _cancelClose();
    if (_entry != null) return;
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: MouseRegion(
            onEnter: (_) => _cancelClose(),
            onExit: (_) => _scheduleClose(),
            child: _CategoriesPanel(
              categories: widget.categories,
              onSelect: (id) {
                _close();
                context.go('/products?category_id=$id');
              },
              onViewAll: () {
                _close();
                context.go('/categories');
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  void _toggle() => _open ? _close() : _openMenu();

  @override
  void dispose() {
    _closeTimer?.cancel();
    _entry?.remove();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _open || _focused;
    return CompositedTransformTarget(
      link: _link,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38, // was 44 — smaller, closer to the reference
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          border: Border.all(
              color: active
                  ? AppColors.accent
                  : AppColors.textHint.withValues(alpha: 0.35),
              width: 1.2),
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(40),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ]
              : const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MouseRegion(
              onEnter: (_) => _openMenu(),
              onExit: (_) => _scheduleClose(),
              child: InkWell(
                  onTap: _toggle,
                  child: SizedBox(
                    height: 38,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.menu,
                            size: 15, color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text('Categories',
                            style: AppText.bodyMd(weight: FontWeight.w600)
                                .copyWith(fontSize: 13)),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 150),
                          turns: _open ? 0.5 : 0,
                          child: Icon(Icons.keyboard_arrow_down,
                              size: 15,
                              color: _open
                                  ? AppColors.accent
                                  : AppColors.textPrimary),
                        ),
                      ]),
                    ),
                  )),
            ),
            Container(width: 1, color: AppColors.border),
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 16, color: AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                focusNode: _searchFocus,
                cursorColor: AppColors.accent,
                textAlignVertical: TextAlignVertical.center,
                style: AppText.bodyMd().copyWith(fontSize: 13, height: 1.0),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  hintText: 'Search products…',
                  hintStyle: AppText.bodyMd(color: AppColors.textHint)
                      .copyWith(fontSize: 13, height: 1.0),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  final List<dynamic> categories;
  final ValueChanged<String> onSelect;
  final VoidCallback onViewAll;
  const _CategoriesPanel({
    required this.categories,
    required this.onSelect,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text('All Categories',
                    style: AppText.bodyMd(weight: FontWeight.w700)),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No categories yet'),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      thickness: 5,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6)
                            .copyWith(right: 10),
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final c = categories[i] as Map;
                          final id = c['_id']?.toString() ?? '';
                          final name = c['name']?.toString() ?? '';
                          return _CategoryRow(
                            name: name,
                            icon: iconForCategory(name),
                            onTap: () => onSelect(id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;
  const _CategoryRow(
      {required this.name, required this.icon, required this.onTap});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hover ? AppColors.surfaceWarm : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Icon(widget.icon,
                size: 18,
                color: _hover ? AppColors.accent : AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.name,
                  style: AppText.bodyMd(
                      weight: _hover ? FontWeight.w700 : FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NavIconText extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavIconText(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_NavIconText> createState() => _NavIconTextState();
}

class _NavIconTextState extends State<_NavIconText> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon,
                size: 18,
                color: _hover ? AppColors.accent : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(widget.label,
                style: AppText.bodyMd(weight: FontWeight.w600).copyWith(
                    color: _hover ? AppColors.accent : AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  final int count;
  const _CartIcon({required this.count});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/cart'),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.shopping_cart_outlined,
              color: AppColors.textPrimary),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                alignment: Alignment.center,
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// FOOTER — left-aligned logo block + three link columns.
// ────────────────────────────────────────────────────────────
class StorefrontFooter extends StatelessWidget {
  const StorefrontFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: _brandBlock()),
                      Expanded(
                        flex: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _col('Shop', [
                              'Deals',
                              'New arrivals',
                              'Best sellers',
                              'Clearance'
                            ]),
                            _col('Help', [
                              'Order status',
                              'Shipping',
                              'Returns',
                              'Contact us'
                            ]),
                            _col('Company', [
                              'About',
                              'Careers',
                              'Sustainability',
                              'Press'
                            ]),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _brandBlock(),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 40,
                        runSpacing: 24,
                        children: [
                          _col('Shop', [
                            'Deals',
                            'New arrivals',
                            'Best sellers',
                            'Clearance'
                          ]),
                          _col('Help', [
                            'Order status',
                            'Shipping',
                            'Returns',
                            'Contact us'
                          ]),
                          _col('Company',
                              ['About', 'Careers', 'Sustainability', 'Press']),
                        ],
                      ),
                    ],
                  ),
            const SizedBox(height: 28),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Text('© 2026 Bathan Mart. All rights reserved.',
                textAlign: TextAlign.center, style: AppText.caption()),
          ],
        ),
      ),
    );
  }

  Widget _brandBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('B',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text('Bathan Mart', style: AppText.h3(color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: 300,
          child: Text(
            'Your everyday marketplace for groceries, '
            'electronics, home and more.',
            style: AppText.caption(),
          ),
        ),
      ],
    );
  }

  Widget _col(String title, List<String> items) {
    return Builder(builder: (context) {
      return SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.bodyMd(weight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => context.go('/products'),
                    child: Text(t, style: AppText.caption()),
                  ),
                )),
          ],
        ),
      );
    });
  }
}
