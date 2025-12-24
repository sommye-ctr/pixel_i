import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/resources/strings.dart';

import '../core/network/api_client.dart';
import '../core/config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: backendBaseUrl);

    final authRepository = AuthRepository(apiClient);
    final router = buildRouter();

    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: authRepository)],
      child: MultiBlocProvider(
        providers: [BlocProvider(create: (_) => AuthBloc(authRepository))],
        child: MaterialApp.router(
          title: appName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
