<p align="center">
	<img src="backend/pixel-i.png" alt="Pixel-i logo" width="180" />
</p>

# Pixel-i

Pixel-i is a gorgeous, private photo-sharing app designed to collect and share memories from group events. With a sleek mobile experience, instant notification updates, and secure privacy boundaries, it brings event galleries to life in real time. 

---

## 📸 A Quick Visual Tour

| **Authentication** | **Home Feed (Grid)** | **Staggered Masonry Feed** |
| :---: | :---: | :---: |
| ![Auth Flow](docs/screenshots/auth.png) | ![Home Grid](docs/screenshots/gallery_grid.png) | ![Masonry Feed](docs/screenshots/gallery_masonry.png) |
| *Log in & get verified securely* | *View photos sorted by time* | *Modern, Pinterest-style gallery* |

| **Interactive Photo Detail** | **Events Hub** | **Event Gallery & Upload** |
| :---: | :---: | :---: |
| ![Photo Details](docs/screenshots/photo_detail.png) | ![Events List](docs/screenshots/events_list.png) | ![Event Gallery](docs/screenshots/event_detail.png) |
| *Pinch-to-zoom, tags, & replies* | *View event lists & cover photos* | *Group galleries & upload flow* |

| **Unified Search** | **Real-time Notifications** | **User Profile & Stats** |
| :---: | :---: | :---: |
| ![Search Screen](docs/screenshots/search.png) | ![Notifications](docs/screenshots/notifications.png) | ![Profile Screen](docs/screenshots/profile.png) |
| *Instantly find photos & friends* | *Live alerts for tags & comments* | *Your profile and sharing metrics* |

---

## ✨ Features You'll Love

- **📐 Staggered Gallery Views**: Toggle between a clean, uniform **Grid Layout** and an elegant, flowing **Masonry Layout** with one quick tap.
- **🔍 Smart Unified Search**: Looking for a specific friend, a memorable photo, or an event? Search across everything instantly from one screen.
- **⚡ Instant Real-time Alerts**: Get notified the second someone likes your photo, tags you, or comments, complete with live app badge updates.
- **🔒 Private Group Galleries**: Photos are organized around exclusive events. Create an event, invite your circle, and keep shared memories fully secure.
- **💬 Rich Chats & Interactions**: Like photos with beautiful spring-based heart animations, tag friends, and reply in clean, structured comment threads.
- **🔎 Pinch-to-Zoom & Pan**: Inspect every detail of your photos with native high-res pinch gestures and smooth transitions.
- **🚀 One-Tap Access**: Log in securely once, and the app will keep you signed in so you can dive straight back into your memories.

---

## 🛠️ Under the Hood (Technical Overview)

Pixel-i is engineered as a robust, distributed client-server platform. The system coordinates state and permissions across a JWT-secured Django REST API and a high-performance, reactive Flutter mobile client.

### System Architecture

| System Layer | Core Responsibility |
| --- | --- |
| **Flutter Mobile Client** | UI rendering, Go-Router deep navigation, token persistence, and BLoC-driven state management. |
| **Django REST API** | Stateless REST endpoints for auth, group events, media access policies, and core engagement. |
| **Realtime Gateway** | Persistent WebSocket connection layer (`ws/notifications/`) secured by JWT middleware. |
| **Async Worker Queue** | Celery integration handling background media ingestion, resizing, and watermarking. |
| **Data Plane** | PostgreSQL relational engine, backed by a Redis broker/cache for WebSocket channel fanout. |

### Technology Stack

#### 📱 Frontend (Flutter Mobile Client)

- **State Management**: `flutter_bloc` (^9.0.0) & `equatable` for strict, predictable BLoC state bounds and reactive side-effect handling.
- **Routing & Deep Linking**: `go_router` (^14.4.1) for declarative navigation, hierarchical routing, and auth guards.
- **API Transport**: `dio` (^5.7.0) with custom interceptors for transparent JWT rotation, header injection, and global error mapping.
- **WS Channels**: `web_socket_channel` (^3.0.1) for continuous low-latency WebSocket connection management.
- **Secure Cache**: `flutter_secure_storage` (^10.0.0) for persistent, encrypted hardware key-value storage of auth tokens.
- **Media & UI Components**:
  - `cached_network_image` (^3.4.1) for high-performance disk and memory image caching.
  - `photo_view` (^0.14.0) for fluid multi-touch gesture scale/pan interactions.
  - `flutter_staggered_grid_view` (^0.7.0) for fast, dynamic staggered masonry layouts.
  - `infinite_scroll_pagination` (^4.0.0) for frictionless paginated feed loading.
  - `palette_generator` (^0.3.3) for generating context-driven dynamic color accents.
