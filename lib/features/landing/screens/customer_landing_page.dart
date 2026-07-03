import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../products/bloc/product_bloc.dart';
import '../../../core/api/api_client.dart';

class CustomerLandingPage extends StatefulWidget {
  const CustomerLandingPage({super.key});
  @override
  State<CustomerLandingPage> createState() => _CustomerLandingPageState();
}

class _CustomerLandingPageState extends State<CustomerLandingPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductLoadListEvent(page: 1));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isLoggedIn = auth is AuthAuthenticatedState;
    final user = isLoggedIn ? (auth as AuthAuthenticatedState).user : null;
    final firstName = user?.name.split(' ').first ?? '';
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      appBar: isDesktop ? null : _mobileAppBar(context, isLoggedIn, user),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // LayoutBuilder gives us bounded constraints — safe to use here
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _DesktopNav(isLoggedIn: isLoggedIn, user: user),
                isDesktop
                    ? _DesktopHero(isLoggedIn: isLoggedIn, firstName: firstName)
                    : _MobileHero(isLoggedIn: isLoggedIn, firstName: firstName),
                _CategoryStrip(),
                _FeaturedProducts(isDesktop: isDesktop),
                _FeaturesSection(isDesktop: isDesktop),
                _DeliveryTiers(isDesktop: isDesktop),
                _CTABanner(isDesktop: isDesktop, isLoggedIn: isLoggedIn),
                _Footer(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _mobileAppBar(
      BuildContext context, bool isLoggedIn, dynamic user) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.local_mall_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        const Text('Bathan Mart',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ]),
      actions: [
        if (!isLoggedIn)
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/home'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent,
                child: Text(
                  (user?.name.isNotEmpty == true ? user.name[0] : 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Desktop Nav  (KEY FIX: uses Row with IntrinsicHeight, no Center)
// ─────────────────────────────────────────────────────────────
class _DesktopNav extends StatelessWidget {
  final bool isLoggedIn;
  final dynamic user;
  const _DesktopNav({required this.isLoggedIn, this.user});

  @override
  Widget build(BuildContext context) {
    // crossAxisAlignment.stretch ensures Container fills screen width
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      child: Row(
        // No Spacer problems — we use mainAxisAlignment spaceBetween
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Logo ──────────────────────────────────────
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_mall_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Bathan Mart',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
          ]),

          // ── Nav links + Auth buttons ───────────────────
          Row(mainAxisSize: MainAxisSize.min, children: [
            _link(context, 'Products', '/products'),
            const SizedBox(width: 28),
            _link(context, 'Local', '/products?origin=domestic'),
            const SizedBox(width: 28),
            _link(context, 'Imported', '/products?origin=international'),
            const SizedBox(width: 36),
            if (!isLoggedIn) ...[
              // Wrap each button in IntrinsicWidth so it sizes to its label
              IntrinsicWidth(
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent),
                  child: const Text('Get Started'),
                ),
              ),
            ] else
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      (user?.name.isNotEmpty == true ? user.name[0] : 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(user?.name.split(' ').first ?? '',
                      style: const TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w500)),
                ]),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, String route) =>
      GestureDetector(
        onTap: () => context.go(route),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
      );
}

