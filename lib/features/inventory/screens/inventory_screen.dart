import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/inventory_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); context.read<InventoryBloc>().add(const InvLoadEvent()); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Inventory'),
      actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: () => context.read<InventoryBloc>().add(const InvLoadEvent()))],
      bottom: TabBar(controller: _tab, indicatorColor: AppColors.primary, tabs: const [Tab(text: 'Stock Levels'), Tab(text: 'Active Alerts')])),
    body: BlocBuilder<InventoryBloc, InventoryState>(builder: (ctx, state) {
      if (state is InvLoadingState) return const Center(child: CircularProgressIndicator());
      if (state is InvErrorState) return AppUI.emptyState(title: 'Error', message: state.message, icon: Icons.error_outline, btnLabel: 'Retry', onBtn: () => ctx.read<InventoryBloc>().add(const InvLoadEvent()));
      if (state is InvLoadedState) return TabBarView(controller: _tab, children: [
        _StockTab(items: state.items, summary: state.summary),
        _AlertsTab(alerts: []),
      ]);
      if (state is InvAlertsState) return TabBarView(controller: _tab, children: [
        const Center(child: CircularProgressIndicator()),
        _AlertsTab(alerts: state.alerts),
      ]);
      return const SizedBox.shrink();
    }),
  );
}

class _StockTab extends StatelessWidget {
  final List items; final Map summary;
  const _StockTab({required this.items, required this.summary});
  @override Widget build(BuildContext context) {
    if (items.isEmpty) return AppUI.emptyState(title: 'No inventory data', icon: Icons.warehouse_outlined, btnLabel: 'Go to Admin', onBtn: () => context.go('/admin/inventory'));
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        _pill('Healthy',   summary['Healthy']??0,   AppColors.success),
        const SizedBox(width: 8),
        _pill('Alert',     summary['Alert']??0,     AppColors.warning),
        const SizedBox(width: 8),
        _pill('Critical',  summary['Critical']??0,  AppColors.error),
        const SizedBox(width: 8),
        _pill('Overstock', summary['Overstock']??0, AppColors.info),
      ])),
      Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final inv = items[i];
          final status = inv.stockStatus;
          final col = {
            'Healthy': AppColors.success, 'Alert': AppColors.warning,
            'Critical': AppColors.error,  'Overstock': AppColors.info
          }[status] ?? AppColors.textHint;
          return Container(padding: const EdgeInsets.all(14), decoration: AppUI.cardDecoration(),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.productName ?? 'Product', style: AppText.bodyMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${inv.warehouseType ?? ''} • ${inv.warehouseName ?? ''}', style: AppText.caption()),
                Text('Bin: ${inv.binLocation ?? 'N/A'}', style: AppText.caption()),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${inv.qtyAvailable}', style: AppText.price(size: 20, color: col)),
                Text('available', style: AppText.caption()),
                const SizedBox(height: 4),
                AppUI.statusBadge(status ?? 'Healthy'),
              ]),
            ]));
        })),
    ]);
  }
  Widget _pill(String label, int count, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: color.withAlpha(50))),
    child: Column(children: [Text('$count', style: AppText.h2(color: color)), Text(label, style: AppText.caption(color: color))])));
}

class _AlertsTab extends StatelessWidget {
  final List alerts;
  const _AlertsTab({required this.alerts});
  @override Widget build(BuildContext context) {
    if (alerts.isEmpty) return AppUI.emptyState(title: 'No active alerts', message: 'All stock levels are within safe limits.', icon: Icons.check_circle_outline);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: alerts.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = alerts[i]; final isCrit = a.alertType == 'MSQ'; final col = isCrit ? AppColors.error : AppColors.warning;
        return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: col.withAlpha(10), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: col.withAlpha(60))),
          child: Row(children: [
            Icon(isCrit ? Icons.error_outline : Icons.warning_amber_outlined, color: col, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.productName ?? 'Product', style: AppText.bodyMd()),
              Text('Current: ${a.currentQty}  |  Threshold: ${a.thresholdQty}', style: AppText.caption()),
              Text(a.warehouseName ?? '', style: AppText.caption()),
            ])),
            AppUI.badge(a.alertType ?? 'ROP', col),
          ]));
      });
  }
}
