import 'package:frontend/features/photos/models/photo.dart';

import '../../../core/network/api_client.dart';

class SearchRepository {
  final ApiClient api;

  SearchRepository(this.api);

  Future<List<Photo>> searchPhotos({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? photographerId,
    String? photographerName,
    List<String>? tags,
    String? readPerm,
    String? eventName,
  }) async {
    final query = <String, dynamic>{};

    if (eventName != null && eventName.isNotEmpty) {
      query['event_name'] = eventName;
    }
    if (dateFrom != null) query['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) query['date_to'] = dateTo.toIso8601String();
    if (photographerId != null && photographerId.isNotEmpty) {
      query['photographer_id'] = photographerId;
    }
    if (photographerName != null && photographerName.isNotEmpty) {
      query['photographer_name'] = photographerName;
    }
    if (tags != null && tags.isNotEmpty) {
      query['tags'] = tags.join(',');
    }
    if (readPerm != null && readPerm.isNotEmpty) query['read_perm'] = readPerm;

    final res = await api.get<Map<String, dynamic>>(
      '/photos/search/',
      query: query,
    );
    final data = res.data ?? {};
    int count = data['count'] as int? ?? 0;
    if (count == 0) return [];
    final results = data['results'] as List<dynamic>? ?? [];
    final photos = results
        .map((e) => Photo.fromMap(e as Map<String, dynamic>))
        .toList();
    return photos;
  }
}
