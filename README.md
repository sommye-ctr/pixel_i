<p align="center">
	<img src="backend/pixel-i.png" alt="Pixel-i logo" width="180" />
</p>

# Pixel-i

Pixel-i is a full-stack event-centric photo sharing platform built with a Django REST backend and a Flutter client. The system is designed around permissioned media distribution, authenticated user identity, realtime notifications, and a mobile-first upload and discovery experience.

## Product Overview

Pixel-i organizes media around events and treats photos as first-class domain entities with lifecycle state, metadata, tagging, and access-control semantics. The backend exposes a JWT-secured REST API, while the Flutter application handles token bootstrap, navigation, and state orchestration through a BLoC-driven UI.

## Core Capabilities

- JWT authentication with signup, login, token refresh, and authenticated profile retrieval.
- Email verification flows backed by OTP generation and resend support.
- Custom user profiles with role-aware access control and optional OAuth account linkage.
- Event-centric media organization with event-scoped photo ingestion.
- Bulk photo upload, tagging, and metadata persistence.
- Permission-aware media access with read and share policies for originals and watermarked variants.
- Engagement primitives including likes, threaded comments, and one-level reply constraints.
- Realtime notifications delivered over WebSockets through Django Channels.
- Search surfaces for users and photos, with a secure mobile client bootstrap that restores stored credentials on launch.

## System Architecture

| Layer | Responsibility |
| --- | --- |
| Flutter client | UI composition, navigation via `go_router`, token persistence, and BLoC-based state management. |
| Django API | REST endpoints for auth, events, photos, engagement, and notifications. |
| Realtime channel | WebSocket notifications at `ws/notifications/`, authenticated by a JWT middleware. |
| Async processing | Celery worker integration for background jobs. |
| Data plane | Relational persistence plus Redis-backed broker and channel layer configuration. |

## Backend Domain Model

- `CustomUser` extends Django's auth user with email uniqueness, display name, profile metadata, and a role foreign key.
- `Event` groups uploads and defines read/write permissions.
- `Photo` stores media state, read/share permissions, dimensions, derived URLs, engagement counters, and tagging data.
- `PhotoTag` enforces unique user-photo tagging.
- `PhotoShare` issues expiring share tokens for original or watermarked variants.
- `Comment` supports a single nesting level for replies.
- `Like` enforces one like per user per photo.
- `Notification` records actor-target events such as tagged, liked, commented, and event-photo-added activity.

## API Surface

### Auth

- `POST /auth/signup/`
- `POST /auth/login/`
- `POST /auth/verify-email/`
- `POST /auth/resend-email-otp/`
- `GET /auth/search/`
- `GET /auth/me/`
- `POST /auth/token/refresh/`

### Events

- `GET /events/` and related router-backed event operations.
- `GET /events/<event_id>/photos/`
- `POST /events/<event_id>/photos/bulk-upload/`

### Photos

- `GET /photos/`
- `GET /photos/search/`
- `GET /photos/photos-tagged-in/`
- `POST /photos/<photo_id>/share/`
- `GET /photos/share/<token>/`

### Engagement

- `GET /photos/<photo_id>/likes/`
- `GET /photos/<photo_id>/comments/`
- `DELETE /photos/<photo_id>/comments/<comment_id>/`
- `GET /comments/<comment_id>/children/`

### Notifications

- `GET /notifications/`
- `PATCH /notifications/<id>/`
- WebSocket stream: `ws/notifications/`

## Screenshots

Add real captures under `docs/screenshots/` and reference them here. Recommended views:

| Screen | Suggested file | What it demonstrates |
| --- | --- | --- |
| Authentication | `docs/screenshots/auth.png` | Signup, login, OTP verification, and token bootstrap. |
| Home dashboard | `docs/screenshots/home.png` | Primary landing surface after credential restoration. |
| Event detail | `docs/screenshots/event-detail.png` | Event-scoped gallery, metadata, and upload entry points. |
| Photo detail | `docs/screenshots/photo-detail.png` | Full-resolution media view, likes, comments, and tagging context. |
| Upload flow | `docs/screenshots/photo-upload.png` | Bulk ingestion, tagging, and upload state transitions. |
| Notifications | `docs/screenshots/notifications.png` | Read/unread notification state and realtime delivery. |

## Local Development

### Backend

The backend expects a Python virtual environment, a `DATABASE_URL`, and Redis for Celery plus the Channels layer.

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install django djangorestframework djangorestframework-simplejwt channels channels-redis dj-database-url python-dotenv celery psycopg2-binary

export DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/pixel_i
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
celery -A pixel_i worker -l info
```

### Frontend

The Flutter client reads the backend and WebSocket base URLs from `dart-define` values.

```bash
cd frontend
flutter pub get
flutter run \
	--dart-define=BACKEND_URL=http://localhost:8000 \
	--dart-define=WS_BASE_URL=ws://localhost:8000
```

## Configuration

- `DATABASE_URL` - Database connection string consumed by `dj-database-url`.
- `BACKEND_URL` - HTTP API base URL for the Flutter client.
- `WS_BASE_URL` - WebSocket base URL for realtime notifications.
- Redis defaults to `redis://localhost:6379/0` for Celery and the channel layer.

## Frontend Stack

- `flutter_bloc` for state boundaries and side-effect orchestration.
- `go_router` for declarative route management and deep-linkable screens.
- `flutter_secure_storage` for persisted auth tokens.
- `dio` for API transport.
- `web_socket_channel` for realtime notification streams.
- `cached_network_image`, `photo_view`, and `flutter_staggered_grid_view` for media-heavy UX.

## Backend Stack

- Django 5.x style project layout with a custom auth model.
- Django REST Framework for HTTP APIs.
- SimpleJWT for access and refresh token management.
- Channels for ASGI WebSocket support.
- Celery for asynchronous background execution.
- Redis as the broker and channel-layer transport.

## Repository Layout

```text
backend/   Django project, domain apps, ASGI entry point, and migrations
frontend/  Flutter app, feature modules, assets, and platform targets
README.md  Project documentation
```

## Notes

- The backend uses a custom user model, so `AUTH_USER_MODEL` must remain consistent across migrations.
- Notification delivery is split between persisted notification rows and the WebSocket channel for realtime fanout.
- Photo access is permission-driven, so read and share policies should be treated as part of the domain contract rather than presentation logic.
