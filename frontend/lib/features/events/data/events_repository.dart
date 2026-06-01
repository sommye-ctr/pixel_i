import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:frontend/core/network/paginated_response.dart';

class EventsRepository {
  final ApiClient apiClient;
  List<Event>? _cachedEvents;

  EventsRepository(this.apiClient);

  List<Event>? get cachedEvents => _cachedEvents;

  Future<PaginatedResponse<Event>> fetchEvents({String? url}) async {
    final targetUrl = url ?? '/events/';
    final res = await apiClient.get<Map<String, dynamic>>(targetUrl);
    final data = res.data ?? <String, dynamic>{};
    final page = PaginatedResponse.fromMap(data, Event.fromMap);
    if (url == null) {
      _cachedEvents = List.from(page.results);
    } else {
      _cachedEvents ??= <Event>[];
      _cachedEvents!.addAll(page.results);
    }
    return page;
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

  Future<Event> updateEvent({
    required String eventId,
    String? title,
    String? readPerm,
    String? writePerm,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (readPerm != null) data['read_perm'] = readPerm;
    if (writePerm != null) data['write_perm'] = writePerm;

    final res = await apiClient.patch<Map<String, dynamic>>(
      '/events/$eventId/',
      data: data,
    );
    
    final updatedData = res.data ?? {};
    final updatedEvent = Event.fromMap(updatedData);

    updateEventInCache(updatedEvent);

    return updatedEvent;
  }

  Future<void> deleteEvent(String eventId) async {
    await apiClient.delete<dynamic>('/events/$eventId/');
    
    if (_cachedEvents != null) {
      _cachedEvents!.removeWhere((e) => e.id == eventId);
    }
  }

  Future<PaginatedResponse<Photo>> fetchEventPhotos(String eventId, {String? url}) async {
    final targetUrl = url ?? '/events/$eventId/photos/';
    final res = await apiClient.get<Map<String, dynamic>>(targetUrl);
    final data = res.data ?? <String, dynamic>{};
    final page = PaginatedResponse.fromMap(data, Photo.fromMap);

    updateEventPhotosInCache(eventId, page.results);

    return page;
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
