import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

abstract class PhotoUploadEvent extends Equatable {
  const PhotoUploadEvent();

  @override
  List<Object?> get props => [];
}

class PhotoUploadPickRequested extends PhotoUploadEvent {}

class PhotoUploadCleared extends PhotoUploadEvent {}

class PhotoUploadHydrate extends PhotoUploadEvent {
  final List<PlatformFile> files;

  const PhotoUploadHydrate(this.files);

  @override
  List<Object?> get props => [files];
}
