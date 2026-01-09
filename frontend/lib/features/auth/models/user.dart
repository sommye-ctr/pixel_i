import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? profilePicture;
  final String? batch;
  final String? department;
  final String? bio;
  final int? photosCount;
  final int? eventsCount;
  final int? likesCount;
  final int? downloadsCount;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profilePicture,
    this.batch,
    this.department,
    this.bio,
    this.photosCount,
    this.eventsCount,
    this.likesCount,
    this.downloadsCount,
  });

  @override
  List<Object?> get props {
    return [
      id,
      name,
      email,
      username,
      profilePicture,
      batch,
      department,
      bio,
      photosCount,
      eventsCount,
      likesCount,
      downloadsCount,
    ];
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    ValueGetter<String?>? profilePicture,
    ValueGetter<String?>? batch,
    ValueGetter<String?>? department,
    ValueGetter<String?>? bio,
    ValueGetter<int?>? photosCount,
    ValueGetter<int?>? eventsCount,
    ValueGetter<int?>? likesCount,
    ValueGetter<int?>? downloadsCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePicture: profilePicture != null
          ? profilePicture()
          : this.profilePicture,
      batch: batch != null ? batch() : this.batch,
      department: department != null ? department() : this.department,
      bio: bio != null ? bio() : this.bio,
      photosCount: photosCount != null ? photosCount() : this.photosCount,
      eventsCount: eventsCount != null ? eventsCount() : this.eventsCount,
      likesCount: likesCount != null ? likesCount() : this.likesCount,
      downloadsCount: downloadsCount != null
          ? downloadsCount()
          : this.downloadsCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'profile_pic': profilePicture,
      'batch': batch,
      'department': department,
      'bio': bio,
      'photos_count': photosCount,
      'events_count': eventsCount,
      'likes_count': likesCount,
      'downloads_count': downloadsCount,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profilePicture: map['profile_pic'],
      batch: map['batch'],
      department: map['department'],
      bio: map['bio'],
      photosCount: map['photos_count']?.toInt(),
      eventsCount: map['events_count']?.toInt(),
      likesCount: map['likes_count']?.toInt(),
      downloadsCount: map['downloads_count']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, username: $username, profilePicture: $profilePicture, batch: $batch, department: $department, bio: $bio, photosCount: $photosCount, eventsCount: $eventsCount, likesCount: $likesCount, downloadsCount: $downloadsCount)';
  }
}
