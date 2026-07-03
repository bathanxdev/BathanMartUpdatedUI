import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String? phone;
  const OtpScreen({super.key, this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.phone != null && widget.phone!.isNotEmpty) {
      _phoneCtrl.text = widget.phone!;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext ctx) {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    ctx.read<AuthBloc>().add(AuthSendOtpEvent(_phoneCtrl.text.trim()));
  }

  void _verifyOtp(BuildContext ctx) {
    final otp = _otpCtrl.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('Please enter OTP sent to your phone number')),
      );
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('OTP should be exactly 6 digits')),
      );
      return;
    }

    ctx.read<AuthBloc>().add(
          AuthOtpVerifyEvent(
            _phoneCtrl.text.trim(),
            otp,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          // ✅ Matches AuthOtpSentState in auth_bloc.dart
          if (state is AuthOtpSentState) {
            setState(() => _otpSent = true);
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('OTP sent! Check backend console.'),
              backgroundColor: AppColors.success,
            ));
          }

          // ✅ Matches AuthAuthenticatedState in auth_bloc.dart
          if (state is AuthAuthenticatedState) {
            final role = state.user.role;
            if (role == 'rider') {
              ctx.go('/rider-home');
            } else if (['admin', 'operations', 'warehouse', 'sourcing']
                .contains(role)) {
              ctx.go('/admin-home');
            } else {
              ctx.go('/welcome');
            }
          }

          // ✅ Matches AuthOtpNewUserState in auth_bloc.dart
          if (state is AuthOtpNewUserState) {
            ctx.go('/register');
          }

          // ✅ Matches AuthErrorState in auth_bloc.dart
          if (state is AuthErrorState) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          final loading = state is AuthLoadingState;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(children: [
                // ── Hero header ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.xxl)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.arrow_back_ios,
                              color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          Text('Back to Login',
                              style: AppText.caption(color: Colors.white54)),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(Icons.phone_android_outlined,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _otpSent ? 'Enter OTP' : 'Login with OTP',
                        style: AppText.display(color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'Enter the 6-digit code sent to ${_phoneCtrl.text}'
                            : 'Enter your email to receive a one-time login code',
                        style: AppText.body(color: Colors.white.withAlpha(180)),
                      ),
                    ],
                  ),
                ),

                // ── Form ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const SizedBox(height: 8),

                    if (!_otpSent) ...[
                      // Phone number input
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Send OTP',
                        isLoading: loading,
                        icon: Icons.send_outlined,
                        onPressed: loading ? null : () => _sendOtp(ctx),
                      ),
                    ] else ...[
                      // OTP input
                      AppTextField(
                        controller: _otpCtrl,
                        label: '6-Digit OTP',
                        hint: '• • • • • •',
                        prefixIcon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _verifyOtp(ctx),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Didn't receive the code?",
                              style: AppText.caption()),
                          TextButton(
                            onPressed: loading ? null : () => _sendOtp(ctx),
                            child: const Text('Resend OTP'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Verify & Login',
                        isLoading: loading,
                        icon: Icons.verified_outlined,
                        onPressed: loading ? null : () => _verifyOtp(ctx),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Change Phone Number',
                        outlined: true,
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                            _otpCtrl.clear();
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Dev info box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Development mode: check the backend console window for your OTP code.',
                            style: AppText.caption(color: AppColors.info),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