// ─────────────────────────────────────────────────────────────
// Desktop Hero
// ─────────────────────────────────────────────────────────────
class _DesktopHero extends StatelessWidget {
  final bool isLoggedIn;
  final String firstName;
  const _DesktopHero({required this.isLoggedIn, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left
          Expanded(
            flex: 6,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (firstName.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withAlpha(60)),
                  ),
                  child: Text('👋 Welcome back, $firstName!',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                const SizedBox(height: 20),
              ],
              const Text('Shop Local.\nShop Global.\nDelivered Fast.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1.5)),
              const SizedBox(height: 20),
              Text(
                  'Artisan foods, handloom textiles, organic wellness\nand curated international imports.',
                  style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 17,
                      height: 1.6)),
              const SizedBox(height: 36),
              // Buttons — IntrinsicWidth prevents infinite-width crash
              Row(mainAxisSize: MainAxisSize.min, children: [
                IntrinsicWidth(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Browse Products',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                IntrinsicWidth(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.go(isLoggedIn ? '/home' : '/register'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLoggedIn ? 'My Account' : 'Create Account'),
                  ),
                ),
              ]),
              const SizedBox(height: 40),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _stat('10K+', 'Customers'),
                const SizedBox(width: 32),
                _stat('500+', 'Artisans'),
                const SizedBox(width: 32),
                _stat('30 min', 'Express'),
              ]),
            ]),
          ),
          const SizedBox(width: 80),
          // Right — delivery cards
          Expanded(
            flex: 4,
            child: Column(children: [
              _deliveryCard('⚡', 'Express', '30 min – 2 hr',
                  'From MFDC micro-fulfilment centres', AppColors.success),
              const SizedBox(height: 16),
              _deliveryCard('🚚', 'Same-Day', 'By evening',
                  'City delivery from Local Warehouses', AppColors.info),
              const SizedBox(height: 16),
              _deliveryCard('📦', 'Standard', '2–5 days',
                  'Nationwide from Central Warehouse', AppColors.primary),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _stat(String n, String l) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n,
            style: TextStyle(
                color: AppColors.accent,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(l, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]);

  Widget _deliveryCard(
      String emoji, String title, String subtitle, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12)),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          Text(subtitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          Text(detail,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile Hero
// ─────────────────────────────────────────────────────────────
class _MobileHero extends StatelessWidget {
  final bool isLoggedIn;
  final String firstName;
  const _MobileHero({required this.isLoggedIn, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (firstName.isNotEmpty) ...[
          Text('👋 Welcome back, $firstName!',
              style: TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
        const Text('Shop Local.\nShop Global.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -1)),
        const SizedBox(height: 12),
        Text(
            'Artisan foods, textiles and international imports delivered fast.',
            style: TextStyle(
                color: Colors.white.withAlpha(180), fontSize: 15, height: 1.5)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Browse All Products'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(isLoggedIn ? '/home' : '/register'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isLoggedIn ? 'My Account' : 'Create Account'),
          ),
        ),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('10K+', 'Customers'),
          Container(width: 1, height: 32, color: Colors.white24),
          _stat('500+', 'Artisans'),
          Container(width: 1, height: 32, color: Colors.white24),
          _stat('30min', 'Express'),
        ]),
      ]),
    );
  }

  Widget _stat(String n, String l) => Column(children: [
        Text(n,
            style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]);
}

// ─────────────────────────────────────────────────────────────
// Category Strip
// ─────────────────────────────────────────────────────────────
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip();

  @override
  Widget build(BuildContext context) {
    final cats = [
      (Icons.grain_rounded, 'Food & Grocery', '/products?category=food'),
      (Icons.checkroom_rounded, 'Textiles', '/products?category=textiles'),
      (Icons.spa_rounded, 'Wellness', '/products?category=wellness'),
      (Icons.public_rounded, 'Imported', '/products?origin=international'),
      (Icons.emoji_nature_rounded, 'Organic', '/products?category=organic'),
      (
        Icons.devices_other_rounded,
        'Accessories',
        '/products?category=accessories'
      ),
    ];
    return Container(
      color: Colors.white,
      padding:
          EdgeInsets.symmetric(vertical: 20, horizontal: context.pagePadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cats
              .map((c) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => context.go(c.$3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EE),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(c.$1, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(c.$2, style: AppText.bodyMd()),
                        ]),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Featured Products
// ─────────────────────────────────────────────────────────────
class _FeaturedProducts extends StatelessWidget {
  final bool isDesktop;
  const _FeaturedProducts({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F3EE),
      padding:
          EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Featured Products',
                style: AppText.display(size: isDesktop ? 32 : 24)),
            const SizedBox(height: 4),
            Text('Handpicked by our team', style: AppText.body()),
          ]),
          TextButton.icon(
            onPressed: () => context.go('/products'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('View All'),
          ),
        ]),
        const SizedBox(height: 28),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (ctx, state) {
            if (state is ProductLoadingState) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }
            if (state is! ProductListLoaded || state.products.isEmpty) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No products yet', style: AppText.body()),
              ));
            }
            final featured = state.products.take(8).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: featured.length,
              itemBuilder: (_, i) {
                final p = featured[i];
                final id = p.id.toString();
                final name = p.name.toString();
                final price = p.price.toString();
                final isImp = p.originType == 'international';
                final avail = (p.totalAvailable ?? 0) as int;
                return _ProductCard(
                  id: id,
                  name: name,
                  price: price,
                  isImported: isImp,
                  available: avail,
                  thumbnail: p.thumbnail,
                );
              },
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final String id, name, price;
  final bool isImported;
  final int available;
  final String? thumbnail;
  const _ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.isImported,
    required this.available,
    this.thumbnail,
  });
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _wishlisted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products/${widget.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Stack(children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F3EE),
              child: widget.thumbnail != null && widget.thumbnail!.isNotEmpty
                  ? Image.network(
                      '${ApiClient.instance.mediaBaseUrl}${widget.thumbnail}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(widget.isImported ? '🌏' : '🏪',
                              style: const TextStyle(fontSize: 48))),
                    )
                  : Center(
                      child: Text(widget.isImported ? '🌏' : '🏪',
                          style: const TextStyle(fontSize: 48))),
            ),
            if (widget.isImported)
              Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Import',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  )),
            Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _wishlisted = !_wishlisted),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(20), blurRadius: 8)
                        ]),
                    child: Icon(
                      _wishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: _wishlisted ? Colors.red : AppColors.textHint,
                    ),
                  ),
                )),
            if (widget.available == 0)
              Positioned.fill(
                  child: Container(
                color: Colors.white.withAlpha(160),
                child: Center(
                    child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Out of Stock',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                )),
              )),
          ])),
          Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name,
                  style: AppText.bodyMd(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Rs.${widget.price}', style: AppText.price(size: 15)),
                  if (widget.available > 0)
                    Text('${widget.available} left',
                        style: TextStyle(
                            color: widget.available < 10
                                ? AppColors.warning
                                : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                ]),
                if (widget.available > 0)
                  GestureDetector(
                    onTap: () {
                      context
                          .read<CartBloc>()
                          .add(CartAddEvent(widget.id, qty: 1));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${widget.name} added'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                            label: 'Cart',
                            onPressed: () => context.go('/cart'),
                            textColor: Colors.white),
                      ));
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10)),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Features Section
// ─────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  final bool isDesktop;
  const _FeaturesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.storefront_outlined,
        AppColors.primary,
        'Local Artisans',
        'Products sourced directly from artisans and farmers across India.'
      ),
      (
        Icons.public_outlined,
        AppColors.info,
        'Global Imports',
        'Curated international products delivered to your door.'
      ),
      (
        Icons.bolt_outlined,
        AppColors.success,
        'Express Delivery',
        '30 min delivery from MFDC micro-fulfilment centres.'
      ),
      (
        Icons.repeat_outlined,
        AppColors.accent,
        'Auto Reorder',
        'Set subscriptions and orders placed automatically.'
      ),
      (
        Icons.verified_outlined,
        AppColors.teal,
        'Quality Assured',
        'Every supplier KYC-verified with tracked quality scores.'
      ),
    ];
    return Container(
      color: Colors.white,
      padding:
          EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 56),
      child: Column(children: [
        Text('Why shop with Bathan Mart?',
            style: AppText.display(size: isDesktop ? 34 : 26),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Directly connecting you with local artisans and global suppliers',
            style: AppText.body(), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        isDesktop
            ? Row(
                children: items
                    .map((e) => Expanded(
                        child: _FeatureCard(
                            icon: e.$1, color: e.$2, title: e.$3, desc: e.$4)))
                    .toList())
            : Column(
                children: items
                    .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeatureCard(
                            icon: e.$1, color: e.$2, title: e.$3, desc: e.$4)))
                    .toList()),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _FeatureCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.desc});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 14),
          Text(title, style: AppText.h3()),
          const SizedBox(height: 6),
          Text(desc, style: AppText.body()),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Delivery Tiers
