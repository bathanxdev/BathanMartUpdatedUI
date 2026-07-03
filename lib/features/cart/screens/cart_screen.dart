import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/cart_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  @override void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        title: const Text('My Cart'),
        actions: [
          BlocBuilder<CartBloc, CartState>(builder: (ctx, s) =>
            s is CartLoadedState && s.cart.itemCount > 0
              ? TextButton(
                  onPressed: () => _confirmClear(ctx),
                  child: Text('Clear all',
                      style: AppText.label(color: AppColors.error)))
              : const SizedBox.shrink()),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(builder: (ctx, state) {
        if (state is CartLoadingState)
          return const Center(child: CircularProgressIndicator());
        if (state is! CartLoadedState || state.cart.items.isEmpty)
          return AppUI.emptyState(
            title: 'Your cart is empty',
            message: 'Add some amazing local and imported products!',
            icon: Icons.shopping_bag_outlined,
            btnLabel: 'Browse Products',
            onBtn: () => ctx.go('/products'),
          );

        final cart = state.cart;
        final fmt  = NumberFormat('#,##0.00');

        return isDesktop
          ? _DesktopCartLayout(cart: cart, fmt: fmt)
          : _MobileCartLayout(cart: cart, fmt: fmt);
      }),
    );
  }

  void _confirmClear(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: const Text('Clear Cart'),
      content: const Text(
          'Remove all items from your cart?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            ctx.read<CartBloc>().add(const CartClearEvent());
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error),
          child: const Text('Clear All'),
        ),
      ],
    ));
  }
}

// ── Mobile layout ──────────────────────────────────────────────
class _MobileCartLayout extends StatelessWidget {
  final dynamic cart;
  final NumberFormat fmt;
  const _MobileCartLayout({required this.cart, required this.fmt});

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) =>
          _CartItemCard(item: cart.items[i], fmt: fmt),
    )),
    _CartSummary(cart: cart, fmt: fmt),
  ]);
}

// ── Desktop layout — side by side ─────────────────────────────
class _DesktopCartLayout extends StatelessWidget {
  final dynamic cart;
  final NumberFormat fmt;
  const _DesktopCartLayout({required this.cart, required this.fmt});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PageContainer(
      padding: EdgeInsets.symmetric(
          horizontal: context.pagePadding, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — items
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shopping Cart (${cart.itemCount} items)',
                  style: AppText.h1()),
              const SizedBox(height: 20),
              ...List.generate(cart.items.length, (i) =>
                Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: _CartItemCard(item: cart.items[i], fmt: fmt))),
            ],
          )),
          const SizedBox(width: 28),
          // Right — summary (sticky)
          SizedBox(width: 340,
              child: _CartSummary(cart: cart, fmt: fmt, isCard: true)),
        ],
      ),
    ),
  );
}

// ── Cart item card ─────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final NumberFormat fmt;
  const _CartItemCard({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final lineTotal = (item.price * item.qty);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppUI.cardDecoration(),
      child: Row(children: [
        // Product image placeholder
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Center(child: Text(
            item.name.contains('Import') ? '🌏' : '🏠',
            style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(item.name, style: AppText.bodyMd(),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Rs.${item.price.toStringAsFixed(0)} each',
              style: AppText.caption()),
          const SizedBox(height: 8),
          Row(children: [
            Text('Total: Rs.${fmt.format(lineTotal)}',
                style: AppText.h3(color: AppColors.primary)),
          ]),
        ])),
        const SizedBox(width: 10),
        // Qty stepper
        Column(children: [
          _qBtn(context, Icons.add,
            () => context.read<CartBloc>().add(
                CartUpdateEvent(item.skuId, item.qty + 1))),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Center(child: Text(item.qty.toString(),
                style: AppText.h3()))),
          _qBtn(context, Icons.remove,
            () => context.read<CartBloc>().add(
                CartUpdateEvent(item.skuId, item.qty - 1)),
            danger: item.qty <= 1),
        ]),
      ]),
    );
  }

  Widget _qBtn(BuildContext ctx, IconData icon,
      VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: danger
              ? AppColors.errorSoft : AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 16,
            color: danger ? AppColors.error : AppColors.primary)),
    );
  }
}

// ── Cart summary panel ─────────────────────────────────────────
class _CartSummary extends StatelessWidget {
  final dynamic cart;
  final NumberFormat fmt;
  final bool isCard;
  const _CartSummary(
      {required this.cart, required this.fmt, this.isCard = false});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      if (isCard) ...[
        Text('Order Summary', style: AppText.h2()),
        const SizedBox(height: 16),
      ],
      _row('Subtotal (${cart.itemCount} items)',
          'Rs.${fmt.format(cart.subtotal)}'),
      const SizedBox(height: 8),
      _row('Delivery fee', 'Calculated at checkout',
          valueStyle: AppText.caption(color: AppColors.textHint)),
      const SizedBox(height: 8),
      _row('Discount', '— Rs.0.00',
          valueStyle: AppText.caption(color: AppColors.success)),
      const Divider(height: 24),
      _row('Estimated Total',
          'Rs.${fmt.format(cart.subtotal)}',
          bold: true),
      const SizedBox(height: 20),
      AppButton(
        label: 'Proceed to Checkout',
        icon: Icons.arrow_forward_outlined,
        onPressed: () => context.go('/checkout'),
      ),
      const SizedBox(height: 12),
      AppButton(
        label: 'Continue Shopping',
        outlined: true,
        onPressed: () => context.go('/products'),
      ),
    ]);

    if (!isCard) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(
              color: Colors.black12, blurRadius: 16,
              offset: Offset(0, -4))]),
        child: content);
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppUI.cardDecoration(elevated: true),
      child: content);
  }

  Widget _row(String label, String value,
      {bool bold = false, TextStyle? valueStyle}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: bold ? AppText.h3() : AppText.body()),
      Text(value, style: valueStyle ?? (bold
          ? AppText.h3(color: AppColors.primary)
          : AppText.bodyMd())),
    ]);
}
