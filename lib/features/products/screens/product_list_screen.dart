import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId, search, originType;
  const ProductListScreen({super.key, this.categoryId, this.search, this.originType});
  @override State<ProductListScreen> createState() => _ProductListScreenState();
}
class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  String? _origin;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    if (widget.search != null) _searchCtrl.text = widget.search!;
    _origin = widget.originType;
    _load();
  }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() => context.read<ProductBloc>().add(ProductLoadListEvent(
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      categoryId: widget.categoryId, originType: _origin, page: _page));

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(title: const Text('Products')),
      body: Column(children: [
        // ── Filter bar ──────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: PageContainer(
            padding: EdgeInsets.symmetric(
                horizontal: context.pagePadding, vertical: 12),
            child: Column(children: [
              if (isDesktop)
                Row(children: [
                  Expanded(child: _buildSearchBar(ctrl: _searchCtrl, onSearch: () { setState(()=>_page=1); _load(); })),
                  const SizedBox(width: 16),
                  _buildFilterChip('All',        null),
                  const SizedBox(width: 8),
                  _buildFilterChip('🏠 Local',   'domestic'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🌏 Imported','international'),
                ]) else Column(children: [
                  _buildSearchBar(ctrl: _searchCtrl, onSearch: () { setState(()=>_page=1); _load(); }),
                  const SizedBox(height: 10),
                  Row(children: [
                    _buildFilterChip('All',      null),
                    const SizedBox(width: 8),
                    _buildFilterChip('🏠 Local', 'domestic'),
                    const SizedBox(width: 8),
                    _buildFilterChip('🌏 Import','international'),
                  ]),
                ]),
            ]),
          ),
        ),
        // ── Results ─────────────────────────────────────────
        Expanded(child: BlocBuilder<ProductBloc, ProductState>(
          builder: (ctx, state) {
            if (state is ProductLoadingState)
              return const Center(child: CircularProgressIndicator());
            if (state is ProductErrorState)
              return Center(child: Text(state.message));
            if (state is! ProductListLoaded || state.products.isEmpty)
              return AppUI.emptyState(title: 'No products found',
                  icon: Icons.inventory_2_outlined,
                  message: 'Try adjusting your filters or search terms');

            return PageContainer(
              padding: EdgeInsets.symmetric(
                  horizontal: context.pagePadding, vertical: 20),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.productColumns,
                    mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75),
                itemCount: state.products.length,
                itemBuilder: (_, i) {
                  final p = state.products[i];
                  final id    = p.id.toString() ?? '';
                  final name  = p.name.toString() ?? '';
                  final price = p.price.toString() ?? '0';
                  final isImp = p.originType == 'international';
                  final avail = (p.totalAvailable ?? 0) as int;
                  return GestureDetector(
                    onTap: () => context.go('/products/$id'),
                    child: Container(
                      decoration: AppUI.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Stack(children: [
                          Container(width: double.infinity, color: AppColors.surfaceWarm,
                            child: Center(child: Text(isImp ? '🌏' : '🏠',
                                style: const TextStyle(fontSize: 40)))),
                          if (isImp) Positioned(top: 8, left: 8,
                              child: AppUI.badge('Import', AppColors.info)),
                          if (avail == 0) Positioned.fill(child: Container(
                            color: Colors.white.withAlpha(160),
                            child: Center(child: AppUI.badge('Out of Stock', AppColors.textHint)))),
                        ])),
                        Padding(padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: AppText.bodyMd(),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Rs.$price', style: AppText.price(size: 16)),
                              if (avail > 0)
                                GestureDetector(
                                  onTap: () {
                                    ctx.read<CartBloc>().add(CartAddEvent(id, qty: 1));
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('$name added'),
                                      backgroundColor: AppColors.success,
                                      action: SnackBarAction(label: 'Cart',
                                          onPressed: () => context.go('/cart'),
                                          textColor: Colors.white)));
                                  },
                                  child: Container(width: 30, height: 30,
                                    decoration: BoxDecoration(color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(AppRadius.md)),
                                    child: const Icon(Icons.add, color: Colors.white, size: 18))),
                            ]),
                          ])),
                      ]),
                    ),
                  );
                },
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _buildFilterChip(String label, String? val) => ChoiceChip(
    label: Text(label), selected: _origin == val,
    onSelected: (_) { setState(() { _origin = val; _page = 1; }); _load(); },
  );

  Widget _buildSearchBar({required TextEditingController ctrl, required VoidCallback onSearch}) =>
    TextField(
      controller: ctrl,
      onSubmitted: (_) => onSearch(),
      style: AppText.bodyMd(),
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
        suffixIcon: IconButton(icon: const Icon(Icons.search, size: 18),
            onPressed: onSearch),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        filled: true, fillColor: AppColors.surfaceWarm,
      ),
    );
}
