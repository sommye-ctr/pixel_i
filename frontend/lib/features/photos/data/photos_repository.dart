import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/network/api_client.dart';
import '../models/photo.dart';

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
}
