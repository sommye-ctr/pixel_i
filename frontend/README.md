# Pixel-i

Frontend scaffolding using BLoC for state management, with modular features and a router.

## Structure

- lib/app/
  - app.dart — App root with repositories and BLoCs
  - router.dart — GoRouter routes
- lib/core/
  - config.dart — backend base URL
  - network/api_client.dart — Dio wrapper
  - image_variants.dart — image variant URL builder
- lib/features/
  - auth/ (models, data, bloc, view/login)
  - gallery/ (models, data, bloc, view/gallery)
  - events/ (models, data, bloc, view/events)
  - notifications/ (models, data, bloc, view/notifications)
  - profile/ (view/profile)
- lib/shared/widgets/
  - photo_tile.dart — reusable gallery tile

## Dependencies

`flutter_bloc`, `equatable`, `dio`, `cached_network_image`, `flutter_staggered_grid_view`, `photo_view`, `infinite_scroll_pagination`, `web_socket_channel`, `go_router`, `timeago`.

## Quick Start

```bash
flutter pub get
flutter run -d ios # or -d macos/-d chrome/-d android
```

Optionally set the backend URL at compile time:

```bash
flutter run --dart-define=BACKEND_URL=https://api.example.com
```

## Notes

- BLoCs are initialized in `app/app.dart` via `MultiBlocProvider`.
- Gallery supports lazy loading and optimistic likes.
- Router paths: `/`, `/events`, `/notifications`, `/profile`, `/login`.
