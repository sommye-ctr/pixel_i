import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/theme.dart';

import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../core/config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: backendBaseUrl,
      tokenStorage: tokenStorage,
    );

    final authRepository = AuthRepository(apiClient, tokenStorage);
    final router = buildRouter();

    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: authRepository)],
      child: MultiBlocProvider(
        providers: [BlocProvider(create: (_) => AuthBloc(authRepository))],
        child: MaterialApp.router(
          title: appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
        ),
      ),
    );
  }
}
