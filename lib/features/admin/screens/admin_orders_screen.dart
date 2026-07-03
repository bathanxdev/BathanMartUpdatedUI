import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/admin_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}
class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _statusFilter;
  int _page = 1;

  static const _statuses = ['All','confirmed','picking','packed','dispatched','out_for_delivery','delivered','cancelled'];

  @override void initState() { super.initState(); _load(); }
  void _load() => context.read<AdminBloc>().add(AdminLoadOrdersEvent(status: _statusFilter, page: _page));

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered':        return AppColors.success;
      case 'cancelled':        return AppColors.error;
      case 'out_for_delivery': return AppColors.info;
      case 'dispatched':       return AppColors.secondary;
      default:                 return AppColors.warning;
    }
  }

  void _showStatusDialog(BuildContext ctx, String orderId, String current) {
    String selected = current;
    final validNext = ['confirmed','picking','packed','dispatched','out_for_delivery','delivered','cancelled'];
    showDialog(context: ctx, builder: (_) => BlocProvider.value(
      value: ctx.read<AdminBloc>(),
      child: StatefulBuilder(builder: (bCtx, setS) => AlertDialog(
        title: Text('Update Order Status'),
        content: DropdownButton<String>(
          value: selected, isExpanded: true,
          items: validNext.map((s) => DropdownMenuItem(value: s, child: Text(AppConstants.orderStatusLabels[s] ?? s))).toList(),
          onChanged: (v) => setS(() => selected = v!),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(bCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ctx.read<AdminBloc>().add(AdminUpdateOrderStatusEvent(orderId, selected));
              Navigator.pop(bCtx);
            },
            child: const Text('Update'),
          ),
        ],
      )),
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order Management')),
    body: Column(children: [
      SizedBox(height: 50, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal, itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _statuses[i]; final val = s == 'All' ? null : s;
          return ChoiceChip(label: Text(s=='All' ? 'All' : AppConstants.orderStatusLabels[s]??s, style: const TextStyle(fontSize: 12)),
            selected: _statusFilter == val,
            onSelected: (_) { setState(() { _statusFilter = val; _page = 1; }); _load(); });
        },
      )),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is AdminErrorState)   return Center(child: Text(state.message));
          if (state is! AdminOrdersLoaded || state.orders.isEmpty)
            return const AdminEmptyState(title: 'No orders found', icon: Icons.receipt_outlined);
          return Column(children: [
            Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final o = state.orders[i];
                final status = o['status']?.toString() ?? '';
                final col    = _statusColor(status);
                final orderId= o['_id']?.toString() ?? '';
                final shortId= orderId.length >= 8 ? orderId.substring(0,8).toUpperCase() : orderId.toUpperCase();
                final createdAt = DateTime.tryParse(o['createdAt']?.toString() ?? o['created_at']?.toString() ?? '');
                final customer  = o['customer_id'];
                final custName  = customer is Map ? customer['name']?.toString() : 'Customer';
                final custPhone = customer is Map ? customer['phone']?.toString() : '';
                return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: col.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                      child: Text(AppConstants.orderStatusLabels[status] ?? status, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('$custName  •  $custPhone', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text("Rs.${o['total_amount']}", style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                    const SizedBox(width: 12),
                    Text(o['channel']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(width: 12),
                    if (createdAt != null) Text(DateFormat('dd MMM, hh:mm a').format(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showStatusDialog(ctx, orderId, status),
                    )),
                  ]),
                ])));
              },
            )),
            AdminPagination(page: state.page, total: state.total, limit: 20,
              onPrev: () { if (_page > 1) { setState(()=>_page--); _load(); } },
              onNext: () { if (_page * 20 < state.total) { setState(()=>_page++); _load(); } },
            ),
          ]);
        },
      )),
    ]),
  );
}
