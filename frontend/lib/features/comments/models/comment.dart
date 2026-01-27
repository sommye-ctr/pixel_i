import 'package:frontend/features/auth/models/user.dart';

class Comment {
  final String id;
  final User user;
  final String content;
  final DateTime createdAt;
  final int? childCount;
  final String? parentComment;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    this.childCount,
    this.parentComment,
  });

  Comment copyWith({
    String? id,
    User? user,
    String? content,
    DateTime? createdAt,
    int? childCount,
    String? parentComment,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      childCount: childCount ?? this.childCount,
      parentComment: parentComment ?? this.parentComment,
    );
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      user: User.fromMap(map['user'] as Map<String, dynamic>),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at']),
      childCount: map['child_count'] != null ? map['child_count'] as int : null,
      parentComment: map['parent_comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user.toMap(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'child_count': childCount,
      'parent_comment': parentComment,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.user == user &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.childCount == childCount &&
        other.parentComment == parentComment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        user.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        childCount.hashCode ^
        parentComment.hashCode;
  }
}
