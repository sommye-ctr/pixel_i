import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo.dart';

abstract class PhotoUploadEvent extends Equatable {
  const PhotoUploadEvent();

  @override
  List<Object?> get props => [];
}

class PhotoUploadHydrate extends PhotoUploadEvent {
  final List<PlatformFile> files;

  const PhotoUploadHydrate(this.files);

  @override
  List<Object?> get props => [files];
}

class PhotoUploadPageChanged extends PhotoUploadEvent {
  final int index;

  const PhotoUploadPageChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class PhotoUploadMetadataUpdated extends PhotoUploadEvent {
  final int index;
  final PhotoReadPermission? readPerm;
  final PhotoSharePermission? sharePerm;
  final List<String>? userTags;
  final List<String>? taggedUsernames;
  final bool applyToAll;

  const PhotoUploadMetadataUpdated({
    required this.index,
    this.readPerm,
    this.sharePerm,
    this.userTags,
    this.taggedUsernames,
    this.applyToAll = false,
  });

  @override
  List<Object?> get props => [
    index,
    readPerm,
    sharePerm,
    userTags,
    taggedUsernames,
    applyToAll,
  ];
}

class PhotoUploadSubmitted extends PhotoUploadEvent {
  final String eventId;

  const PhotoUploadSubmitted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
