import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo_upload_metadata.dart';
import 'package:frontend/features/photos/models/photo_bulk_upload_result.dart';

class PhotoUploadState extends Equatable {
  final List<PlatformFile> files;
  final List<PhotoUploadMetadata> metadata;
  final int currentIndex;
  final bool isUploading;
  final Map<String, PhotoBulkUploadResult> uploadResults;
  final Map<String, double> uploadProgress;
  final String? uploadError;

  const PhotoUploadState({
    this.files = const [],
    this.metadata = const [],
    this.currentIndex = 0,
    this.isUploading = false,
    this.uploadResults = const <String, PhotoBulkUploadResult>{},
    this.uploadProgress = const <String, double>{},
    this.uploadError,
  });

  PhotoUploadState copyWith({
    List<PlatformFile>? files,
    List<PhotoUploadMetadata>? metadata,
    int? currentIndex,
    bool? isUploading,
    Map<String, PhotoBulkUploadResult>? uploadResults,
    Map<String, double>? uploadProgress,
    String? uploadError,
    bool resetUploadError = false,
  }) {
    return PhotoUploadState(
      files: files ?? this.files,
      metadata: metadata ?? this.metadata,
      currentIndex: currentIndex ?? this.currentIndex,
      isUploading: isUploading ?? this.isUploading,
      uploadResults: uploadResults ?? this.uploadResults,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadError: resetUploadError ? null : uploadError ?? this.uploadError,
    );
  }

  PhotoUploadMetadata? get selectedMetadata {
    if (metadata.isEmpty || currentIndex >= metadata.length) return null;
    return metadata[currentIndex];
  }

  @override
  List<Object?> get props => [
    files,
    metadata,
    currentIndex,
    isUploading,
    uploadResults,
    uploadProgress,
    uploadError,
  ];
}
