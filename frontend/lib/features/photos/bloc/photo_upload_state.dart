import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

class PhotoUploadState extends Equatable {
  final bool picking;
  final List<PlatformFile> files;
  final String? error;

  const PhotoUploadState({
    this.picking = false,
    this.files = const [],
    this.error,
  });

  PhotoUploadState copyWith({
    bool? picking,
    List<PlatformFile>? files,
    String? error,
  }) {
    return PhotoUploadState(
      picking: picking ?? this.picking,
      files: files ?? this.files,
      error: error,
    );
  }

  @override
  List<Object?> get props => [picking, files, error];
}