// ─────────────────────────────────────────────────────────────
class _DeliveryTiers extends StatelessWidget {
  final bool isDesktop;
  const _DeliveryTiers({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final tiers = [
      (
        '⚡',
        'Express',
        '30 min – 2 hours',
        'From MFDC micro-fulfilment centres near you',
        AppColors.success
      ),
      (
        '🚚',
        'Same-Day',
        'By evening',
        'City delivery from our Local Warehouses',
        AppColors.info
      ),
      (
        '📦',
        'Standard',
        '2–5 business days',
        'Nationwide from Central Warehouse',
        AppColors.primary
      ),
    ];
    return Container(
      color: const Color(0xFFF5F3EE),
      padding:
          EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 52),
      child: Column(children: [
        Text('Choose Your Delivery Speed',
            style: AppText.display(size: isDesktop ? 32 : 24),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),
        isDesktop
            ? Row(
                children: tiers
                    .map((t) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _TierCard(
                                emoji: t.$1,
                                title: t.$2,
                                time: t.$3,
                                detail: t.$4,
                                color: t.$5))))
                    .toList())
            : Column(
                children: tiers
                    .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TierCard(
                            emoji: t.$1,
                            title: t.$2,
                            time: t.$3,
                            detail: t.$4,
                            color: t.$5)))
                    .toList()),
      ]),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String emoji, title, time, detail;
  final Color color;
  const _TierCard(
      {required this.emoji,
      required this.title,
      required this.time,
      required this.detail,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50)),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(15),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(children: [
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: color.withAlpha(18), shape: BoxShape.circle),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 32)))),
          const SizedBox(height: 16),
          Text(title, style: AppText.h2(color: color)),
          const SizedBox(height: 4),
          Text(time,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(detail, style: AppText.caption(), textAlign: TextAlign.center),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// CTA Banner
// ─────────────────────────────────────────────────────────────
class _CTABanner extends StatelessWidget {
  final bool isDesktop;
  final bool isLoggedIn;
  const _CTABanner({required this.isDesktop, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 32),
      padding: EdgeInsets.all(isDesktop ? 56 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(children: [
        Text('Ready to start shopping?',
            style:
                AppText.display(color: Colors.white, size: isDesktop ? 34 : 26),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Join thousands of happy customers across India.',
            style: AppText.body(color: Colors.white.withAlpha(180)),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        if (isDesktop)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IntrinsicWidth(
                child: ElevatedButton(
              onPressed: () => context.go('/products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(160, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Browse Products'),
            )),
            const SizedBox(width: 16),
            IntrinsicWidth(
                child: OutlinedButton(
              onPressed: () => context.go(isLoggedIn ? '/home' : '/register'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isLoggedIn ? 'My Account' : 'Create Account'),
            )),
          ])
        else ...[
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse Products'),
              )),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(isLoggedIn ? '/home' : '/register'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isLoggedIn ? 'My Account' : 'Create Account'),
              )),
        ],
        if (!isLoggedIn) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Have an account? ',
                style: AppText.body(color: Colors.white.withAlpha(180))),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text('Sign In',
                  style: AppText.body(
                      color: Colors.white, weight: FontWeight.w700)),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Staff: ', style: AppText.caption()),
        GestureDetector(
            onTap: () => context.go('/login'),
            child: Text('Admin Portal',
                style: AppText.caption(color: AppColors.primary))),
        Text('  •  ', style: AppText.caption()),
        GestureDetector(
            onTap: () => context.go('/rider-intro'),
            child: Text('Become a Rider',
                style: AppText.caption(color: AppColors.primary))),
      ]),
    );
  }
}
