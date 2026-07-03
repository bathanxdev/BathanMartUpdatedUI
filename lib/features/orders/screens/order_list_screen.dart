import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override State<OrderListScreen> createState() =>
      _OrderListScreenState();
}
class _OrderListScreenState extends State<OrderListScreen> {
  String? _filter;
  static const _statuses = [
    (null,              'All'),
    ('confirmed',       'Confirmed'),
    ('picking',         'Picking'),
    ('packed',          'Packed'),
    ('dispatched',      'Dispatched'),
    ('out_for_delivery','On the Way'),
    ('delivered',       'Delivered'),
    ('cancelled',       'Cancelled'),
  ];

  @override void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderLoadListEvent(status: _filter));
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
      appBar: isDesktop ? null : AppBar(
        title: const Text('My Orders')),
      body: Column(children: [
        // Status filter chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final sel = _filter == s.$1;
                return ChoiceChip(
                  label: Text(s.$2),
                  selected: sel,
                  onSelected: (_) {
                    setState(() => _filter = s.$1);
                    context.read<OrderBloc>().add(
                        OrderLoadListEvent(status: _filter));
                  },
                );
              },
            ),
          ),
        ),

        // Orders list
        Expanded(child: BlocBuilder<OrderBloc, OrderState>(
          builder: (ctx, state) {
            if (state is OrderLoadingState)
              return const Center(
                  child: CircularProgressIndicator());
            if (state is OrderErrorState)
              return AppUI.emptyState(
                title: 'Could not load orders',
                message: state.message,
                icon: Icons.error_outline,
                btnLabel: 'Retry',
                onBtn: () => ctx.read<OrderBloc>()
                    .add(OrderLoadListEvent(status: _filter)));
            if (state is! OrderListLoaded ||
                state.orders.isEmpty)
              return AppUI.emptyState(
                title: 'No orders yet',
                message: 'Place your first order and it will appear here.',
                icon: Icons.receipt_long_outlined,
                btnLabel: 'Shop Now',
                onBtn: () => ctx.go('/products'));

            return RefreshIndicator(
              onRefresh: () async => ctx.read<OrderBloc>()
                  .add(OrderLoadListEvent(status: _filter)),
              child: PageContainer(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding,
                    vertical: 16),
                child: ListView.separated(
                  itemCount: state.orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = state.orders[i];
                    final status = o.status;
                    final col = _statusColor(status);
                    final dt = DateFormat('dd MMM yyyy, hh:mm a')
                        .format(o.createdAt);
                    return GestureDetector(
                      onTap: () =>
                          ctx.go('/orders/${o.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppUI.cardDecoration(),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                            Text(
                              '#${o.id.substring(0, o.id.length > 8 ? 8 : o.id.length).toUpperCase()}',
                              style: AppText.h3()),
                            AppUI.badge(
                              status ?? 'confirmed', col),
                          ]),
                          const SizedBox(height: 8),
                          Text(dt,
                              style: AppText.caption()),
                          const SizedBox(height: 6),
                          Text(
                            '${o.items.length} item${o.items.length > 1 ? 's' : ''}',
                            style: AppText.body()),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                            Text(
                              'Rs.${o.totalAmount.toStringAsFixed(2)}',
                              style: AppText.price(size: 18)),
                            Row(mainAxisSize: MainAxisSize.min,
                                children: [
                              Text('View details',
                                  style: AppText.label(
                                      color: AppColors.accent)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AppColors.accent),
                            ]),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        )),
      ]),
    );
  }
}
