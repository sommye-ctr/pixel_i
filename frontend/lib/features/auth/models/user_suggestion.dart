import 'package:equatable/equatable.dart';

class UserSuggestion extends Equatable {
  final String username;
  final String name;
  final String? profilePic;

  const UserSuggestion({
    required this.username,
    required this.name,
    this.profilePic,
  });

  factory UserSuggestion.fromMap(Map<String, dynamic> map) {
    return UserSuggestion(
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profile_pic'],
    );
  }

  @override
  List<Object?> get props => [username, name, profilePic];
}
