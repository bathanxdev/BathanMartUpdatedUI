import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/bloc/auth_bloc.dart';

class RiderLandingPage extends StatefulWidget {
  const RiderLandingPage({super.key});
  @override State<RiderLandingPage> createState() => _RiderLandingPageState();
}

class _RiderLandingPageState extends State<RiderLandingPage> {
  List<dynamic> _deliveries = [];
  bool _loading    = true;
  bool _online     = true;
  int  _totalToday = 0;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.instance.get('/riders/my-deliveries');
      if (mounted) setState(() {
        _deliveries = (r['data'] as List?) ?? [];
        _loading    = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _confirmDelivery(String orderId) async {
    final otpCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title:   const Text('Confirm Delivery'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter the OTP provided by the customer:'),
        const SizedBox(height: 16),
        TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'Customer OTP', prefixIcon: Icon(Icons.pin_outlined)), keyboardType: TextInputType.number, maxLength: 6),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
      ],
    ));
    if (confirmed != true || otpCtrl.text.isEmpty) return;
    try {
      await ApiClient.instance.post('/riders/deliveries/$orderId/otp-confirm', data: {'otp': otpCtrl.text});
      if (mounted) {
        setState(() => _totalToday++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Delivery confirmed!'), backgroundColor: AppColors.success));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _pickupOrder(String orderId) async {
    try {
      await ApiClient.instance.post('/riders/deliveries/$orderId/pickup');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup confirmed — order is out for delivery'), backgroundColor: AppColors.info)); _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticatedState?)?.user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(slivers: [

            // ── Header ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A3D1F), AppColors.secondary],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Top row
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24)),
                      const SizedBox(width: 12),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bathan Mart', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Rider App', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ]),
                    Row(children: [
                      Text(_online ? 'Online' : 'Offline', style: TextStyle(color: _online ? Colors.greenAccent : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _online,
                        onChanged: (v) => setState(() => _online = v),
                        activeColor: Colors.greenAccent,
                        inactiveThumbColor: Colors.white54,
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 28),

                  Text('Hey, ${user?.name.split(' ').first ?? 'Rider'}! 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_online ? 'You are online and ready for deliveries.' : 'You are offline. Toggle to receive deliveries.',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
                  const SizedBox(height: 24),

                  // Stats pills
                  Row(children: [
                    _statPill('${_deliveries.length}', 'Active',    Colors.orangeAccent),
                    const SizedBox(width: 10),
                    _statPill('$_totalToday',           'Today',     Colors.greenAccent),
                    const SizedBox(width: 10),
                    _statPill(_online ? 'Ready' : 'Away', 'Status', _online ? Colors.greenAccent : Colors.white54),
                  ]),
                ]),
              ),
            ),

            // ── Status bar ────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: _online ? AppColors.success.withAlpha(20) : AppColors.textHint.withAlpha(20),
                child: Row(children: [
                  Icon(Icons.circle, size: 10, color: _online ? AppColors.success : AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    _online
                        ? _deliveries.isEmpty ? 'No active deliveries — waiting for assignment' : '${_deliveries.length} active ${_deliveries.length == 1 ? 'delivery' : 'deliveries'}'
                        : 'Go online to start receiving delivery assignments',
                    style: TextStyle(fontSize: 13, color: _online ? AppColors.success : AppColors.textHint, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(onTap: _load, child: const Icon(Icons.refresh, size: 18, color: AppColors.textHint)),
                ]),
              ),
            ),

            // ── Deliveries list ────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
            else if (_deliveries.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  child: Column(children: [
                    Icon(Icons.delivery_dining_outlined, size: 80, color: AppColors.textHint.withAlpha(100)),
                    const SizedBox(height: 20),
                    const Text('No active deliveries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('New orders will appear here when assigned to you.',
                        style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final d       = _deliveries[i] as Map;
                    final orderId = d['_id']?.toString() ?? '';
                    final shortId = orderId.length >= 8 ? '#${orderId.substring(0,8).toUpperCase()}' : orderId;
                    final status  = d['status']?.toString() ?? '';
                    final cust    = d['customer_id'];
                    final custName= cust is Map ? cust['name']?.toString() : 'Customer';
                    final custPh  = cust is Map ? cust['phone']?.toString() : '';
                    final addr    = d['delivery_address'];
                    final line1   = addr is Map ? addr['line1']?.toString() : '';
                    final city    = addr is Map ? addr['city']?.toString()  : '';
                    final pincode = addr is Map ? addr['pincode']?.toString(): '';
                    final amount  = d['total_amount']?.toString() ?? '0';
                    final isDispatched = status == 'dispatched';
                    final isOutForDel  = status == 'out_for_delivery';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0,2))],
                      ),
                      child: Column(children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withAlpha(15),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.receipt_outlined, size: 16, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(shortId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.info)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(20)),
                              child: Text(status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Customer
                            Row(children: [
                              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
                                child: const Icon(Icons.person_outline, color: AppColors.primary, size: 18)),
                              const SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(custName ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(custPh  ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ]),
                              const Spacer(),
                              Text('Rs.$amount', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.success)),
                            ]),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Address
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(line1 ?? '',   style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                Text('$city  $pincode', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ])),
                            ]),
                            const SizedBox(height: 16),

                            // Action buttons
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.phone_outlined, size: 16),
                                  label: const Text('Call', style: TextStyle(fontSize: 13)),
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (isDispatched) Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Confirm Pickup', style: TextStyle(fontSize: 13)),
                                  onPressed: () => _pickupOrder(orderId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              )
                              else if (isOutForDel) Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.verified_outlined, size: 16),
                                  label: const Text('Delivered — OTP', style: TextStyle(fontSize: 13)),
                                  onPressed: () => _confirmDelivery(orderId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    );
                  }, childCount: _deliveries.length),
                ),
              ),

            // ── Bottom padding ────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ]),
        ),
      ),

      // ── Floating logout button ─────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<AuthBloc>().add(const AuthLogoutEvent()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.error,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        elevation: 2,
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label,  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10)),
      ]),
    ),
  );
}
