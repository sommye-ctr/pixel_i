import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/features/auth/models/user.dart';

enum PhotoReadPermission {
  pub('PUB', 'Public'),
  img('IMG', 'IMG Member'),
  prv('PRV', 'Private');

  final String value;
  final String label;

  const PhotoReadPermission(this.value, this.label);

  factory PhotoReadPermission.fromValue(String value) {
    return PhotoReadPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => PhotoReadPermission.pub,
    );
  }
}

enum PhotoSharePermission {
  ownerRoles('OR', 'Owner or Roles'),
  anyone('AN', 'Anyone'),
  disabled('DI', 'Disabled');

  final String value;
  final String label;

  const PhotoSharePermission(this.value, this.label);

  factory PhotoSharePermission.fromValue(String value) {
    return PhotoSharePermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => PhotoSharePermission.disabled,
    );
  }
}

class Photo {
  final String id;
  final String thumbnailUrl;
  final DateTime timestamp;
  final User photographer;
  final int? width;
  final int? height;

  final Map<String, dynamic>? meta;
  //final Event? event
  final List<User>? taggedUsers;
  final int? downloads;
  final int? views;
  final PhotoReadPermission? readPerm;
  final PhotoSharePermission? sharePerm;
  final String? originalUrl;
  final int? likesCount;
  final bool? isLiked;
  Photo({
    required this.id,
    required this.thumbnailUrl,
    required this.timestamp,
    required this.photographer,
    this.width,
    this.height,
    this.meta,
    this.taggedUsers,
    this.downloads,
    this.views,
    this.readPerm,
    this.sharePerm,
    this.originalUrl,
    this.likesCount,
    this.isLiked,
  });

  Photo.cover({
    required String id,
    required String thumbnailUrl,
    int? width,
    int? height,
  }) : this(
         id: id,
         thumbnailUrl: thumbnailUrl,
         timestamp: DateTime.fromMillisecondsSinceEpoch(0),
         photographer: const User(id: '', name: '', email: '', username: ''),
         width: width,
         height: height,
       );

  Photo copyWith({
    String? id,
    String? thumbnailUrl,
    DateTime? timestamp,
    User? photographer,
    ValueGetter<int?>? width,
    ValueGetter<int?>? height,
    ValueGetter<Map<String, dynamic>?>? meta,
    ValueGetter<List<User>?>? taggedUsers,
    ValueGetter<int?>? downloads,
    ValueGetter<int?>? views,
    ValueGetter<PhotoReadPermission?>? readPerm,
    ValueGetter<PhotoSharePermission?>? sharePerm,
    ValueGetter<String?>? originalUrl,
    ValueGetter<int?>? likesCount,
    ValueGetter<bool?>? isLiked,
  }) {
    return Photo(
      id: id ?? this.id,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      timestamp: timestamp ?? this.timestamp,
      photographer: photographer ?? this.photographer,
      width: width != null ? width() : this.width,
      height: height != null ? height() : this.height,
      meta: meta != null ? meta() : this.meta,
      taggedUsers: taggedUsers != null ? taggedUsers() : this.taggedUsers,
      downloads: downloads != null ? downloads() : this.downloads,
      views: views != null ? views() : this.views,
      readPerm: readPerm != null ? readPerm() : this.readPerm,
      sharePerm: sharePerm != null ? sharePerm() : this.sharePerm,
      originalUrl: originalUrl != null ? originalUrl() : this.originalUrl,
      likesCount: likesCount != null ? likesCount() : this.likesCount,
      isLiked: isLiked != null ? isLiked() : this.isLiked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thumbnail_url': thumbnailUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'photographer': photographer.toMap(),
      'width': width,
      'height': height,
      'meta': meta,
      'tagged_users': taggedUsers?.map((x) => x.toMap()).toList(),
      'downloads': downloads,
      'views': views,
      'read_perm': readPerm?.value,
      'share_perm': sharePerm?.value,
      'original_url': originalUrl,
      'likes_count': likesCount,
      'is_liked': isLiked,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] ?? '',
      thumbnailUrl: map['thumbnail_url'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      photographer: User.fromMap(map['photographer']),
      width: map['width'] != null ? (map['width'] as num).toInt() : null,
      height: map['height'] != null ? (map['height'] as num).toInt() : null,
      meta: Map<String, dynamic>.from(map['meta'] ?? {}),
      taggedUsers: map['tagged_users'] != null
          ? List<User>.from(map['tagged_users']?.map((x) => User.fromMap(x)))
          : null,
      downloads: map['downloads']?.toInt(),
      views: map['views']?.toInt(),
        readPerm: map['read_perm'] != null
          ? PhotoReadPermission.fromValue(map['read_perm'])
          : null,
        sharePerm: map['share_perm'] != null
          ? PhotoSharePermission.fromValue(map['share_perm'])
          : null,
      originalUrl: map['original_url'],
      likesCount: map['likes_count']?.toInt(),
      isLiked: map['is_liked'] == null ? null : map['is_liked'] as bool,
    );
  }

  factory Photo.fromCoverMap(Map<String, dynamic> map) {
    return Photo.cover(
      id: map['id'] ?? '',
      thumbnailUrl: map['thumbnail_url'] ?? '',
      width: map['width'] != null ? (map['width'] as num).toInt() : null,
      height: map['height'] != null ? (map['height'] as num).toInt() : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Photo.fromJson(String source) => Photo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Photo(id: $id, thumbnailUrl: $thumbnailUrl, timestamp: $timestamp, photographer: $photographer, width: $width, height: $height, meta: $meta, taggedUsers: $taggedUsers, downloads: $downloads, views: $views, readPerm: $readPerm, sharePerm: $sharePerm, originalUrl: $originalUrl, likesCount: $likesCount, isLiked: $isLiked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Photo &&
        other.id == id &&
        other.thumbnailUrl == thumbnailUrl &&
        other.timestamp == timestamp &&
        other.photographer == photographer &&
        other.width == width &&
        other.height == height &&
        mapEquals(other.meta, meta) &&
        listEquals(other.taggedUsers, taggedUsers) &&
        other.downloads == downloads &&
        other.views == views &&
        other.readPerm == readPerm &&
        other.sharePerm == sharePerm &&
        other.originalUrl == originalUrl &&
        other.likesCount == likesCount &&
        other.isLiked == isLiked;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        thumbnailUrl.hashCode ^
        timestamp.hashCode ^
        photographer.hashCode ^
        width.hashCode ^
        height.hashCode ^
        meta.hashCode ^
        taggedUsers.hashCode ^
        downloads.hashCode ^
        views.hashCode ^
        readPerm.hashCode ^
        sharePerm.hashCode ^
        originalUrl.hashCode ^
        likesCount.hashCode ^
        isLiked.hashCode;
  }
}
