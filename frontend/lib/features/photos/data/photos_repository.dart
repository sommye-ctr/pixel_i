import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/photo.dart';
import '../models/photo_bulk_upload_result.dart';
import '../models/photo_upload_metadata.dart';

class PhotosRepository {
  final ApiClient api;

  List<Photo>? _cachedPhotos;

  PhotosRepository(this.api);

  List<Photo>? get cachedPhotos => _cachedPhotos;

  Photo? getById(String id) {
    final photos = _cachedPhotos;
    if (photos == null) return null;
    try {
      return photos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void upsertPhoto(Photo photo) {
    _cachedPhotos ??= <Photo>[];
    final index = _cachedPhotos!.indexWhere((p) => p.id == photo.id);
    if (index == -1) {
      _cachedPhotos!.add(photo);
    } else {
      _cachedPhotos![index] = photo;
    }
  }

  Future<List<Photo>> fetchPhotos() async {
    final res = await api.get<List<dynamic>>('/photos/');
    final data = res.data ?? [];
    _cachedPhotos = data
        .map((e) => Photo.fromMap(e as Map<String, dynamic>))
        .toList();
    return _cachedPhotos!;
  }

  Future<Photo> fetchPhotoById(String id) async {
    final res = await api.get<Map<String, dynamic>>('/photos/$id/');
    final data = res.data;
    if (data != null) {
      final photo = Photo.fromMap(data);
      upsertPhoto(photo);
      return photo;
    }
    throw Exception('Photo not found');
  }

  Future<Photo> toggleLikePhoto(String photoId, bool like) async {
    String endpoint = '/photos/$photoId/likes/';
    final res = await (like
        ? api.post<Map<String, dynamic>>(endpoint)
        : api.delete<Map<String, dynamic>>(endpoint));
    final data = res.data;
    if (data != null) {
      final updatedPhoto =
          Photo.fromMap(data['photo'] as Map<String, dynamic>);
      upsertPhoto(updatedPhoto);
      return updatedPhoto;
    }
    throw Exception('Failed to toggle like on photo');
  }

  Future<List<PhotoBulkUploadResult>> bulkUploadPhotos({
    required String eventId,
    required List<PlatformFile> files,
    required List<PhotoUploadMetadata> metadata,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    final formData = FormData();

    formData.fields.add(
      MapEntry(
        'metadata',
        json.encode(metadata.map((m) => m.toMap()).toList()),
      ),
    );

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final meta = metadata[i];
      if (file.path != null) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(file.path!, filename: meta.clientId),
          ),
        );
      } else if (file.bytes != null) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(file.bytes!, filename: meta.clientId),
          ),
        );
      }
    }

    final res = await api.dio.post<Map<String, dynamic>>(
      '/events/$eventId/photos/bulk-upload/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );

    final data = res.data;
    if (data == null) return [];

    final results = data['results'];
    if (results is List) {
      return results
          .map(
            (e) => PhotoBulkUploadResult.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }

    return [];
  }
}
