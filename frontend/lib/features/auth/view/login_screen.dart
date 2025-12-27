import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/resources/strings.dart';
import '../../../core/widgets/index.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {},
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: emailController,
                  hint: loginEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthEvent.requestOtp(emailController.text),
                        );
                      },
                      child: const Text(loginRequestOtpBtn),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthEvent.loginWithOAuth('demo-token'),
                        );
                      },
                      child: const Text(loginOAuthBtn),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: otpController,
                  hint: loginOtpLabel,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthEvent.submitOtp(
                        emailController.text,
                        otpController.text,
                      ),
                    );
                  },
                  child: const Text(loginVerifyOtpBtn),
                ),
                const SizedBox(height: 16),
                Text('$loginStatus: ${state.status.name}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
