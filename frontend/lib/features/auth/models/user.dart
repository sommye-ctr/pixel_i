import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? batch;
  final String? department;

  const User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.batch,
    this.department,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, batch, department];
}
