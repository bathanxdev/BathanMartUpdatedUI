import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _products = [], _categories = [];
  bool _loading = true;

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
          .get('/products', params: {'limit': '12', 'sort': 'sold_count'});
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text('Bathan Mart'),
              actions: [
                if (user?.isStaff == true || user?.isAdmin == true)
                  IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: () => context.go('/admin-home')),
                IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {}),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// HERO SECTION
              Container(
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                padding: EdgeInsets.fromLTRB(
                    context.pagePadding, 24, context.pagePadding, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello, $firstName! 👋",
                            style: AppText.display(
                                color: Colors.white,
                                size: isDesktop ? 32 : 26)),
                        const SizedBox(height: 6),
                        Text("What are you looking for today?",
                            style: AppText.body(
                                color: Colors.white.withAlpha(200))),
                        const SizedBox(height: 20),

                        /// Search Bar
                        GestureDetector(
                          onTap: () => context.go('/products'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search),
                                const SizedBox(width: 10),
                                Expanded(child: Text("Search products...")),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Categories
                        if (!_loading && _categories.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categories.take(6).map((c) {
                                final name = c['name']?.toString() ?? '';
                                return GestureDetector(
                                  onTap: () =>
                                      context.go('/products?search=$name'),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              /// PRODUCTS
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppUI.sectionHeader('Featured Products',
                            action: 'View all',
                            onAction: () => context.go('/products')),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.productColumns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (_, i) {
                            final p = _products[i] as Map;
                            final id = p['_id'] ?? '';
                            final name = p['name'] ?? '';
                            final price = p['price']?.toString() ?? '0';

                            return GestureDetector(
                              onTap: () => context.go('/products/$id'),
                              child: Container(
                                decoration: AppUI.cardDecoration(),
                                child: Column(
                                  children: [
                                    Expanded(
                                        child: Container(color: Colors.grey)),
                                    Text(name.toString()),
                                    Text("Rs.$price"),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
