import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/theme.dart';
import 'package:frontend/features/events/bloc/events_bloc.dart';
import 'package:frontend/features/events/bloc/event_create_bloc.dart';
import 'package:frontend/features/events/data/events_repository.dart';

import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../core/config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/photos/data/photos_repository.dart';
import '../features/photos/bloc/photos_bloc.dart';
import '../features/photos/bloc/photo_detail_bloc.dart';
import 'router.dart';

class App extends StatefulWidget {
  final bool isLoggedIn;
  const App({super.key, this.isLoggedIn = false});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: backendBaseUrl,
      tokenStorage: tokenStorage,
    );

    final authRepository = AuthRepository(apiClient, tokenStorage);
    final photosRepository = PhotosRepository(apiClient);
    final eventsRepository = EventsRepository(apiClient);
    final router = buildRouter(isLoggedIn: widget.isLoggedIn);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: photosRepository),
        RepositoryProvider.value(value: eventsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepository)),
          BlocProvider(create: (_) => PhotosBloc(photosRepository)),
          BlocProvider(create: (_) => PhotoDetailBloc(photosRepository)),
          BlocProvider(
            create: (_) => EventsBloc(eventsRepository, authRepository),
          ),
          BlocProvider(create: (_) => EventCreateBloc(eventsRepository)),
        ],
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
