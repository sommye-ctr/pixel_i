import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/photos/models/photo.dart';

class EventsRepository {
  final ApiClient apiClient;
  List<Event>? _cachedEvents;

  EventsRepository(this.apiClient);

  List<Event>? get cachedEvents => _cachedEvents;

  Future<List<Event>> fetchEvents() async {
    final res = await apiClient.get<List<dynamic>>('/events/');
    final data = res.data ?? [];
    _cachedEvents = data
        .map((e) => Event.fromMap(e as Map<String, dynamic>))
        .toList();
    return _cachedEvents!;
  }

  Event? getEventFromCache(String eventId) {
    if (_cachedEvents == null) return null;
    try {
      return _cachedEvents!.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  Future<Event> createEvent({
    required String title,
    required String readPerm,
    required String writePerm,
  }) async {
    final res = await apiClient.post<Map<String, dynamic>>(
      '/events/',
      data: {'title': title, 'read_perm': readPerm, 'write_perm': writePerm},
    );
    final data = res.data ?? {};
    final newEvent = Event.fromMap(data);

    if (_cachedEvents != null) {
      _cachedEvents!.add(newEvent);
    }

    return newEvent;
  }

  Future<List<Photo>> fetchEventPhotos(String eventId) async {
    final res = await apiClient.get<List<dynamic>>('/events/$eventId/photos/');
    final data = res.data ?? [];
    final photos = data
        .map((e) => Photo.fromMap(e as Map<String, dynamic>))
        .toList();

    updateEventPhotosInCache(eventId, photos);

    return photos;
  }

  void updateEventInCache(Event updatedEvent) {
    if (_cachedEvents == null) return;

    try {
      final eventIndex = _cachedEvents!.indexWhere(
        (e) => e.id == updatedEvent.id,
      );
      if (eventIndex != -1) {
        _cachedEvents![eventIndex] = updatedEvent;
      }
    } catch (e) {
      // Silently fail if event not found
    }
  }

  void updateEventPhotosInCache(String eventId, List<Photo> photos) {
    if (_cachedEvents == null) return;

    try {
      final eventIndex = _cachedEvents!.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        _cachedEvents![eventIndex] = _cachedEvents![eventIndex].copyWith(
          imagesCount: photos.length,
        );
      }
    } catch (e) {
      // Silently fail if event not found
    }
  }

  void clearCache() {
    _cachedEvents = null;
  }
}
