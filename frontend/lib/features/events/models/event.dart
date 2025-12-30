import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:frontend/features/auth/models/user.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String readPerm;
  final User coordinator;
  final int imagesCount;
  final String imageUrl;

  const Event({
    required this.id,
    required this.title,
    required this.readPerm,
    required this.coordinator,
    required this.imagesCount,
    required this.imageUrl,
  });

  @override
  List<Object?> get props {
    return [id, title, readPerm, coordinator, imagesCount, imageUrl];
  }

  Event copyWith({
    String? id,
    String? title,
    String? readPerm,
    User? coordinator,
    int? imagesCount,
    String? imageUrl,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      readPerm: readPerm ?? this.readPerm,
      coordinator: coordinator ?? this.coordinator,
      imagesCount: imagesCount ?? this.imagesCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'read_perm': readPerm,
      'coordinator': coordinator.toMap(),
      'images_count': imagesCount,
      'image_url': imageUrl,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      readPerm: map['read_perm'] ?? 'PUB',
      coordinator: User.fromMap(map['coordinator']),
      imagesCount: map['images_count']?.toInt() ?? 0,
      imageUrl: map['image_url'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Event.fromJson(String source) => Event.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Event(id: $id, title: $title, readPerm: $readPerm, coordinator: $coordinator, imagesCount: $imagesCount, imageUrl: $imageUrl)';
  }
}
