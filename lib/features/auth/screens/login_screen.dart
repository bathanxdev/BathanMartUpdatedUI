import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _fk = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (!_fk.currentState!.validate()) return;

    ctx.read<AuthBloc>().add(
          AuthLoginEvent(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticatedState) {
            final role = state.user.role;
            if (role == 'rider')
              ctx.go('/rider-home');
            else if (['admin', 'operations', 'warehouse', 'sourcing']
                .contains(role))
              ctx.go('/admin-home');
            else
              ctx.go('/welcome');
          }
          if (state is AuthErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error));
        },
        builder: (ctx, state) {
          final loading = state is AuthLoadingState;
          if (isDesktop) {
            return Row(children: [
              // Left panel — branding
              Expanded(
                flex: 5,
                child: Container(
                    decoration:
                        const BoxDecoration(gradient: AppGradients.dark),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg)),
                              child: const Icon(Icons.local_mall_rounded,
                                  color: Colors.white, size: 30)),
                          const SizedBox(height: 32),
                          Text('Bathan Mart',
                              style: AppText.display(
                                  color: Colors.white, size: 44)),
                          const SizedBox(height: 12),
                          Text(
                              'Local & Global Products.\nDelivered Fast. Everywhere.',
                              style: AppText.bodyLg(
                                  color: Colors.white.withAlpha(200))),
                          const SizedBox(height: 48),
                          ...[
                            '🌶️ Artisan Food & Spices',
                            '🧵 Handloom & Textiles',
                            '🌿 Natural Wellness',
                            '🌏 International Imports'
                          ].map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Text(s.substring(0, 2),
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(s.substring(3),
                                    style: AppText.body(
                                        color: Colors.white.withAlpha(200))),
                              ]))),
                        ])),
              ),
              // Right panel — form
              Expanded(
                  flex: 4,
                  child: Container(
                      color: Colors.white,
                      child: Center(
                          child: SingleChildScrollView(
                              padding: const EdgeInsets.all(48),
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: _loginForm(ctx, loading)))))),
            ]);
          }
          // Mobile
          return SafeArea(
              child: SingleChildScrollView(
                  child: Column(children: [
            Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
                decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.xxl))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                          onTap: () => context.go('/'),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.local_mall_rounded,
                                    color: Colors.white, size: 18)),
                            const SizedBox(width: 8),
                            Text('Bathan Mart',
                                style: AppText.bodyMd(color: Colors.white)),
                          ])),
                      const SizedBox(height: 28),
                      Text('Welcome back',
                          style:
                              AppText.display(color: Colors.white, size: 32)),
                      const SizedBox(height: 8),
                      Text('Sign in to continue',
                          style:
                              AppText.body(color: Colors.white.withAlpha(180))),
                    ])),
            Padding(
                padding: const EdgeInsets.all(24),
                child: _loginForm(ctx, loading)),
          ])));
        },
      ),
    );
  }

  Widget _loginForm(BuildContext ctx, bool loading) {
    return Form(
      key: _fk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (desktop only)
          if (MediaQuery.sizeOf(context).width >= 960) ...[
            Text('Sign In', style: AppText.display(size: 32)),
            const SizedBox(height: 8),
            Text('Enter your credentials to continue', style: AppText.body()),
            const SizedBox(height: 32),
          ],

          // Email Field
          AppTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please enter your email address.';
              if (!v.contains('@'))
                return 'Please enter a valid email address.';
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Password Field
          AppTextField(
            controller: _passCtrl,
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(ctx),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your password.' : null,
          ),

          const SizedBox(height: 6),

          // OTP LOGIN LINK
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
                onPressed: () => ctx.go('/otp', extra: _emailCtrl.text),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Login with OTP',
                    style: AppText.caption(color: AppColors.primary))),
            TextButton(
                onPressed: () => ctx.go('/forgot-password'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Forgot Password?',
                    style: AppText.caption(color: AppColors.accent))),
          ]),

          const SizedBox(height: 16),

          // LOGIN BUTTON
          AppButton(
            label: 'Sign In',
            isLoading: loading,
            icon: Icons.login,
            onPressed: loading ? null : () => _submit(ctx),
          ),

          const SizedBox(height: 20),

          AppUI.divider(label: 'or'),

          const SizedBox(height: 20),

          // REGISTER BUTTON
          AppButton(
            label: 'Create Free Account',
            outlined: true,
            icon: Icons.person_add_outlined,
            onPressed: () => ctx.go('/register'),
          ),

          const SizedBox(height: 20),

          // BACK
          Center(
            child: GestureDetector(
              onTap: () => ctx.go('/'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Back to store', style: AppText.caption()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
