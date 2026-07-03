import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}
class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); context.read<AdminBloc>().add(const AdminLoadReportsEvent()); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports & Analytics'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<AdminBloc>().add(const AdminLoadReportsEvent()))],
      bottom: TabBar(controller: _tab, indicatorColor: Colors.white, isScrollable: true,
        tabs: const [Tab(text: 'Inventory'), Tab(text: 'Orders'), Tab(text: 'Subscriptions')]),
    ),
    body: BlocBuilder<AdminBloc, AdminState>(builder: (ctx, state) {
      if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
      if (state is AdminErrorState)   return Center(child: Text(state.message));
      if (state is! AdminReportsLoaded) return const SizedBox.shrink();
      return TabBarView(controller: _tab, children: [
        _inventoryReport(state.inventory),
        _ordersReport(state.orders),
        _subscriptionsReport(state.subscriptions),
      ]);
    }),
  );

  Widget _inventoryReport(List data) {
    if (data.isEmpty) return const AdminEmptyState(title: 'No inventory data', icon: Icons.warehouse_outlined);
    return ListView.separated(padding: const EdgeInsets.all(12),
      itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r   = data[i] as Map;
        final id  = r['_id'] as Map? ?? {};
        final type= id['type']?.toString() ?? '';
        final city= id['city']?.toString() ?? '';
        final col = type == 'MCW' ? AppColors.primary : type == 'LWH' ? AppColors.info : AppColors.success;
        final val = double.tryParse(r['total_value']?.toString() ?? '0') ?? 0;
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: col.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Text(type, style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 12))),
            const SizedBox(width: 8),
            Text(city, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _reportStat("SKUs",       "${r['sku_count']    ?? 0}", AppColors.primary),
            _reportStat("Units",      "${r['total_units']  ?? 0}", AppColors.info),
            _reportStat("Value",      'Rs.${val.toStringAsFixed(0)}', AppColors.success),
            _reportStat("Critical",   "${r['critical']     ?? 0}", AppColors.error),
          ]),
        ])));
      },
    );
  }

  Widget _ordersReport(List data) {
    if (data.isEmpty) return const AdminEmptyState(title: 'No order data', icon: Icons.receipt_outlined);
    return ListView.separated(padding: const EdgeInsets.all(12),
      itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r   = data[i] as Map;
        final id  = r['_id'] as Map? ?? {};
        final rev = double.tryParse(r['revenue']?.toString() ?? '0') ?? 0;
        final aov = double.tryParse(r['avg_aov']?.toString() ?? '0') ?? 0;
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(id['channel']?.toString()?.toUpperCase() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
            const SizedBox(width: 10),
            Text(id['status']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _reportStat("Orders",  "${r['count']  ?? 0}", AppColors.primary),
            _reportStat('Revenue', 'Rs.${rev.toStringAsFixed(0)}', AppColors.success),
            _reportStat('Avg AOV', 'Rs.${aov.toStringAsFixed(0)}', AppColors.info),
          ]),
        ])));
      },
    );
  }

  Widget _subscriptionsReport(List data) {
    if (data.isEmpty) return const AdminEmptyState(title: 'No subscription data', icon: Icons.repeat_outlined);
    return ListView.separated(padding: const EdgeInsets.all(12),
      itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r    = data[i] as Map;
        final freq = double.tryParse(r['avg_freq']?.toString() ?? '0') ?? 0;
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['product_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            _reportStat("Active Subs",  "${r['active_subs']  ?? 0}", AppColors.primary),
            _reportStat("Qty/Cycle",    "${r['total_qty']    ?? 0}", AppColors.info),
            _reportStat('Avg Freq',     '${freq.toStringAsFixed(0)} days', AppColors.secondary),
          ]),
        ])));
      },
    );
  }

  Widget _reportStat(String label, String val, Color color) => Expanded(child: Column(children: [
    Text(val,   style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
  ]));
}
