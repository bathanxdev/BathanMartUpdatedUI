import 'package:bathanmart/features/admin/widgets/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadDetailEvent(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {})
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (ctx, state) {
          if (state is ProductLoadingState)
            return const Center(child: CircularProgressIndicator());
          if (state is ProductErrorState)
            return Center(child: Text(state.message));
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          final p = state.product;

          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        height: 260,
                        width: double.infinity,
                        color: AppColors.surface,
                        child: p.images.isNotEmpty
                            ? Image.network(
                                '${ApiClient.instance.mediaBaseUrl}${p.images.first}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.inventory_2_outlined,
                                        size: 80, color: AppColors.textHint)))
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined,
                                    size: 80, color: AppColors.textHint)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tags
                              Wrap(spacing: 8, children: [
                                if (p.isImported)
                                  const Chip(
                                      label: Text('🌏 Imported',
                                          style: TextStyle(fontSize: 11))),
                                if (p.categoryName != null)
                                  Chip(
                                      label: Text(p.categoryName!,
                                          style:
                                              const TextStyle(fontSize: 11))),
                              ]),
                              const SizedBox(height: 12),
                              Text(p.name,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              if (p.skuCode != null)
                                Text('SKU: ${p.skuCode}',
                                    style: Theme.of(ctx).textTheme.bodySmall),
                              const SizedBox(height: 12),
                              Text('Rs.${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                              // Fix: p.unit is String? so use ?? 'piece'
                              Text("per ${p.unit ?? 'piece'}",
                                  style: Theme.of(ctx).textTheme.bodySmall),
                              const SizedBox(height: 20),
                              // Stock by tier
                              if (p.stockByTier.isNotEmpty) ...[
                                Text('Delivery Options',
                                    style: Theme.of(ctx).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ...p.stockByTier
                                    .where((s) => s.qtyAvailable > 0)
                                    .map((s) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          leading: DeliveryTierBadge(
                                              tier: s.warehouseType ?? 'MCW'),
                                          title: Text(s.warehouseName ?? '',
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          trailing: Text(
                                              '${s.qtyAvailable} in stock',
                                              style: const TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 12)),
                                        )),
                                const SizedBox(height: 12),
                              ],
                              // Description
                              if (p.description != null) ...[
                                Text('About this product',
                                    style: Theme.of(ctx).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(p.description!,
                                    style: Theme.of(ctx).textTheme.bodyMedium),
                              ],
                            ]),
                      ),
                    ]),
              ),
            ),
            // Add to cart bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ]),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          if (_qty > 1) setState(() => _qty--);
                        }),
                    Text(_qty.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _qty++)),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Add to Cart',
                    icon: Icons.shopping_cart_outlined,
                    onPressed: p.inStock
                        ? () {
                            ctx
                                .read<CartBloc>()
                                .add(CartAddEvent(p.id, qty: _qty));
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('\${p.name} added'),
                              backgroundColor: AppColors.success,
                              action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () => ctx.go('/cart'),
                                  textColor: Colors.white),
                            ));
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: p.inStock
                      ? () => ctx.go('/subscriptions/create', extra: p.id)
                      : null,
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Icon(Icons.repeat),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
