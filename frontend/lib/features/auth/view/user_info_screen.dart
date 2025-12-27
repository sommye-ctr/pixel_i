import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../resources/strings.dart';
import '../../../core/widgets/index.dart';
import '../data/auth_repository.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _bioController = TextEditingController();
  final _batchController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _batchController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    setState(() => _saving = true);
    final repo = RepositoryProvider.of<AuthRepository>(context);
    try {
      await repo.updateProfile(
        bio: _bioController.text.trim(),
        batch: _batchController.text.trim(),
        department: _departmentController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$errorSaveInfoFailed$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(userInfoTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(controller: _bioController, hint: userInfoBioLabel),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _batchController,
              hint: userInfoBatchLabel,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _departmentController,
              hint: userInfoDepartmentLabel,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: _saving ? null : _saveInfo,
                type: RoundedButtonType.filled,
                child: const Text(userInfoContinueBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
