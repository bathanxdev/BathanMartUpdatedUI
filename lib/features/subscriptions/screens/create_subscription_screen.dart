import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/subscription_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class CreateSubscriptionScreen extends StatefulWidget {
  final String? skuId;
  const CreateSubscriptionScreen({super.key, this.skuId});
  @override State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}
class _CreateSubscriptionScreenState
    extends State<CreateSubscriptionScreen> {
  Map? _product;
  bool _loading = true;
  int _qty = 1;
  int _freqDays = 7;
  String _payment = 'cod';

  static const _freqOptions = [
    (1,  'Every Day'),
    (7,  'Every Week'),
    (14, 'Every 2 Weeks'),
    (30, 'Every Month'),
    (60, 'Every 2 Months'),
  ];

  @override void initState() {
    super.initState();
    if (widget.skuId != null) _loadProduct();
    else setState(() => _loading = false);
  }

  Future<void> _loadProduct() async {
    try {
      final r = await ApiClient.instance
          .get('/products/${widget.skuId}');
      if (mounted) setState(() {
        _product = r['data'] as Map;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _create(BuildContext ctx) {
    if (widget.skuId == null) return;
    ctx.read<SubscriptionBloc>().add(SubCreateEvent(
        widget.skuId!, _qty, _freqDays, _payment));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Set Up Auto-Reorder')),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (ctx, state) {
          if (state is SubCreatedState) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Subscription created!'),
              backgroundColor: AppColors.success));
            ctx.go('/subscriptions');
          }
          if (state is SubErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error));
        },
        builder: (ctx, state) {
          if (_loading)
            return const Center(
                child: CircularProgressIndicator());
          final loading = state is SubLoadingState;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Product info
              if (_product != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppUI.cardDecoration(),
                  child: Row(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(
                            AppRadius.md)),
                      child: Center(child: Text(
                        (_product!['origin_type'] == 'international')
                            ? '🌏' : '🏠',
                        style: const TextStyle(fontSize: 28)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(_product!['name']?.toString() ?? "",
                          style: AppText.h3()),
                      Text(
                        "Rs.${_product!['price']} per ${_product!["unit"] ?? 'piece'}",
                        style: AppText.body()),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),
              ],

              // Quantity
              Text('Quantity per delivery', style: AppText.h3()),
              const SizedBox(height: 12),
              Row(children: [
                _stepBtn(Icons.remove,
                    () { if (_qty > 1) setState(() => _qty--); }),
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(
                        AppRadius.md)),
                  child: Text('$_qty',
                      style: AppText.display(
                          color: AppColors.primary, size: 28))),
                _stepBtn(Icons.add,
                    () => setState(() => _qty++)),
              ]),
              const SizedBox(height: 24),

              // Frequency
              Text('Delivery frequency', style: AppText.h3()),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _freqOptions.map((f) {
                  final sel = _freqDays == f.$1;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _freqDays = f.$1),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(
                            AppRadius.full),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.border)),
                      child: Text(f.$2,
                          style: AppText.label(
                              color: sel
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                    ),
                  );
                }).toList()),
              const SizedBox(height: 24),

              // Payment
              Text('Payment method', style: AppText.h3()),
              const SizedBox(height: 12),
              ...[
                ('cod',    '💵 Cash on Delivery'),
                ('online', '💳 Online Payment'),
              ].map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _payment = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _payment == opt.$1
                          ? AppColors.primarySoft
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(
                          AppRadius.md),
                      border: Border.all(
                        color: _payment == opt.$1
                            ? AppColors.primary
                            : AppColors.border,
                        width: _payment == opt.$1 ? 2 : 1)),
                    child: Row(children: [
                      Text(opt.$2,
                          style: AppText.bodyMd()),
                      const Spacer(),
                      if (_payment == opt.$1)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary,
                            size: 20),
                    ]),
                  ),
                ),
              )),
              const SizedBox(height: 24),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(
                      AppRadius.md),
                  border: Border.all(
                      color: AppColors.gold.withAlpha(80))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('Subscription Summary',
                      style: AppText.h3(
                          color: AppColors.warning)),
                  const SizedBox(height: 10),
                  if (_product != null)
                    _summaryRow('Product',
                        _product!['name']?.toString() ?? ''),
                  _summaryRow('Quantity', '$_qty unit${_qty > 1 ? 's' : ''}'),
                  _summaryRow('Frequency',
                      'Every $_freqDays day${_freqDays > 1 ? 's' : ''}'),
                  if (_product?['price'] != null)
                    _summaryRow("Cost per cycle",
                        "Rs.${((_product!['price'] as num) * _qty).toStringAsFixed(0)}"),
                ])),
              const SizedBox(height: 28),
              AppButton(
                label: "Start Auto-Reorder",
                isLoading: loading,
                icon: Icons.repeat_outlined,
                onPressed: widget.skuId == null || loading
                    ? null : () => _create(ctx)),
              const SizedBox(height: 12),
              AppButton(
                label: 'Cancel',
                outlined: true,
                onPressed: () => context.go('/subscriptions')),
              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border)),
        child: Icon(icon, color: AppColors.primary)),
    );

  Widget _summaryRow(String label, String value) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(label, style: AppText.body()),
        Text(value, style: AppText.bodyMd()),
      ]));
}
