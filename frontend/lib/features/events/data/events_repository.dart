import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/photos/models/photo.dart';

class EventsRepository {
  final ApiClient apiClient;
  EventsRepository(this.apiClient);

  Future<List<Event>> fetchEvents() async {
    final res = await apiClient.get<List<dynamic>>('/events/');
    final data = res.data ?? [];
    return data.map((e) => Event.fromMap(e as Map<String, dynamic>)).toList();
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
    return Event.fromMap(data);
  }

  Future<List<Photo>> fetchEventPhotos(String eventId) async {
    final res = await apiClient.get<List<dynamic>>('/events/$eventId/photos/');
    final data = res.data ?? [];
    return data.map((e) => Photo.fromMap(e as Map<String, dynamic>)).toList();
  }
}
