import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});
  @override State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    context.read<AdminBloc>().add(const AdminLoadInventoryEvent());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Color _statusColor(String s) {
    switch (s) {
      case 'Critical': return AppColors.error;
      case 'Alert':    return AppColors.warning;
      case 'Overstock':return AppColors.info;
      default:         return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Inventory Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminBloc>().add(const AdminLoadInventoryEvent()),
        ),
      ],
      bottom: TabBar(
        controller: _tab,
        indicatorColor: Colors.white,
        tabs: const [Tab(text: 'Stock Levels'), Tab(text: 'Active Alerts')],
      ),
    ),
    body: BlocBuilder<AdminBloc, AdminState>(builder: (ctx, state) {
      if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
      if (state is AdminErrorState)   return Center(child: Text(state.message));
      if (state is! AdminInventoryLoaded) return const SizedBox.shrink();

      return TabBarView(controller: _tab, children: [

        // ── Stock Levels Tab ──────────────────────────────────
        Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('All',       null),
                const SizedBox(width: 8),
                _chip('Critical',  'Critical'),
                const SizedBox(width: 8),
                _chip('Alert',     'Alert'),
                const SizedBox(width: 8),
                _chip('Overstock', 'Overstock'),
                const SizedBox(width: 8),
                _chip('Healthy',   'Healthy'),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              _pill('Healthy',   state.items.where((i) => i['stock_status'] == 'Healthy').length,   AppColors.success),
              const SizedBox(width: 8),
              _pill('Alert',     state.items.where((i) => i['stock_status'] == 'Alert').length,     AppColors.warning),
              const SizedBox(width: 8),
              _pill('Critical',  state.items.where((i) => i['stock_status'] == 'Critical').length,  AppColors.error),
              const SizedBox(width: 8),
              _pill('Overstock', state.items.where((i) => i['stock_status'] == 'Overstock').length, AppColors.info),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(child: Builder(builder: (_) {
            final filtered = _statusFilter == null
                ? state.items
                : state.items.where((i) => i['stock_status'] == _statusFilter).toList();
            if (filtered.isEmpty) {
              return const AdminEmptyState(title: 'No items', icon: Icons.inventory_outlined);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final inv    = filtered[i] as Map;
                final status = inv['stock_status']?.toString() ?? 'Healthy';
                final col    = _statusColor(status);
                final wh     = inv['warehouse_id'];
                final prod   = inv['sku_id'];
                final whName = (wh is Map
                    ? wh['name']?.toString()
                    : inv['warehouse_name']?.toString()) ?? '';
                final pName  = (prod is Map
                    ? prod['name']?.toString()
                    : inv['product_name']?.toString()) ?? '';
                final tier   = (wh is Map
                    ? wh['type']?.toString()
                    : inv['tier']?.toString()) ?? '';
                final avail  = (inv['qty_available'] ??
                    (((inv['qty_on_hand'] ?? 0) as int) -
                     ((inv['qty_reserved'] ?? 0) as int))) as int;
                // Use string variable for bin to avoid quote nesting
                final binLoc = inv['bin_location']?.toString() ?? 'N/A';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(pName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$tier  •  $whName',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        Text('Bin: $binLoc',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('$avail',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: col)),
                        const Text('available',
                            style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: col.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status,
                              style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            );
          })),
        ]),

        // ── Alerts Tab ────────────────────────────────────────
        state.alerts.isEmpty
            ? const AdminEmptyState(
                title: 'No active alerts',
                message: 'All stock levels are within safe limits.',
                icon: Icons.check_circle_outline,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a      = state.alerts[i] as Map;
                  final type   = a['alert_type']?.toString() ?? 'ROP';
                  final isCrit = type == 'MSQ';
                  final col    = isCrit ? AppColors.error : AppColors.warning;
                  final sku    = a['sku_id'];
                  final wh     = a['warehouse_id'];
                  final pName  = (sku is Map
                      ? sku['name']?.toString()
                      : a['product_name']?.toString()) ?? '';
                  final whName = (wh is Map
                      ? wh['name']?.toString()
                      : a['warehouse_name']?.toString()) ?? '';
                  final tier   = (wh is Map
                      ? wh['type']?.toString()
                      : a['tier']?.toString()) ?? '';
                  // Use variables to avoid map key access inside strings
                  final currentQty   = a['current_qty']?.toString()   ?? '0';
                  final thresholdQty = a['threshold_qty']?.toString() ?? '0';

                  return Card(
                    color: col.withAlpha(10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(isCrit ? Icons.error : Icons.warning_amber, color: col, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(pName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(12)),
                            child: Text(type,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text('$tier  •  $whName',
                            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                        Text('Current: $currentQty  |  Threshold: $thresholdQty',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  );
                },
              ),
      ]);
    }),
  );

  Widget _chip(String label, String? val) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    selected: _statusFilter == val,
    onSelected: (_) => setState(() => _statusFilter = val),
  );

  Widget _pill(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:  color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label,    style: TextStyle(fontSize: 10, color: color.withAlpha(200))),
      ]),
    ),
  );
}