- **Premium Aesthetics**: `flex_color_scheme` (^8.4.0) for cohesive Material 3 color spaces, combined with Google Fonts and Lucide Icons.

#### ⚙️ Backend (Django REST Framework & Celery)

- **Core Web Application**: Django 5.x structured with an asynchronous-friendly ASGI gateway.
- **Web APIs**: Django REST Framework (DRF) exposing resource routes for events, media models, and activities.
- **Token Security**: SimpleJWT for stateless, secure access and refresh token distribution.
- **Asynchronous Channels**: Django Channels providing ASGI-compatible server configurations for real-time WebSocket protocol handling.
- **Background Tasks**: Celery for asynchronous offloading of intensive media modifications (e.g., watermarking and scaling).
- **Relational Storage**: PostgreSQL relational engine supported by `psycopg2-binary` and `dj-database-url` routing.

---

### Backend Domain Model

- `CustomUser` extends standard auth with email uniqueness, custom display profiles, and role-based permissions.
- `Event` defines permission boundaries and scopes for uploaded files.
- `Photo` stores metadata, access flags (originals vs. watermarked), pixel metrics, and tags.
- `PhotoTag` manages many-to-many user-photo tagging relationships.
- `PhotoShare` issues timed sharing tokens for original or watermarked variants.
- `Comment` structures nested conversations (supports a single nesting tier for replies).
- `Like` enforces a singular like mapping per user-photo instance.
- `Notification` records and dispatches activities (likes, comments, tags, event updates) via Channel Groups.

---

### API Surface

#### Auth & Accounts
- `POST /auth/signup/` - Register new accounts
- `POST /auth/login/` - Authenticate & obtain JWT
- `POST /auth/verify-email/` - OTP validation
- `POST /auth/resend-email-otp/` - Rate-limited OTP resend
- `GET /auth/search/` - Query registered profiles
- `GET /auth/me/` - Retrieve active profile session
- `POST /auth/token/refresh/` - Secure token refresh

#### Events & Ingestion
- `GET /events/` - Fetch available group event feeds
- `GET /events/<event_id>/photos/` - Retrieve event-scoped photos
- `POST /events/<event_id>/photos/bulk-upload/` - Upload batch high-res images

#### Media & Sharing
- `GET /photos/` - General image queries
- `GET /photos/search/` - Specific tags/description lookup
- `GET /photos/photos-tagged-in/` - List photos user is tagged in
- `POST /photos/<photo_id>/share/` - Create a temporary share link
- `GET /photos/share/<token>/` - Resolve token-scoped photo access

#### Social Engagement
- `GET /photos/<photo_id>/likes/` - List photo likes
- `GET /photos/<photo_id>/comments/` - Fetch comments & nested threads
- `DELETE /photos/<photo_id>/comments/<comment_id>/` - Delete comment node
- `GET /comments/<comment_id>/children/` - Query nested comment replies

#### Notification Stream
- `GET /notifications/` - Query historical notifications
- `PATCH /notifications/<id>/` - Set notification status (Read/Unread)
- **WebSocket Route**: `ws/notifications/` - Active real-time notification stream

---

## 💻 Local Development

### Backend Setup

The backend relies on a Python virtual environment, PostgreSQL, and Redis (used for both the Celery worker broker and ASGI Channels layer).

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install django djangorestframework djangorestframework-simplejwt channels channels-redis dj-database-url python-dotenv celery psycopg2-binary

# Set your active Postgres connection string
export DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/pixel_i

# Complete initial database setup & run
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver

# In a separate terminal shell, boot the worker:
celery -A pixel_i worker -l info
```

### Frontend Setup

The Flutter client requires the local server URLs injected via Dart compilation definitions.

```bash
cd frontend
flutter pub get

# Run on your target emulator or physical device
flutter run \
	--dart-define=BACKEND_URL=http://localhost:8000 \
	--dart-define=WS_BASE_URL=ws://localhost:8000
```

### App Configuration

- `DATABASE_URL` - Database connection string consumed by `dj-database-url`.
- `BACKEND_URL` - HTTP API base URL for the Flutter client.
- `WS_BASE_URL` - WebSocket base URL for realtime notifications.
- Redis defaults to `redis://localhost:6379/0` for Celery and the channel layer.

---

### Repository Layout

```text
backend/   Django project, domain apps, ASGI entry point, and migrations
frontend/  Flutter app, feature modules, assets, and platform targets
README.md  Project documentation
```

### Developer Notes

- **Custom Auth**: The custom user model requires a clean database state prior to changing `AUTH_USER_MODEL` configurations.
- **Asynchronous Notifications**: Action events split notification logs into PostgreSQL records and Channel Groups for real-time WebSocket push updates.
- **Media Access Integrity**: Share tokens restrict and validate photo access dynamically on the server side to protect user privacy.
