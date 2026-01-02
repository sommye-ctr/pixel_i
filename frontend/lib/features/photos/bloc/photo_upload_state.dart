import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo_upload_metadata.dart';

class PhotoUploadState extends Equatable {
  final List<PlatformFile> files;
  final List<PhotoUploadMetadata> metadata;
  final int currentIndex;

  const PhotoUploadState({
    this.files = const [],
    this.metadata = const [],
    this.currentIndex = 0,
  });

  PhotoUploadState copyWith({
    List<PlatformFile>? files,
    List<PhotoUploadMetadata>? metadata,
    int? currentIndex,
  }) {
    return PhotoUploadState(
      files: files ?? this.files,
      metadata: metadata ?? this.metadata,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  PhotoUploadMetadata? get selectedMetadata {
    if (metadata.isEmpty || currentIndex >= metadata.length) return null;
    return metadata[currentIndex];
  }

  @override
  List<Object?> get props => [files, metadata, currentIndex];
}
