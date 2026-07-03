import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override void initState() { super.initState(); context.read<AdminBloc>().add(const AdminLoadDashboardEvent()); }

  @override Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: () => context.read<AdminBloc>().add(const AdminLoadDashboardEvent()))]),
      body: BlocBuilder<AdminBloc, AdminState>(builder: (ctx, state) {
        if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
        if (state is AdminErrorState) return _Err(msg: state.message, onRetry: () => ctx.read<AdminBloc>().add(const AdminLoadDashboardEvent()));
        if (state is! AdminDashboardLoaded) return const SizedBox.shrink();
        final data  = state.data;
        final today = data['today']         as Map? ?? {};
        final inv   = data['inventory']     as Map? ?? {};
        final riders= data['riders']        as Map? ?? {};
        final subs  = data['subscriptions'] as Map? ?? {};
        final top   = (data['top_products_7d'] as List?) ?? [];

        return RefreshIndicator(
          onRefresh: () async => ctx.read<AdminBloc>().add(const AdminLoadDashboardEvent()),
          child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // KPI Grid
                  Text("Today's Overview", style: AppText.h2()),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: context.kpiColumns, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: isDesktop ? 1.8 : 1.4,
                    children: [
                      _kpi("Total Orders",  "${today['total']     ?? 0}", Icons.receipt_outlined,        AppColors.primary),
                      _kpi("GMV Today",     "Rs.${today['gmv']    ?? 0}", Icons.currency_rupee,          AppColors.success),
                      _kpi("Delivered",     "${today['delivered'] ?? 0}", Icons.check_circle_outline,    AppColors.teal),
                      _kpi("Active Riders", "${riders['online']   ?? 0}", Icons.delivery_dining_outlined,AppColors.accent),
                    ]),
                  const SizedBox(height: 24),

                  // Inventory overview
                  Text('Inventory Status', style: AppText.h2()),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
                    children: [
                      _kpi("Critical", "${inv['critical'] ?? 0}", Icons.error_outline, AppColors.error),
                      _kpi("Warnings", "${inv['warnings'] ?? 0}", Icons.warning_outlined, AppColors.warning),
                      _kpi("Active Subs", "${subs['active'] ?? 0}", Icons.repeat, AppColors.info),
                    ]),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: AppText.h2()),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: isDesktop ? 2.2 : 2.4,
                    children: [
                      _action(ctx, 'Products',   Icons.inventory_2_outlined,       AppColors.info,    '/admin/products'),
                      _action(ctx, 'Orders',     Icons.receipt_outlined,           AppColors.success, '/admin/orders'),
                      _action(ctx, 'Inventory',  Icons.warehouse_outlined,         AppColors.teal,    '/admin/inventory'),
                      _action(ctx, 'Categories', Icons.category_outlined,          AppColors.accent,  '/admin/categories'),
                      _action(ctx, 'Warehouses', Icons.store_outlined,             AppColors.primary, '/admin/warehouses'),
                      _action(ctx, 'Suppliers',  Icons.local_shipping_outlined,    AppColors.info,    '/admin/suppliers'),
                      _action(ctx, 'Reports',    Icons.bar_chart,                  AppColors.success, '/admin/reports'),
                      _action(ctx, 'Users',      Icons.people_outlined,            AppColors.teal,    '/admin/users'),
                      _action(ctx, 'Roles',      Icons.manage_accounts_outlined,   AppColors.warning, '/admin/roles'),
                      _action(ctx, 'Audit Log',  Icons.history_outlined,           AppColors.error,   '/admin/audit-logs'),
                    ]),
                  const SizedBox(height: 24),

                  if (top.isNotEmpty) ...[
                    Text('Top Products (7 days)', style: AppText.h2()),
                    const SizedBox(height: 16),
                    ...top.take(5).toList().asMap().entries.map((e) {
                      final p = e.value as Map;
                      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                        decoration: AppUI.cardDecoration(),
                        child: Row(children: [
                          Container(width: 32, height: 32,
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                            child: Center(child: Text('${e.key + 1}', style: AppText.label(color: AppColors.primary)))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p['name']?.toString() ?? '', style: AppText.bodyMd())),
                          Text("${p['units'] ?? p['units_sold'] ?? 0} units", style: AppText.caption()),
                        ]));
                    }),
                    const SizedBox(height: 24),
                  ],
                ]))))));
      }),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) =>
    Container(padding: const EdgeInsets.all(14), decoration: AppUI.cardDecoration(elevated: true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Icon(icon, color: color, size: 18)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppText.price(color: color, size: 22)),
          Text(label, style: AppText.caption()),
        ]),
      ]));

  Widget _action(BuildContext ctx, String label, IconData icon, Color color, String route) =>
    GestureDetector(onTap: () => ctx.go(route),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppUI.cardDecoration(),
        child: Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppText.bodyMd(), overflow: TextOverflow.ellipsis)),
          Icon(Icons.chevron_right, color: AppColors.textHint, size: 16),
        ])));
}

class _Err extends StatelessWidget {
  final String msg; final VoidCallback onRetry;
  const _Err({required this.msg, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
    const SizedBox(height: 12),
    Text(msg, textAlign: TextAlign.center, style: AppText.body()),
    const SizedBox(height: 16),
    SizedBox(width: 160, child: ElevatedButton(onPressed: onRetry, child: const Text('Retry'))),
  ]));
}
