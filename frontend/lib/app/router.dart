import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/signup_screen.dart';
import '../features/auth/view/fill_profile_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/photos/view/photo_detail_screen.dart';
import '../features/events/views/event_detail_screen.dart';

GoRouter buildRouter({bool isLoggedIn = false}) {
  return GoRouter(
    initialLocation: isLoggedIn ? '/' : '/signup',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/user-info',
        name: 'user-info',
        builder: (context, state) => const FillProfileScreen(),
      ),
      GoRoute(
        path: '/photo/:id',
        name: 'photo-detail',
        builder: (context, state) {
          final photoId = state.pathParameters['id']!;
          final heroTag =
              state.uri.queryParameters['heroTag'] ?? 'photo-$photoId';
          final thumbnailUrl = state.uri.queryParameters['thumbnailUrl'];
          return PhotoDetailScreen(
            photoId: photoId,
            heroTag: heroTag,
            thumbnailUrl: thumbnailUrl,
          );
        },
      ),
      GoRoute(
        path: '/event/:id',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? 'Event';
          return EventDetailScreen(eventId: eventId, title: title);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
}
