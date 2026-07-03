import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override State<OrderDetailScreen> createState() =>
      _OrderDetailScreenState();
}
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override void initState() {
    super.initState();
    context.read<OrderBloc>()
        .add(OrderLoadDetailEvent(widget.orderId));
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'delivered':         return AppColors.success;
      case 'cancelled':         return AppColors.error;
      case 'out_for_delivery':  return AppColors.info;
      case 'dispatched':        return AppColors.secondary;
      default:                  return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<OrderBloc>()
                .add(OrderLoadDetailEvent(widget.orderId)),
          ),
        ],
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (ctx, state) {
          if (state is OrderLoadingState)
            return const Center(
                child: CircularProgressIndicator());
          if (state is OrderErrorState)
            return AppUI.emptyState(
              title: 'Could not load order',
              message: state.message,
              icon: Icons.error_outline,
              btnLabel: 'Retry',
              onBtn: () => ctx.read<OrderBloc>()
                  .add(OrderLoadDetailEvent(widget.orderId)));
          if (state is! OrderDetailLoaded)
            return const SizedBox.shrink();

          final o   = state.order;
          final col = _statusColor(o.status);
          final dt  = DateFormat('dd MMM yyyy, hh:mm a')
              .format(o.createdAt);
          final shortId = o.id.substring(
              0, o.id.length > 12 ? 12 : o.id.length)
              .toUpperCase();

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Order header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [col.withAlpha(20), col.withAlpha(8)]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: col.withAlpha(60))),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('#$shortId',
                      style: AppText.h2(color: col)),
                  const SizedBox(height: 4),
                  Text(dt, style: AppText.caption()),
                  const SizedBox(height: 8),
                  AppUI.badge(o.status ?? 'confirmed', col),
                ])),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                  Text('Rs.${o.totalAmount.toStringAsFixed(2)}',
                      style: AppText.price(
                          size: 22, color: col)),
                  const SizedBox(height: 4),
                  Text('${o.items.length} item${o.items.length > 1 ? 's' : ''}',
                      style: AppText.caption()),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: o.id));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Order ID copied')));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      const Icon(Icons.copy, size: 12,
                          color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('Copy ID',
                          style: AppText.caption()),
                    ]),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Status stepper
            if (o.status != 'cancelled') ...[
              Text('Delivery Progress', style: AppText.h3()),
              const SizedBox(height: 12),
              OrderStatusStepper(currentStatus: o.status ?? 'confirmed'),
              const SizedBox(height: 20),
            ],

            // Items
            Text('Items Ordered', style: AppText.h3()),
            const SizedBox(height: 10),
            ...o.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppUI.cardDecoration(),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm)),
                  child: const Center(child: Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textHint, size: 24))),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(item.productName ?? 'Product',
                      style: AppText.bodyMd()),
                  Text('Qty: ${item.qty}  ×  Rs.${item.unitPrice.toStringAsFixed(0)}',
                      style: AppText.caption()),
                ])),
                Text('Rs.${item.lineTotal.toStringAsFixed(0)}',
                    style: AppText.h3(
                        color: AppColors.primary)),
              ]),
            )),
            const SizedBox(height: 20),

            // Delivery address
            Text('Delivery Address', style: AppText.h3()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppUI.cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  if (o.deliveryAddress != null) ...[
                    if (o.deliveryAddress!['name'] != null)
                      Text(o.deliveryAddress!['name'].toString(),
                          style: AppText.bodyMd()),
                    Text([
                      o.deliveryAddress!['line1'],
                      o.deliveryAddress!['city'],
                      o.deliveryAddress!['state'],
                      o.deliveryAddress!['pincode'],
                    ].where((e) => e != null && e.toString().isNotEmpty)
                        .join(', '),
                        style: AppText.body()),
                  ] else
                    Text('Address not available',
                        style: AppText.caption()),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // Payment & pricing
            Text('Payment', style: AppText.h3()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppUI.cardDecoration(),
              child: Column(children: [
                _priceRow('Subtotal',
                    'Rs.${o.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _priceRow('Delivery fee',
                    'Rs.${o.deliveryFee.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _priceRow('Total',
                    'Rs.${o.totalAmount.toStringAsFixed(2)}',
                    bold: true),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.payment_outlined,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(o.paymentMethod ?? 'COD',
                      style: AppText.caption()),
                  const SizedBox(width: 8),
                  AppUI.badge(
                    o.paymentStatus ?? 'pending',
                    o.paymentStatus == 'paid'
                        ? AppColors.success : AppColors.warning),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Cancel button
            if (o.status == 'confirmed' ||
                o.status == 'picking') ...[
              AppButton(
                label: 'Cancel Order', danger: true,
                outlined: true,
                icon: Icons.cancel_outlined,
                onPressed: () => _confirmCancel(ctx, o.id)),
              const SizedBox(height: 8),
            ],

            AppButton(
              label: 'Back to Orders', outlined: true,
              icon: Icons.arrow_back_outlined,
              onPressed: () => ctx.go('/orders')),
            const SizedBox(height: 32),
          ]);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              padding: EdgeInsets.symmetric(
                  horizontal: context.pagePadding, vertical: 20),
              child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Expanded(flex: 3, child: content),
                    const SizedBox(width: 32),
                    const SizedBox(width: 300),
                  ])
                : content,
            ),
          );
        },
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool bold = false}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
      Text(label, style: bold ? AppText.h3() : AppText.body()),
      Text(value, style: bold
          ? AppText.h3(color: AppColors.primary)
          : AppText.bodyMd()),
    ]);

  void _confirmCancel(BuildContext ctx, String id) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: const Text('Cancel Order'),
      content: const Text(
          'Are you sure? This cannot be undone and your cart items will be released back to stock.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order')),
        ElevatedButton(
          onPressed: () {
            ctx.read<OrderBloc>().add(OrderCancelEvent(id));
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error),
          child: const Text('Cancel Order')),
      ],
    ));
  }
}
