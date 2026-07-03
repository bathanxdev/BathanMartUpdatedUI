import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/subscription_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});
  @override State<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}
class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  @override void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(const SubLoadEvent());
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':    return AppColors.success;
      case 'paused':    return AppColors.warning;
      case 'cancelled': return AppColors.error;
      default:          return AppColors.textHint;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'active':    return Icons.check_circle_outline;
      case 'paused':    return Icons.pause_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      default:          return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: context.isDesktop ? null : AppBar(
        title: const Text('My Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<SubscriptionBloc>()
                .add(const SubLoadEvent())),
        ],
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (ctx, state) {
          if (state is SubErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error));
        },
        builder: (ctx, state) {
          if (state is SubLoadingState)
            return const Center(child: CircularProgressIndicator());
          if (state is! SubLoadedState || state.subs.isEmpty)
            return AppUI.emptyState(
              title: 'No subscriptions yet',
              message: 'Set up auto-reorders on any product. Never run out again.',
              icon: Icons.repeat_outlined,
              btnLabel: 'Browse Products',
              onBtn: () => ctx.go('/products'));

          return RefreshIndicator(
            onRefresh: () async =>
                ctx.read<SubscriptionBloc>().add(const SubLoadEvent()),
            child: PageContainer(
              padding: EdgeInsets.symmetric(
                  horizontal: context.pagePadding, vertical: 16),
              child: ListView.separated(
                itemCount: state.subs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final sub = state.subs[i];
                  final status = sub.status;
                  final col = _statusColor(status);
                  final nextRun = sub.nextRunAt != null
                      ? DateFormat('dd MMM yyyy')
                          .format(sub.nextRunAt!)
                      : 'Paused';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppUI.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                          child: const Icon(Icons.repeat,
                              color: AppColors.primary, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(sub.productName ?? 'Product',
                              style: AppText.h3()),
                          Text('Every ${sub.frequencyDays} days  •  Qty: ${sub.qty}',
                              style: AppText.caption()),
                        ])),
                        AppUI.badge(status ?? 'active', col,
                            icon: _statusIcon(status)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.schedule_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text('Next order: $nextRun',
                            style: AppText.caption()),
                        const Spacer(),
                        Text(
                          sub.price != null
                              ? 'Rs.${sub.price!.toStringAsFixed(0)}/cycle' : '',
                          style: AppText.label(
                              color: AppColors.primary)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        if (status == 'active') ...[
                          Expanded(child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.pause_outlined, size: 16),
                            label: const Text('Pause'),
                            onPressed: () =>
                                _showPauseDialog(ctx, sub.id),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.skip_next_outlined, size: 16),
                            label: const Text('Skip'),
                            onPressed: () => ctx.read<SubscriptionBloc>()
                                .add(SubSkipEvent(sub.id)),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12)),
                          )),
                        ],
                        if (status == 'paused')
                          Expanded(child: ElevatedButton.icon(
                            icon: const Icon(
                                Icons.play_arrow_outlined, size: 16),
                            label: const Text('Resume'),
                            onPressed: () => ctx.read<SubscriptionBloc>()
                                .add(SubResumeEvent(sub.id)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                minimumSize: const Size(0, 38)),
                          )),
                        if (status != 'cancelled') ...[
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(
                            icon: Icon(Icons.cancel_outlined,
                                size: 16, color: AppColors.error),
                            label: Text('Cancel',
                                style: AppText.label(
                                    color: AppColors.error)),
                            onPressed: () =>
                                _confirmCancel(ctx, sub.id),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.error),
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12)),
                          )),
                        ],
                      ]),
                    ]),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPauseDialog(BuildContext ctx, String id) {
    int days = 7;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(
      builder: (dCtx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Pause Subscription'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Pause for how many days?',
              style: AppText.body()),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            IconButton(icon: const Icon(Icons.remove),
                onPressed: () {
                  if (days > 1) setS(() => days--);
                }),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('$days days',
                  style: AppText.h2(color: AppColors.primary))),
            IconButton(icon: const Icon(Icons.add),
                onPressed: () => setS(() => days++)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ctx.read<SubscriptionBloc>()
                  .add(SubPauseEvent(id, days));
              Navigator.pop(dCtx);
            },
            child: Text('Pause for $days days')),
        ],
      )));
  }

  void _confirmCancel(BuildContext ctx, String id) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: const Text('Cancel Subscription'),
      content: const Text(
          'This will stop all future auto-orders for this product.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep It')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error),
          onPressed: () {
            ctx.read<SubscriptionBloc>().add(SubCancelEvent(id));
            Navigator.pop(ctx);
          },
          child: const Text('Cancel Subscription')),
      ],
    ));
  }
}
