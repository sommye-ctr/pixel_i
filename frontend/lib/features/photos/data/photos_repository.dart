import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/photo.dart';
import '../models/photo_bulk_upload_result.dart';
import '../models/photo_upload_metadata.dart';

class PhotosRepository {
  final ApiClient api;

  PhotosRepository(this.api);

  Future<List<Photo>> fetchPhotos() async {
    final res = await api.get<List<dynamic>>('/photos/');
    final data = res.data ?? [];
    return data.map((e) => Photo.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Photo> fetchPhotoById(String id) async {
    final res = await api.get<Map<String, dynamic>>('/photos/$id/');
    final data = res.data;
    if (data != null) {
      return Photo.fromMap(data);
    }
    throw Exception('Photo not found');
  }

  Future<Photo> toggleLikePhoto(String photoId, bool like) async {
    final res = await api.post<Map<String, dynamic>>(
      '/photos/$photoId/likes/${like ? '' : 'me/'}',
    );
    final data = res.data;
    if (data != null) {
      return Photo.fromMap(data);
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
      '/events/4ff95cd3-04ca-4253-8fc9-e2b0ea8b4e0b/photos/bulk-upload/', //TODO CHANGE THIS TO EVENT ID
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
