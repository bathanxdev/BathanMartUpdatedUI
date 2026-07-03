import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';

class RiderScreen extends StatefulWidget {
  const RiderScreen({super.key});
  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> {
  List<dynamic> _deliveries = [];
  bool _loading = true, _online = true;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.instance.get('/riders/my-deliveries');
      if (mounted)
        setState(() {
          _deliveries = (r['data'] as List?) ?? [];
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelivery(String orderId) async {
    final otpCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Confirm Delivery'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Enter the OTP provided by customer:'),
                const SizedBox(height: 12),
                AppTextField(
                    controller: otpCtrl,
                    label: 'Customer OTP',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'))
              ],
            ));
    if (confirmed != true || otpCtrl.text.isEmpty) return;
    try {
      await ApiClient.instance.post('/riders/deliveries/$orderId/otp-confirm',
          data: {'otp': otpCtrl.text});
      if (mounted) {
        setState(() => _todayCount++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Delivery confirmed!'),
            backgroundColor: AppColors.success));
        _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final user = auth is AuthAuthenticatedState ? auth.user : null;
    final firstName = user?.name.split(' ').first ?? 'Rider';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(slivers: [
                // Hero header
                SliverToBoxAdapter(
                  child: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                            Color(0xFF0A3D1F),
                            AppColors.secondary
                          ])),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(20),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md)),
                                        child: const Icon(Icons.delivery_dining,
                                            color: Colors.white, size: 26)),
                                    const SizedBox(width: 12),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Bathan Mart',
                                              style: AppText.bodyMd(
                                                  color: Colors.white)),
                                          Text('Rider App',
                                              style: AppText.caption(
                                                  color: Colors.white54))
                                        ]),
                                  ]),
                                  Row(children: [
                                    Text(_online ? 'Online' : 'Offline',
                                        style: AppText.label(
                                            color: _online
                                                ? const Color(0xFF86EFAC)
                                                : Colors.white54)),
                                    const SizedBox(width: 8),
                                    Switch(
                                        value: _online,
                                        onChanged: (v) =>
                                            setState(() => _online = v),
                                        activeColor: const Color(0xFF86EFAC),
                                        inactiveThumbColor: Colors.white38),
                                  ]),
                                ]),
                            const SizedBox(height: 24),
                            Text('Hey, $firstName! 👋',
                                style: AppText.display(
                                    color: Colors.white, size: 26)),
                            const SizedBox(height: 4),
                            Text(
                                _online
                                    ? 'You are online and ready'
                                    : 'Toggle to go online',
                                style: AppText.body(
                                    color: Colors.white.withAlpha(180))),
                            const SizedBox(height: 20),
                            Row(children: [
                              _statPill('${_deliveries.length}', 'Active',
                                  const Color(0xFFFBBF24)),
                              const SizedBox(width: 10),
                              _statPill('$_todayCount', 'Today',
                                  const Color(0xFF86EFAC)),
                              const SizedBox(width: 10),
                              _statPill(
                                  _online ? 'Ready' : 'Away',
                                  'Status',
                                  _online
                                      ? const Color(0xFF86EFAC)
                                      : Colors.white54),
                            ]),
                          ])),
                ),

                // Status bar
                SliverToBoxAdapter(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: _online
                            ? AppColors.success.withAlpha(15)
                            : AppColors.border.withAlpha(40),
                        child: Row(children: [
                          Icon(Icons.circle,
                              size: 10,
                              color: _online
                                  ? AppColors.success
                                  : AppColors.textHint),
                          const SizedBox(width: 8),
                          Text(
                              _online
                                  ? (_deliveries.isEmpty
                                      ? 'No active deliveries'
                                      : '${_deliveries.length} active delivery${_deliveries.length > 1 ? 's' : ''}')
                                  : 'Go online to receive deliveries',
                              style: AppText.body(
                                  color: _online
                                      ? AppColors.success
                                      : AppColors.textHint,
                                  weight: FontWeight.w500)),
                          const Spacer(),
                          GestureDetector(
                              onTap: _load,
                              child: const Icon(Icons.refresh,
                                  size: 18, color: AppColors.textHint)),
                        ]))),

                // Deliveries
                if (_loading)
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator())))
                else if (_deliveries.isEmpty)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                          child: AppUI.emptyState(
                              title: 'No active deliveries',
                              message:
                                  'New orders will appear here when assigned to you.',
                              icon: Icons.delivery_dining_outlined)))
                else
                  SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                        final d = _deliveries[i] as Map;
                        final orderId = d['_id']?.toString() ?? '';
                        final shortId = orderId.length >= 8
                            ? '#${orderId.substring(0, 8).toUpperCase()}'
                            : orderId;
                        final status = d['status']?.toString() ?? '';
                        final cust = d['customer_id'];
                        final custName = cust is Map
                            ? cust['name']?.toString() ?? 'Customer'
                            : 'Customer';
                        final custPh =
                            cust is Map ? cust['phone']?.toString() ?? '' : '';
                        final addr = d['delivery_address'];
                        final line1 =
                            addr is Map ? addr['line1']?.toString() ?? '' : '';
                        final city =
                            addr is Map ? addr['city']?.toString() ?? '' : '';
                        final pincode = addr is Map
                            ? addr['pincode']?.toString() ?? ''
                            : '';
                        final amount = d['total_amount']?.toString() ?? '0';
                        final isDispatched = status == 'dispatched';
                        final isOutForDel = status == 'out_for_delivery';
                        return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Column(children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: AppColors.infoSoft,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppRadius.lg))),
                                  child: Row(children: [
                                    const Icon(Icons.receipt_outlined,
                                        size: 16, color: AppColors.info),
                                    const SizedBox(width: 8),
                                    Text(shortId,
                                        style:
                                            AppText.h3(color: AppColors.info)),
                                    const Spacer(),
                                    AppUI.statusBadge(status)
                                  ])),
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  AppColors.primarySoft,
                                              child: Text(
                                                  custName.isNotEmpty
                                                      ? custName[0]
                                                          .toUpperCase()
                                                      : 'C',
                                                  style: AppText.h3(
                                                      color:
                                                          AppColors.primary))),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(custName,
                                                    style: AppText.bodyMd()),
                                                Text(custPh,
                                                    style: AppText.caption())
                                              ])),
                                          Text('Rs.$amount',
                                              style: AppText.price(
                                                  size: 18,
                                                  color: AppColors.success))
                                        ]),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 18,
                                                  color: AppColors.error),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(line1,
                                                        style:
                                                            AppText.bodyMd()),
                                                    Text('$city $pincode',
                                                        style:
                                                            AppText.caption())
                                                  ]))
                                            ]),
                                        const SizedBox(height: 14),
                                        Row(children: [
                                          Expanded(
                                              child: OutlinedButton.icon(
                                                  icon: const Icon(
                                                      Icons.phone_outlined,
                                                      size: 16),
                                                  label: const Text('Call'),
                                                  onPressed: () {},
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                          minimumSize:
                                                              const Size(
                                                                  0, 40)))),
                                          if (isDispatched) ...[
                                            const SizedBox(width: 10),
                                            Expanded(
                                                flex: 2,
                                                child: ElevatedButton.icon(
                                                    icon: const Icon(
                                                        Icons
                                                            .inventory_2_outlined,
                                                        size: 16),
                                                    label: const Text(
                                                        'Confirm Pickup'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                AppColors.info,
                                                            minimumSize:
                                                                const Size(
                                                                    0, 40)),
                                                    onPressed: () async {
                                                      await ApiClient.instance.post(
                                                          '/riders/deliveries/$orderId/pickup');
                                                      _load();
                                                    }))
                                          ],
                                          if (isOutForDel) ...[
                                            const SizedBox(width: 10),
                                            Expanded(
                                                flex: 2,
                                                child: ElevatedButton.icon(
                                                    icon: const Icon(
                                                        Icons.verified_outlined,
                                                        size: 16),
                                                    label: const Text(
                                                        'Delivered — OTP'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                AppColors
                                                                    .success,
                                                            minimumSize:
                                                                const Size(
                                                                    0, 40)),
                                                    onPressed: () =>
                                                        _confirmDelivery(
                                                            orderId)))
                                          ],
                                        ]),
                                      ])),
                            ]));
                      }, childCount: _deliveries.length))),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ]))),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    title: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.red, size: 20)),
                      const SizedBox(width: 12),
                      const Text('Sign Out',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ]),
                    content: const Text(
                        'Are you sure you want to sign out of Bathan Mart?',
                        style: TextStyle(
                            fontSize: 14, color: Colors.black54, height: 1.5)),
                    actionsAlignment: MainAxisAlignment.end,
                    actions: [
                      TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10)),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14))),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context
                                .read<AuthBloc>()
                                .add(const AuthLogoutEvent());
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text('Sign Out',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14))),
                    ],
                  )),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.error,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign Out',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          elevation: 2),
    );
  }

  Widget _statPill(String value, String label, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(children: [
            Text(value, style: AppText.h2(color: color)),
            Text(label,
                style: AppText.caption(color: Colors.white.withAlpha(150)))
          ])));
}
