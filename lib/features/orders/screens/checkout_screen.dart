import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  final _fk      = GlobalKey<FormState>();
  final _line1   = TextEditingController();
  final _city    = TextEditingController();
  final _state   = TextEditingController();
  final _pincode = TextEditingController();
  final _name    = TextEditingController();
  final _phone   = TextEditingController();
  String _payment = 'cod';

  @override void dispose() {
    for (final c in [_line1,_city,_state,_pincode,_name,_phone])
      c.dispose();
    super.dispose();
  }

  void _placeOrder(BuildContext ctx) {
    if (!_fk.currentState!.validate()) return;
    final cartState = ctx.read<CartBloc>().state;
    if (cartState is! CartLoadedState || cartState.cart.items.isEmpty)
      return;

    ctx.read<OrderBloc>().add(OrderPlaceEvent(
      items: cartState.cart.items.map((i) =>
          {'sku_id': i.skuId, 'qty': i.qty}).toList(),
      address: {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'line1': _line1.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
      },
      paymentMethod: _payment,
      pincode: _pincode.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(title: const Text('Checkout')),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (ctx, state) {
          if (state is OrderPlacedState) {
            ctx.read<CartBloc>().add(const CartClearEvent());
            _showSuccessDialog(ctx, state.orderId);
          }
          if (state is OrderErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error));
        },
        builder: (ctx, orderState) {
          final loading = orderState is OrderLoadingState;
          return BlocBuilder<CartBloc, CartState>(
              builder: (ctx, cartState) {
            if (cartState is! CartLoadedState ||
                cartState.cart.items.isEmpty)
              return AppUI.emptyState(
                title: 'Cart is empty',
                icon: Icons.shopping_bag_outlined,
                btnLabel: 'Browse Products',
                onBtn: () => ctx.go('/products'));

            final cart = cartState.cart;
            final formSection = Form(key: _fk, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _sectionTitle('Delivery Address'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(
                  controller: _name, label: 'Full Name *',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  controller: _phone,
                  label: 'Phone *',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v!.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 12),
              AppTextField(
                controller: _line1,
                label: 'Street Address *',
                hint: '123, MG Road, Bandra West',
                prefixIcon: Icons.home_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(
                  controller: _city, label: 'City *',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  controller: _state, label: 'State',
                  textInputAction: TextInputAction.next)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  controller: _pincode,
                  label: 'Pincode *',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v!.length < 6 ? '6 digits' : null)),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Payment Method'),
              const SizedBox(height: 12),
              ...[
                ('cod',      '💵 Cash on Delivery',
                    'Pay when your order arrives'),
                ('online',   '💳 Pay Online',
                    'UPI, Net Banking, Cards'),
                ('wallet',   '👛 Wallet',
                    'Bathan Mart wallet balance'),
              ].map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentOption(
                  value: opt.$1, label: opt.$2,
                  subtitle: opt.$3,
                  selected: _payment == opt.$1,
                  onTap: () =>
                      setState(() => _payment = opt.$1)),
              )),
            ]));

            final summarySection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _sectionTitle('Order Summary'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppUI.cardDecoration(),
                child: Column(children: [
                  ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(item.name,
                          style: AppText.body(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                      Text('${item.qty} × Rs.${item.price.toStringAsFixed(0)}',
                          style: AppText.caption()),
                    ]),
                  )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text('Subtotal', style: AppText.body()),
                    Text('Rs.${cart.subtotal.toStringAsFixed(2)}',
                        style: AppText.bodyMd()),
                  ]),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text('Delivery', style: AppText.body()),
                    Text('Calculated on placement',
                        style: AppText.caption()),
                  ]),
                  const SizedBox(height: 14),
                  AppButton(
                    label: loading
                        ? 'Placing Order...' : 'Place Order Now',
                    isLoading: loading,
                    icon: Icons.check_circle_outline,
                    onPressed:
                        loading ? null : () => _placeOrder(ctx),
                  ),
                ]),
              ),
            ]);

            if (isDesktop) {
              return PageContainer(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding, vertical: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Expanded(flex: 3, child: SingleChildScrollView(
                    child: formSection)),
                  const SizedBox(width: 28),
                  SizedBox(width: 360,
                      child: summarySection),
                ]),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                formSection,
                const SizedBox(height: 16),
                summarySection,
                const SizedBox(height: 32),
              ]),
            );
          });
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: AppText.h2());

  void _showSuccessDialog(BuildContext ctx, String orderId) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: AppColors.successSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 40)),
          const SizedBox(height: 20),
          Text('Order Placed!', style: AppText.h1()),
          const SizedBox(height: 8),
          Text('Your order has been confirmed. We\'ll notify you as it progresses.',
              style: AppText.body(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(
              'Order ID: ${orderId.substring(0, orderId.length > 12 ? 12 : orderId.length).toUpperCase()}',
              style: AppText.label(color: AppColors.primary))),
          const SizedBox(height: 20),
          AppButton(label: 'Track My Order',
              onPressed: () {
                Navigator.pop(ctx);
                ctx.go('/orders');
              }),
          const SizedBox(height: 10),
          AppButton(label: 'Continue Shopping',
              outlined: true,
              onPressed: () {
                Navigator.pop(ctx);
                ctx.go('/home');
              }),
        ]),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value, label, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.value, required this.label,
    required this.subtitle, required this.selected,
    required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1)),
      child: Row(children: [
        Text(label.split(' ').first,
            style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(label.split(' ').skip(1).join(' '),
              style: AppText.bodyMd(
                  color: selected ? AppColors.primary
                      : AppColors.textPrimary)),
          Text(subtitle, style: AppText.caption()),
        ])),
        if (selected)
          const Icon(Icons.check_circle,
              color: AppColors.primary, size: 20),
      ]),
    ),
  );
}
