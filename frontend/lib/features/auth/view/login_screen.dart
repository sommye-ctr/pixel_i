import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {},
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
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
                      child: const Text('Request OTP'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthEvent.loginWithOAuth('demo-token'),
                        );
                      },
                      child: const Text('Login via OAuth'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
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
                  child: const Text('Verify OTP'),
                ),
                const SizedBox(height: 16),
                Text('Status: ${state.status.name}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
