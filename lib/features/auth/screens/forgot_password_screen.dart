import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl  = TextEditingController();
  final _otpCtrl    = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _cpassCtrl  = TextEditingController();
  bool _codeSent    = false;
  bool _obscure     = true;

  @override void dispose() {
    _emailCtrl.dispose(); _otpCtrl.dispose();
    _passCtrl.dispose();  _cpassCtrl.dispose();
    super.dispose();
  }

  void _sendCode(BuildContext ctx) {
    if (_emailCtrl.text.trim().isEmpty) return;
    ctx.read<AuthBloc>().add(AuthForgotPasswordEvent(_emailCtrl.text.trim()));
  }

  void _resetPassword(BuildContext ctx) {
    if (_otpCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) return;
    if (_passCtrl.text != _cpassCtrl.text) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: AppColors.error));
      return;
    }
    if (_passCtrl.text.length < 8) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Password must be at least 8 characters'),
        backgroundColor: AppColors.error));
      return;
    }
    ctx.read<AuthBloc>().add(AuthResetPasswordEvent(
        _emailCtrl.text.trim(), _otpCtrl.text.trim(), _passCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthForgotPasswordSentState) {
            setState(() => _codeSent = true);
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Reset code sent to your email'),
              backgroundColor: AppColors.success));
          }
          if (state is AuthPasswordResetSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Password reset! Please log in with your new password.'),
              backgroundColor: AppColors.success));
            ctx.go('/login');
          }
          if (state is AuthErrorState)
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error));
        },
        builder: (ctx, state) {
          final loading = state is AuthLoadingState;
          return SafeArea(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(child: Column(children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xxl))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text('Back to Login', style: AppText.caption(color: Colors.white54)),
                    ])),
                  const SizedBox(height: 28),
                  Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 16),
                  Text(_codeSent ? 'Set New Password' : 'Forgot Password',
                      style: AppText.display(color: Colors.white, size: 30)),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code sent to ${_emailCtrl.text} and set a new password'
                        : 'Enter your registered email and we will send you a reset code',
                    style: AppText.body(color: Colors.white.withAlpha(180))),
                ])),

              // Form
              Padding(padding: const EdgeInsets.all(24), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),

                // Email field — always visible
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _codeSent,
                  textInputAction: TextInputAction.done),
                const SizedBox(height: 16),

                if (!_codeSent) ...[
                  AppButton(
                    label: 'Send Reset Code',
                    isLoading: loading,
                    icon: Icons.send_outlined,
                    onPressed: loading ? null : () => _sendCode(ctx)),
                ] else ...[
                  // OTP field
                  AppTextField(
                    controller: _otpCtrl,
                    label: '6-Digit Reset Code',
                    hint: '• • • • • •',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),

                  // New password
                  AppTextField(
                    controller: _passCtrl,
                    label: 'New Password',
                    hint: 'Minimum 8 characters',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure))),
                  const SizedBox(height: 14),

                  // Confirm password
                  AppTextField(
                    controller: _cpassCtrl,
                    label: 'Confirm New Password',
                    hint: 'Repeat new password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _resetPassword(ctx)),
                  const SizedBox(height: 8),

                  // Resend code link
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Didn't receive the code?", style: AppText.caption()),
                    GestureDetector(
                      onTap: () => _sendCode(ctx),
                      child: Text('Resend Code',
                          style: AppText.caption(color: AppColors.primary))),
                  ]),
                  const SizedBox(height: 20),

                  AppButton(
                    label: 'Reset Password',
                    isLoading: loading,
                    icon: Icons.check_circle_outline,
                    onPressed: loading ? null : () => _resetPassword(ctx)),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Change Email',
                    outlined: true,
                    onPressed: () => setState(() {
                      _codeSent = false;
                      _otpCtrl.clear();
                      _passCtrl.clear();
                      _cpassCtrl.clear();
                    })),
                ],

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _codeSent
                          ? 'Check your spam folder if you did not receive the code.'
                          : 'The reset code expires in 10 minutes. Check your email inbox.',
                      style: AppText.caption(color: AppColors.info))),
                  ])),
                const SizedBox(height: 32),
              ])),
            ])),
          )));
        },
      ),
    );
  }
}
