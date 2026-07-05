import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/storefront_nav.dart';

class CustomerLandingPage extends StatefulWidget {
  const CustomerLandingPage({super.key});

  @override
  State<CustomerLandingPage> createState() => _CustomerLandingPageState();
}

class _CustomerLandingPageState extends State<CustomerLandingPage> {
  List<dynamic> _products = [], _categories = [];
  bool _loading = true;

  // How many categories to show on the landing page before "View all".
  static const int _kLandingCategoryLimit = 6;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await ApiClient.instance
          .get('/products', params: {'limit': '10', 'sort': 'sold_count'});
      final r2 = await ApiClient.instance.get('/categories');
      if (mounted) {
        setState(() {
          _products = (r1['data'] as List?) ?? [];
          _categories = (r2['data'] as List?) ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticatedState ? auth.user : null;
    final firstName = user?.name.split(' ').first ?? 'there';
    final isDesktop = context.isDesktop;
    //final cartCount = context.watch<CartBloc>().state.itemCount;
    final cartCount = 0;

    final visibleCategories = _categories.length > _kLandingCategoryLimit
        ? _categories.sublist(0, _kLandingCategoryLimit)
        : _categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StorefrontTopNavBar(
        user: user,
        cartCount: cartCount,
        isDesktop: isDesktop,
        categories: _categories,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              PageContainer(
                child: Padding(
                  padding: EdgeInsets.only(top: isDesktop ? 24 : 12),
                  child:
                      _HeroCarousel(firstName: firstName, isDesktop: isDesktop),
                ),
              ),
              const SizedBox(height: 24),
              const _PerksMarquee(),
              const SizedBox(height: 32),
              PageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Shop by Category',
                      action: 'View all',
                      onTap: () => context.go('/categories'),
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No categories yet', style: AppText.body()),
                      )
                    else
                      _CategoryGrid(categories: visibleCategories),
                    const SizedBox(height: 36),
                    _SectionHeader(
                      title: 'Featured Products',
                      action: 'View all',
                      onTap: () => context.go('/products'),
                    ),
                    const SizedBox(height: 14),
                    _loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _products.isEmpty
                            ? AppUI.emptyState(
                                title: 'No products yet',
                                message:
                                    'Check back soon — new products are added regularly.',
                                icon: Icons.inventory_2_outlined,
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: context.productColumns,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.58,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (_, i) =>
                                    _ProductCard(product: _products[i] as Map),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const StorefrontFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _SectionHeader(
      {required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(title,
              style: AppText.display(size: 22, color: AppColors.textPrimary)),
        ),
        InkWell(
          onTap: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(action,
                style: AppText.bodyMd(
                    color: AppColors.accent, weight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
          ]),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// HERO CAROUSEL (3 pages, auto-slide)
// ────────────────────────────────────────────────────────────
class _HeroCarousel extends StatefulWidget {
  final String firstName;
  final bool isDesktop;
  const _HeroCarousel({required this.firstName, required this.isDesktop});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_page + 1) % 3;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.isDesktop ? 440.0 : 480.0;
    return Column(
      children: [
        SizedBox(
          height: h,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _HeroBanner(
                  firstName: widget.firstName, isDesktop: widget.isDesktop),
              _HeroImageSlide(
                isDesktop: widget.isDesktop,
                image:
                    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1600&q=80',
                pill: 'Fresh Groceries',
                title: 'Farm-fresh picks,\ndelivered daily.',
                body:
                    'Up to 30% off on fruits, veggies and pantry staples this week.',
                cta: 'Shop groceries',
              ),
              _HeroImageSlide(
                isDesktop: widget.isDesktop,
                image:
                    'https://images.unsplash.com/photo-1526738549149-8e07eca6c147?auto=format&fit=crop&w=1600&q=80',
                pill: 'Tech Deals',
                title: 'Upgrade your tech,\nnot your budget.',
                body:
                    'Big savings on phones, earbuds and everyday electronics.',
                cta: 'Shop electronics',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroImageSlide extends StatelessWidget {
  final bool isDesktop;
  final String image, pill, title, body, cta;
  const _HeroImageSlide({
    required this.isDesktop,
    required this.image,
    required this.pill,
    required this.title,
    required this.body,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.primaryDark)),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withAlpha(160), Colors.black.withAlpha(40)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isDesktop ? 36 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(pill, style: AppText.label(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: AppText.display(
                      color: Colors.white, size: isDesktop ? 40 : 28)),
              const SizedBox(height: 12),
              SizedBox(
                width: 460,
                child: Text(body,
                    style: AppText.body(color: Colors.white.withAlpha(220))),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 320 : 360),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeroCta(
                        label: cta,
                        onTap: () => context.go('/products'),
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Hero banner (page 1) ──
class _HeroBanner extends StatelessWidget {
  final String firstName;
  final bool isDesktop;
  const _HeroBanner({required this.firstName, required this.isDesktop});

  static const _tiles = [
    (Icons.shopping_cart_outlined, 'Grocery'),
    (Icons.devices_other_outlined, 'Electronics'),
    (Icons.checkroom_outlined, 'Clothing'),
    (Icons.chair_outlined, 'Home'),
    (Icons.face_retouching_natural_outlined, 'Beauty'),
    (Icons.toys_outlined, 'Toys'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: EdgeInsets.all(isDesktop ? 36 : 24),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _copy(context)),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: _tileGrid()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy(context),
                const SizedBox(height: 20),
                _tileGrid(),
              ],
            ),
    );
  }

  Widget _copy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.full)),
          child:
              Text('Summer Savings', style: AppText.label(color: Colors.white)),
        ),
        const SizedBox(height: 16),
        Text('Everyday essentials,\neveryday value.',
            style: AppText.display(
                color: Colors.white, size: isDesktop ? 40 : 28)),
        const SizedBox(height: 12),
        Text(
          'Save up to 40% across groceries, electronics, home & more. '
          'Free pickup and fast delivery.',
          style: AppText.body(color: Colors.white.withAlpha(210)),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 320 : 360),
          child: Row(
            children: [
              Expanded(
                child: _HeroCta(
                    label: 'Shop featured',
                    onTap: () => context.go('/products'),
                    compact: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroCtaOutline(
                    label: 'Browse categories',
                    onTap: () => context.go('/categories')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final t = _tiles[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.white.withAlpha(46)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.$1, size: 20, color: Colors.white.withAlpha(235)),
              const SizedBox(height: 4),
              Text(t.$2,
                  style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

// Compact-capable CTA with hover lift.
class _HeroCta extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _HeroCta(
      {required this.label, required this.onTap, this.compact = false});

  @override
  State<_HeroCta> createState() => _HeroCtaState();
}

class _HeroCtaState extends State<_HeroCta> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 38.0 : 40.0;
    final hPad = widget.compact ? 14.0 : 18.0;
    final fontSize = widget.compact ? 12.5 : 13.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          height: h,
          child: ElevatedButton(
            onPressed: widget.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: _hover ? 6 : 0,
              shadowColor: AppColors.accent.withAlpha(120),
              padding: EdgeInsets.symmetric(horizontal: hPad),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              textStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.label),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: widget.compact ? 13 : 14),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HeroCtaOutline extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HeroCtaOutline({required this.label, required this.onTap});

  @override
  State<_HeroCtaOutline> createState() => _HeroCtaOutlineState();
}

class _HeroCtaOutlineState extends State<_HeroCtaOutline> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        height: 38,
        child: OutlinedButton(
          onPressed: widget.onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: _hover ? Colors.white.withAlpha(20) : null,
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withAlpha(_hover ? 200 : 90)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full)),
            textStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// PERKS MARQUEE — auto-scrolling, pause + fade on hover.
// ────────────────────────────────────────────────────────────
class _PerksMarquee extends StatefulWidget {
  const _PerksMarquee();
  @override
  State<_PerksMarquee> createState() => _PerksMarqueeState();
}

class _PerksMarqueeState extends State<_PerksMarquee> {
  final _ctrl = ScrollController();
  Timer? _timer;
  bool _paused = false;

  static const _perks = [
    (
      Icons.local_shipping_outlined,
      'Free delivery Rs.2000+',
      'Fast to your door'
    ),
    (Icons.autorenew, '7-day returns', 'Hassle-free'),
    (Icons.verified_user_outlined, 'Secure checkout', 'Shop with confidence'),
    (Icons.sell_outlined, 'Price match', 'Everyday low prices'),
    (Icons.support_agent_outlined, '24/7 support', 'We are here to help'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || !_ctrl.hasClients || _paused) return;
      if (!_ctrl.position.hasContentDimensions) return;
      final max = _ctrl.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _ctrl.offset + 0.6;
      if (next >= max) {
        _ctrl.jumpTo(0);
      } else {
        _ctrl.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [..._perks, ..._perks, ..._perks];
    return PageContainer(
      child: ClipRect(
        child: MouseRegion(
          onEnter: (_) => _paused = true,
          onExit: (_) => _paused = false,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.03, 0.97, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: 84,
              child: ListView.separated(
                controller: _ctrl,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    SizedBox(width: 250, child: _PerkCard(perk: items[i])),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerkCard extends StatefulWidget {
  final (IconData, String, String) perk;
  const _PerkCard({required this.perk});

  @override
  State<_PerkCard> createState() => _PerkCardState();
}

class _PerkCardState extends State<_PerkCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.perk;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              Border.all(color: _hover ? AppColors.accent : AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(28), shape: BoxShape.circle),
            child: Icon(p.$1, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.$2,
                    style: AppText.bodyMd(weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(p.$3,
                    style: AppText.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// CATEGORY GRID — pastel icon-circle tiles.
// ────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final List<dynamic> categories;
  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    final cols = context.isDesktop ? 6 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final c = categories[i] as Map;
        final id = c['_id']?.toString() ?? '';
        final name = c['name']?.toString() ?? '';
        return _CategoryTile(id: id, name: name, colorIndex: i);
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String id, name;
  final int colorIndex;
  const _CategoryTile(
      {required this.id, required this.name, required this.colorIndex});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final bg = colorForCategoryIndex(widget.colorIndex);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/category/${widget.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border:
                Border.all(color: _hover ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hover ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(iconForCategory(widget.name),
                      size: 26, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd(
                      weight: FontWeight.w600,
                      color:
                          _hover ? AppColors.accent : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product card, with hover lift ──
class _ProductCard extends StatefulWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final id = product['_id']?.toString() ?? '';
    final name = product['name']?.toString() ?? '';
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final original =
        double.tryParse(product['original_price']?.toString() ?? '') ??
            double.tryParse(product['compare_at_price']?.toString() ?? '');
    final discount = (original != null && original > price)
        ? (((original - price) / original) * 100).round()
        : 0;
    final thumbnail = product['thumbnail']?.toString() ??
        ((product['images'] as List?)?.isNotEmpty == true
            ? (product['images'] as List).first.toString()
            : null);
    final ratingAvg =
        double.tryParse(product['rating_avg']?.toString() ?? '0') ?? 0;
    final ratingCount =
        int.tryParse(product['rating_count']?.toString() ?? '0') ?? 0;
    final brand = product['brand']?.toString() ??
        (product['category_id'] is Map
            ? product['category_id']['name']?.toString() ?? ''
            : '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go('/products/$id'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border:
                Border.all(color: _hover ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: AppColors.surfaceWarm,
                  child: thumbnail != null && thumbnail.isNotEmpty
                      ? AnimatedScale(
                          scale: _hover ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Image.network(thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.shopping_bag_outlined,
                                      color: AppColors.textHint, size: 40))),
                        )
                      : const Center(
                          child: Icon(Icons.shopping_bag_outlined,
                              color: AppColors.textHint, size: 40)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty)
                      Text(brand.toUpperCase(),
                          style: AppText.caption(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMd(weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (ratingCount > 0)
                      Row(children: [
                        const Icon(Icons.star,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text('${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                            style: AppText.caption()),
                      ]),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs.${price.toStringAsFixed(2)}',
                            style: AppText.h2(color: AppColors.textPrimary)),
                        if (original != null && original > price) ...[
                          const SizedBox(width: 6),
                          Text('Rs.${original.toStringAsFixed(2)}',
                              style: AppText.caption().copyWith(
                                  decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 4),
                          Text('-$discount%',
                              style: AppText.caption(color: AppColors.accent)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<CartBloc>()
                              .add(CartAddEvent(id, qty: 1));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                duration: const Duration(milliseconds: 900),
                                content: Text('Added $name to cart')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full)),
                        ),
                        child: const Text('Add to cart',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
