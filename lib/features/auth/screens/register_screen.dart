import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _fk = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController();
  final _phone = TextEditingController(), _pass = TextEditingController(), _cpass = TextEditingController();
  bool _obscure = true;
  @override void dispose() { for (final c in [_name,_email,_phone,_pass,_cpass]) c.dispose(); super.dispose(); }

  void _submit(BuildContext ctx) {
    if (!_fk.currentState!.validate()) return;
    ctx.read<AuthBloc>().add(AuthRegisterEvent(_name.text.trim(), _email.text.trim(), _phone.text.trim(), _pass.text));
  }

  @override Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticatedState) ctx.go('/welcome');
          if (state is AuthErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        },
        builder: (ctx, state) {
          final loading = state is AuthLoadingState;
          if (isDesktop) {
            return Row(children: [
              Expanded(flex: 4, child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.dark),
                padding: const EdgeInsets.all(48),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(AppRadius.lg)), child: const Icon(Icons.local_mall_rounded, color: Colors.white, size: 30)),
                  const SizedBox(height: 32),
                  Text('Join Bathan Mart', style: AppText.display(color: Colors.white, size: 40)),
                  const SizedBox(height: 12),
                  Text('Get access to the best local and global products, delivered fast.', style: AppText.body(color: Colors.white.withAlpha(200))),
                  const SizedBox(height: 32),
                  _benefit(Icons.local_shipping_outlined, 'Free delivery on first order'),
                  const SizedBox(height: 12),
                  _benefit(Icons.repeat_outlined, 'Set up auto-reorder subscriptions'),
                  const SizedBox(height: 12),
                  _benefit(Icons.track_changes_outlined, 'Real-time order tracking'),
                  const SizedBox(height: 12),
                  _benefit(Icons.verified_outlined, 'Quality-verified products only'),
                ]))),
              Expanded(flex: 5, child: Container(color: Colors.white,
                child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: _form(ctx, loading, isDesktop)))))),
            ]);
          }
          return SafeArea(child: SingleChildScrollView(child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              decoration: const BoxDecoration(gradient: AppGradients.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(onTap: () => context.go('/login'),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16), Text('Back', style: AppText.caption(color: Colors.white54))])),
                const SizedBox(height: 20),
                Text('Create Account', style: AppText.display(color: Colors.white, size: 30)),
                const SizedBox(height: 6),
                Text('Join thousands of happy customers', style: AppText.body(color: Colors.white.withAlpha(180))),
              ])),
            Padding(padding: const EdgeInsets.all(24), child: _form(ctx, loading, false)),
          ])));
        },
      ),
    );
  }

  Widget _form(BuildContext ctx, bool loading, bool isDesktop) => Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (isDesktop) ...[Text('Create Account', style: AppText.display(size: 32)), const SizedBox(height: 8), Text('Fill in your details to get started', style: AppText.body()), const SizedBox(height: 32)] else const SizedBox(height: 8),
    AppTextField(controller: _name, label: 'Full Name *', hint: 'Manish Kumar', prefixIcon: Icons.person_outline, textInputAction: TextInputAction.next, validator: (v) => v!.trim().isEmpty ? 'Enter full name' : null),
    const SizedBox(height: 14),
    AppTextField(controller: _email, label: 'Email Address *', hint: 'you@example.com', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: (v) => !v!.contains('@') ? 'Enter valid email' : null),
    const SizedBox(height: 14),
    AppTextField(controller: _phone, label: 'Phone Number *', hint: '9876543210', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, validator: (v) => v!.replaceAll(RegExp(r'[^0-9]'), '').length < 10 ? 'Enter valid phone' : null),
    const SizedBox(height: 14),
    AppTextField(controller: _pass, label: 'Password *', hint: 'Minimum 8 characters', prefixIcon: Icons.lock_outline, obscureText: _obscure, textInputAction: TextInputAction.next,
      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
      validator: (v) => v!.length < 8 ? 'Password must be at least 8 characters long' : null),
    const SizedBox(height: 14),
    AppTextField(controller: _cpass, label: 'Confirm Password *', prefixIcon: Icons.lock_outline, obscureText: true, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit(ctx), validator: (v) => v != _pass.text ? 'Passwords do not match' : null),
    const SizedBox(height: 24),
    AppButton(label: 'Create My Account', isLoading: loading, onPressed: loading ? null : () => _submit(ctx), icon: Icons.check_circle_outline),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account?  ', style: AppText.body()),
      GestureDetector(onTap: () => ctx.go('/login'), child: Text('Sign In', style: AppText.bodyMd(color: AppColors.primary, weight: FontWeight.w700))),
    ]),
    const SizedBox(height: 24),
  ]));

  Widget _benefit(IconData icon, String text) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Icon(icon, color: Colors.white, size: 16)),
    const SizedBox(width: 12),
    Text(text, style: AppText.body(color: Colors.white.withAlpha(200))),
  ]);
}
