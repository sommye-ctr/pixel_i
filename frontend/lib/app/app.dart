import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/theme.dart';
import 'package:frontend/features/events/bloc/events_bloc.dart';
import 'package:frontend/features/events/bloc/event_create_bloc.dart';
import 'package:frontend/features/events/data/events_repository.dart';
import 'package:overlay_support/overlay_support.dart';

import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../core/config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/photos/data/photos_repository.dart';
import '../features/photos/bloc/photos_bloc.dart';
import '../features/photos/bloc/photo_detail_bloc.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/search/data/search_repository.dart';
import '../features/notifications/bloc/notifications_bloc.dart';
import 'router.dart';

class App extends StatefulWidget {
  final bool isLoggedIn;
  const App({super.key, this.isLoggedIn = false});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription? _authSubscription;
  NotificationsBloc? _notificationsBloc;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: backendBaseUrl,
      tokenStorage: tokenStorage,
    );

    final authRepository = AuthRepository(apiClient, tokenStorage);
    final photosRepository = PhotosRepository(apiClient);
    final searchRepository = SearchRepository(apiClient);
    final eventsRepository = EventsRepository(apiClient);
    final notificationsRepository = NotificationsRepository(
      apiClient,
      tokenStorage,
    );
    final router = buildRouter(isLoggedIn: widget.isLoggedIn);

    return OverlaySupport.global(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: authRepository),
          RepositoryProvider.value(value: photosRepository),
          RepositoryProvider.value(value: searchRepository),
          RepositoryProvider.value(value: eventsRepository),
          RepositoryProvider.value(value: notificationsRepository),
        ],
        child: Builder(
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => AuthBloc(authRepository)),
                BlocProvider(create: (_) => PhotosBloc(photosRepository)),
                BlocProvider(create: (_) => PhotoDetailBloc(photosRepository)),
                BlocProvider(
                  create: (_) => EventsBloc(eventsRepository, authRepository),
                ),
                BlocProvider(create: (_) => EventCreateBloc(eventsRepository)),
                BlocProvider(
                  create: (ctx) {
                    _notificationsBloc = NotificationsBloc(
                      ctx.read<NotificationsRepository>(),
                    )..add(NotificationsInitialized());
                    return _notificationsBloc!;
                  },
                ),
              ],
              child: Builder(
                builder: (context) {
                  // Listen to auth state changes to cleanup notifications on logout
                  _authSubscription?.cancel();
                  _authSubscription = context.read<AuthBloc>().stream.listen((
                    authState,
                  ) {
                    if (authState.status == AuthStatus.unauthenticated) {
                      _notificationsBloc?.add(NotificationsDisconnect());
                    } else if (authState.status == AuthStatus.authenticated) {
                      _notificationsBloc?.add(NotificationsInitialized());
                    }
                  });

                  return MaterialApp.router(
                    title: appName,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: ThemeMode.system,
                    routerConfig: router,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
