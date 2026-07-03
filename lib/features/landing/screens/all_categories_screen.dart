import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';
// Shared nav/footer/category-icon helpers — was duplicated locally
// before, now imported from the one shared implementation.
import '../../../shared/widgets/storefront_nav.dart';

/// Dedicated "Shop by Category" screen — reached via the landing page's
/// "View all" action and the nav bar's "All Categories" link. Uses the
/// same top nav bar and footer as the rest of the storefront so it
/// doesn't feel like a separate app.
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.instance.get('/categories');
      if (mounted) {
        setState(() {
          _categories = (r['data'] as List?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load categories';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticatedState ? auth.user : null;
    final cartState = context.watch<CartBloc>().state;
    final cartCount =
        cartState is CartLoadedState ? cartState.cart.itemCount : 0;

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
                  padding: EdgeInsets.symmetric(
                      horizontal: 0, vertical: isDesktop ? 28 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shop by Category',
                          style: AppText.display(
                              size: isDesktop ? 30 : 22,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Explore every aisle at Bathan Mart.',
                          style: AppText.body(color: AppColors.textSecondary)),
                      const SizedBox(height: 28),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: AppUI.emptyState(
                            title: _error!,
                            icon: Icons.error_outline,
                            message: 'Pull to refresh and try again.',
                          ),
                        )
                      else if (_categories.isEmpty)
                        AppUI.emptyState(
                          title: 'No categories yet',
                          icon: Icons.category_outlined,
                          message: 'Check back soon.',
                        )
                      else
                        _AllCategoriesGrid(categories: _categories),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const StorefrontFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllCategoriesGrid extends StatelessWidget {
  final List<dynamic> categories;
  const _AllCategoriesGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    final cols = context.isDesktop ? 5 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) {
        final c = categories[i] as Map;
        final id = c['_id']?.toString() ?? '';
        final name = c['name']?.toString() ?? '';
        final count = c['item_count'] ?? c['product_count'] ?? c['count'];
        return _AllCategoryCard(
            id: id, name: name, count: count, colorIndex: i);
      },
    );
  }
}

class _AllCategoryCard extends StatefulWidget {
  final String id, name;
  final dynamic count;
  final int colorIndex;
  const _AllCategoryCard({
    required this.id,
    required this.name,
    required this.count,
    required this.colorIndex,
  });

  @override
  State<_AllCategoryCard> createState() => _AllCategoryCardState();
}

class _AllCategoryCardState extends State<_AllCategoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = colorForCategoryIndex(widget.colorIndex);
    final n = widget.count is int
        ? widget.count as int
        : int.tryParse(widget.count?.toString() ?? '');
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/category/${widget.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border:
                Border.all(color: _hover ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(24),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hover ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(iconForCategory(widget.name),
                      size: 30, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd(
                      weight: FontWeight.w700,
                      color:
                          _hover ? AppColors.accent : AppColors.textPrimary)),
              if (n != null) ...[
                const SizedBox(height: 4),
                Text('$n item${n == 1 ? '' : 's'}', style: AppText.caption()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
