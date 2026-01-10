import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/signup_screen.dart';
import '../features/auth/view/fill_profile_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/photos/view/photo_detail_screen.dart';
import '../features/photos/view/photo_upload_screen.dart';
import '../features/events/views/event_detail_screen.dart';
import '../features/events/views/event_create_screen.dart';
import '../features/notifications/view/notifications_screen.dart';

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
        path: '/photos/upload',
        name: 'photo-upload',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final files = extra?['files'] as List<PlatformFile>?;
          final eventId = extra?['eventId'] as String?;
          final eventName = extra?['eventName'] as String?;
          return PhotoUploadScreen(
            initialFiles: files,
            eventId: eventId,
            eventName: eventName,
          );
        },
      ),
      GoRoute(
        path: '/event/create',
        name: 'event-create',
        builder: (context, state) => const EventCreateScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? 'Event';
          final fileCountParam = state.uri.queryParameters['files'];
          final fileCount = fileCountParam != null
              ? int.tryParse(fileCountParam)
              : null;
          final createdAtParam = state.uri.queryParameters['createdAt'];
          final createdAt = createdAtParam != null
              ? DateTime.tryParse(createdAtParam)
              : null;
          final coverUrl = state.uri.queryParameters['cover'];
          final canWrite = state.uri.queryParameters['canWrite'] == 'true';

          return EventDetailScreen(
            eventId: eventId,
            title: title,
            fileCount: fileCount,
            createdAt: createdAt,
            coverPhotoUrl: coverUrl,
            canWrite: canWrite,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
}
