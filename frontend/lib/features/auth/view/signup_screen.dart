import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/assets.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';
import '../../../core/widgets/index.dart';
import '../bloc/auth_bloc.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
      AuthEvent.signup(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      ),
    );
  }

  Future<void> _showOtpBottomSheet({required String email}) async {
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmailOtpBottomSheet(email: email),
    );
    if (verified == true && mounted) {
      context.push('/user-info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$errorSignupFailed${state.error}')),
          );
        } else if (state.status == AuthStatus.unauthenticated) {
          // Signup successful, show OTP sheet
          _showOtpBottomSheet(email: _emailController.text.trim());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgAsset(
                      assetPath: AssetPaths.signup,
                      height: context.heightPercent(40),
                    ),
                    CustomTextField(
                      controller: _emailController,
                      icon: Icon(LucideIcons.mail),
                      hint: signupEmailLabel,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.isEmpty)
                          ? signupValidationRequired
                          : null,
                    ),
                    const SizedBox(height: defaultSpacing),
                    CustomTextField(
                      controller: _nameController,
                      icon: Icon(LucideIcons.user),
                      hint: signupNameLabel,
                      validator: (v) => (v == null || v.isEmpty)
                          ? signupValidationRequired
                          : null,
                    ),
                    const SizedBox(height: defaultSpacing),
                    CustomTextField(
                      controller: _usernameController,
                      icon: Icon(LucideIcons.atSign),
                      hint: signupUsernameLabel,
                      validator: (v) => (v == null || v.isEmpty)
                          ? signupValidationRequired
                          : null,
                    ),
                    const SizedBox(height: defaultSpacing),
                    CustomTextField(
                      controller: _passwordController,
                      icon: Icon(LucideIcons.lock),
                      hint: signupPasswordLabel,
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? signupValidationPassword
                          : null,
                    ),
                    const SizedBox(height: largeSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: isLoading ? null : _onSignup,
                        type: RoundedButtonType.filled,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(signupCreateBtn),
                      ),
                    ),
                    const SizedBox(height: defaultSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: () {},
                        type: RoundedButtonType.outlined,
                        child: const Text(signupOAuthBtn),
                      ),
                    ),
                    const SizedBox(height: defaultSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(signupAlreadyHaveAccount),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(signupLoginLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmailOtpBottomSheet extends StatefulWidget {
  final String email;
  const EmailOtpBottomSheet({super.key, required this.email});

  @override
  State<EmailOtpBottomSheet> createState() => _EmailOtpBottomSheetState();
}

class _EmailOtpBottomSheetState extends State<EmailOtpBottomSheet> {
  final _otpController = TextEditingController();
  int _secondsLeft = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    context.read<AuthBloc>().add(AuthEvent.submitOtp(widget.email, otp));
  }

  Future<void> _resend() async {
    if (!_canResend) return;

    context.read<AuthBloc>().add(AuthEvent.requestOtp(widget.email));
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // OTP verified successfully
          Navigator.of(context).pop(true);
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorOtpVerificationFailed${state.error}'),
            ),
          );
        } else if (state.status == AuthStatus.unauthenticated &&
            _canResend == false) {
          // OTP resent successfully
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(otpResendSuccess)));
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomInset + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  otpTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('$otpMessage ${widget.email}. Enter it below.'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _otpController,
                  hint: otpLabel,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: isLoading ? null : _verify,
                        type: RoundedButtonType.filled,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(otpVerifyBtn),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _canResend && !isLoading ? _resend : null,
                      child: Text(
                        _canResend
                            ? otpResendBtn
                            : '$otpResendCountdown $_secondsLeft$otpResendCountdownSuffix',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
