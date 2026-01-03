import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo.dart';

class PhotoUploadMetadata extends Equatable {
  final String clientId;
  final PhotoReadPermission readPerm;
  final PhotoSharePermission sharePerm;
  final List<String> taggedUsernames;
  final List<String> userTags;

  const PhotoUploadMetadata({
    required this.clientId,
    this.readPerm = PhotoReadPermission.pub,
    this.sharePerm = PhotoSharePermission.anyone,
    this.taggedUsernames = const [],
    this.userTags = const [],
  });

  factory PhotoUploadMetadata.fromPlatformFile(
    PlatformFile file,
    String clientId,
  ) {
    return PhotoUploadMetadata(clientId: clientId);
  }

  PhotoUploadMetadata copyWith({
    String? clientId,
    PhotoReadPermission? readPerm,
    PhotoSharePermission? sharePerm,
    List<String>? taggedUsernames,
    List<String>? userTags,
  }) {
    return PhotoUploadMetadata(
      clientId: clientId ?? this.clientId,
      readPerm: readPerm ?? this.readPerm,
      sharePerm: sharePerm ?? this.sharePerm,
      taggedUsernames: taggedUsernames ?? this.taggedUsernames,
      userTags: userTags ?? this.userTags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'read_perm': readPerm.value,
      'share_perm': sharePerm.value,
      'tagged_usernames': taggedUsernames,
      'user_tags': userTags,
    };
  }

  @override
  List<Object?> get props => [
    clientId,
    readPerm,
    sharePerm,
    taggedUsernames,
    userTags,
  ];
}
