import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/assets.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';
import '../../../core/widgets/index.dart';
import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
      AuthEvent.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.error) {
          ToastUtils.showLong('Login failed: ${state.error}');
        } else if (state.status == AuthStatus.authenticated) {
          // Login successful, navigate to home
          context.go('/');
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
                      assetPath: AssetPaths.login,
                      height: context.heightPercent(40),
                    ),
                    CustomTextField(
                      controller: _usernameController,
                      icon: Icon(LucideIcons.atSign),
                      hint: loginUsernameLabel,
                      validator: Validators.username,
                    ),
                    const SizedBox(height: defaultSpacing),
                    CustomTextField(
                      controller: _passwordController,
                      icon: Icon(LucideIcons.lock),
                      hint: loginPasswordLabel,
                      obscure: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: largeSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: isLoading ? null : _onLogin,
                        type: RoundedButtonType.filled,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(loginButton),
                      ),
                    ),
                    const SizedBox(height: defaultSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: () {},
                        type: RoundedButtonType.outlined,
                        child: const Text(loginOAuthBtn),
                      ),
                    ),
                    const SizedBox(height: defaultSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(loginNoAccount),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text(loginSignupLink),
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
