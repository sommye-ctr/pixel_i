import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/assets.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../core/resources/strings.dart';
import '../../../core/widgets/index.dart';
import '../bloc/auth_bloc.dart';

class FillProfileScreen extends StatefulWidget {
  const FillProfileScreen({super.key});

  @override
  State<FillProfileScreen> createState() => _FillProfileScreenState();
}

class _FillProfileScreenState extends State<FillProfileScreen> {
  final _bioController = TextEditingController();
  final _batchController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void dispose() {
    _bioController.dispose();
    _batchController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    context.read<AuthBloc>().add(
      AuthEvent.updateProfile(
        bio: _bioController.text.trim(),
        batch: _batchController.text.trim(),
        department: _departmentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.error) {
          ToastUtils.showLong('$errorSaveInfoFailed${state.error ?? ''}');
        } else if (state.status == AuthStatus.authenticated) {
          context.go('/');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgAsset(
                    assetPath: AssetPaths.profileFill,
                    height: context.heightPercent(35),
                  ),
                  CustomTextField(
                    controller: _bioController,
                    hint: userInfoBioLabel,
                  ),
                  const SizedBox(height: defaultSpacing),
                  CustomTextField(
                    controller: _batchController,
                    hint: userInfoBatchLabel,
                  ),
                  const SizedBox(height: defaultSpacing),
                  CustomTextField(
                    controller: _departmentController,
                    hint: userInfoDepartmentLabel,
                  ),
                  const SizedBox(height: largeSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: isLoading ? null : _saveInfo,
                      type: RoundedButtonType.filled,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(userInfoContinueBtn),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
