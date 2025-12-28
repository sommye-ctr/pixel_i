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
}
