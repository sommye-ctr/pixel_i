import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:frontend/core/utils/index.dart';

import '../../../core/network/api_client.dart';
import '../models/photo.dart';
import '../models/photo_bulk_upload_result.dart';
import '../models/photo_upload_metadata.dart';

class PhotosRepository {
  final ApiClient api;

  PhotosRepository(this.api);

  Future<List<Photo>> fetchPhotos() async {
    // final res = await api.get<List<dynamic>>('/photos/');
    // final data = res.data ?? [];
    // if (data is List) {
    //   return data.map((e) => Photo.fromMap(e as Map<String, dynamic>)).toList();
    // }
    // throw Exception('Unexpected response format for photos');

    // Development
    final jsonStr = await rootBundle.loadString('assets/json/photos.json');
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    return data
        .map((e) => Photo.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Photo> fetchPhotoById(String id) async {
    // final res = await api.get<Map<String, dynamic>>('/photos/$id/');
    // final data = res.data;
    // if (data != null) {
    //   return Photo.fromMap(data);
    // }
    // throw Exception('Photo not found');

    // Development: load from local JSON and find by ID
    final jsonStr = await rootBundle.loadString('assets/json/photos.json');
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    final photoMap = data.firstWhere(
      (e) => e['id'].toString() == id,
      orElse: () => throw Exception('Photo not found'),
    );
    return Photo.fromMap(Map<String, dynamic>.from(photoMap as Map));
  }

  Future<Photo> toggleLikePhoto(Photo photo) async {
    // final res = await api.post<Map<String, dynamic>>('/photos/$photoId/toggle-like/');
    // final data = res.data;
    // if (data != null) {
    //   return Photo.fromMap(data);
    // }
    // throw Exception('Failed to toggle like on photo');

    // Development: update local state (fetch and toggle isLiked)
    return photo.copyWith(isLiked: () => !(photo.isLiked ?? false));
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
      final clientId = meta.clientId;
      final ext = PhotoUtils.getFileExtension(file.name);
      final filename = '$clientId$ext';
      if (file.path != null) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(file.path!, filename: filename),
          ),
        );
      } else if (file.bytes != null) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(file.bytes!, filename: filename),
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
