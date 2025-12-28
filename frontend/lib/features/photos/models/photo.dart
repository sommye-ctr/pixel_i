import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/features/auth/models/user.dart';

class Photo {
  final String id;
  final String thumbnailUrl;
  final DateTime timestamp;
  final User photographer;

  final Map<String, dynamic>? meta;
  //final Event? event
  final List<User>? taggedUsers;
  final int? downloads;
  final int? views;
  final String? readPerm;
  final String? sharePerm;
  final String? originalUrl;
  final int? likesCount;
  Photo({
    required this.id,
    required this.thumbnailUrl,
    required this.timestamp,
    required this.photographer,
    this.meta,
    this.taggedUsers,
    this.downloads,
    this.views,
    this.readPerm,
    this.sharePerm,
    this.originalUrl,
    this.likesCount,
  });

  Photo copyWith({
    String? id,
    String? thumbnailUrl,
    DateTime? timestamp,
    User? photographer,
    ValueGetter<Map<String, dynamic>?>? meta,
    ValueGetter<List<User>?>? taggedUsers,
    ValueGetter<int?>? downloads,
    ValueGetter<int?>? views,
    ValueGetter<String?>? readPerm,
    ValueGetter<String?>? sharePerm,
    ValueGetter<String?>? originalUrl,
    ValueGetter<int?>? likesCount,
  }) {
    return Photo(
      id: id ?? this.id,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      timestamp: timestamp ?? this.timestamp,
      photographer: photographer ?? this.photographer,
      meta: meta != null ? meta() : this.meta,
      taggedUsers: taggedUsers != null ? taggedUsers() : this.taggedUsers,
      downloads: downloads != null ? downloads() : this.downloads,
      views: views != null ? views() : this.views,
      readPerm: readPerm != null ? readPerm() : this.readPerm,
      sharePerm: sharePerm != null ? sharePerm() : this.sharePerm,
      originalUrl: originalUrl != null ? originalUrl() : this.originalUrl,
      likesCount: likesCount != null ? likesCount() : this.likesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thumbnail_url': thumbnailUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'photographer': photographer.toMap(),
      'meta': meta,
      'tagged_users': taggedUsers?.map((x) => x.toMap()).toList(),
      'downloads': downloads,
      'views': views,
      'read_perm': readPerm,
      'share_perm': sharePerm,
      'original_url': originalUrl,
      'likes_count': likesCount,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] ?? '',
      thumbnailUrl: map['thumbnail_url'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      photographer: User.fromMap(map['photographer']),
      meta: Map<String, dynamic>.from(map['meta'] ?? {}),
      taggedUsers: map['tagged_users'] != null
          ? List<User>.from(map['tagged_users']?.map((x) => User.fromMap(x)))
          : null,
      downloads: map['downloads']?.toInt(),
      views: map['views']?.toInt(),
      readPerm: map['read_perm'],
      sharePerm: map['share_perm'],
      originalUrl: map['original_url'],
      likesCount: map['likes_count']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Photo.fromJson(String source) => Photo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Photo(id: $id, thumbnailUrl: $thumbnailUrl, timestamp: $timestamp, photographer: $photographer, meta: $meta, taggedUsers: $taggedUsers, downloads: $downloads, views: $views, readPerm: $readPerm, sharePerm: $sharePerm, originalUrl: $originalUrl, likesCount: $likesCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Photo &&
        other.id == id &&
        other.thumbnailUrl == thumbnailUrl &&
        other.timestamp == timestamp &&
        other.photographer == photographer &&
        mapEquals(other.meta, meta) &&
        listEquals(other.taggedUsers, taggedUsers) &&
        other.downloads == downloads &&
        other.views == views &&
        other.readPerm == readPerm &&
        other.sharePerm == sharePerm &&
        other.originalUrl == originalUrl &&
        other.likesCount == likesCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        thumbnailUrl.hashCode ^
        timestamp.hashCode ^
        photographer.hashCode ^
        meta.hashCode ^
        taggedUsers.hashCode ^
        downloads.hashCode ^
        views.hashCode ^
        readPerm.hashCode ^
        sharePerm.hashCode ^
        originalUrl.hashCode ^
        likesCount.hashCode;
  }
}
