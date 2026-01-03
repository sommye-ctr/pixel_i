import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:frontend/features/auth/models/user.dart';
import 'package:frontend/features/photos/models/photo.dart';

enum EventPermission {
  pub('PUB', 'Public'),
  img('IMG', 'IMG Member'),
  prv('PRV', 'Private');

  final String value;
  final String label;

  const EventPermission(this.value, this.label);

  factory EventPermission.fromValue(String value) {
    return EventPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => EventPermission.pub,
    );
  }

  @override
  String toString() {
    return label;
  }
}

class Event extends Equatable {
  final String id;
  final String title;
  final EventPermission readPerm;
  final EventPermission writePerm;
  final User coordinator;
  final int imagesCount;
  final Photo? coverPhoto;
  final DateTime? createdAt;

  const Event({
    required this.id,
    required this.title,
    required this.readPerm,
    required this.writePerm,
    required this.coordinator,
    required this.imagesCount,
    this.coverPhoto,
    this.createdAt,
  });

  @override
  List<Object?> get props {
    return [
      id,
      title,
      readPerm,
      writePerm,
      coordinator,
      imagesCount,
      coverPhoto,
      createdAt,
    ];
  }

  Event copyWith({
    String? id,
    String? title,
    EventPermission? readPerm,
    EventPermission? writePerm,
    User? coordinator,
    int? imagesCount,
    Photo? coverPhoto,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      readPerm: readPerm ?? this.readPerm,
      writePerm: writePerm ?? this.writePerm,
      coordinator: coordinator ?? this.coordinator,
      imagesCount: imagesCount ?? this.imagesCount,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'read_perm': readPerm.value,
      'write_perm': writePerm.value,
      'coordinator': coordinator.toMap(),
      'images_count': imagesCount,
      'cover_photo': coverPhoto?.toMap(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      readPerm: EventPermission.fromValue(
        map['read_perm'] ?? EventPermission.pub.value,
      ),
      writePerm: EventPermission.fromValue(
        map['write_perm'] ?? EventPermission.pub.value,
      ),
      coordinator: User.fromMap(map['coordinator']),
      imagesCount: map['images_count']?.toInt() ?? 0,
      coverPhoto: map['cover_photo'] != null
          ? Photo.fromCoverMap(map['cover_photo'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Event.fromJson(String source) => Event.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Event(id: $id, title: $title, readPerm: $readPerm, writePerm: $writePerm, coordinator: $coordinator, imagesCount: $imagesCount, coverPhoto: $coverPhoto, createdAt: $createdAt)';
  }
}
