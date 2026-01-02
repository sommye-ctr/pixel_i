import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo_upload_metadata.dart';
import 'photo_upload_event.dart';
import 'photo_upload_state.dart';

class PhotoUploadBloc extends Bloc<PhotoUploadEvent, PhotoUploadState> {
  static const int maxFiles = 20;

  PhotoUploadBloc() : super(const PhotoUploadState()) {
    on<PhotoUploadHydrate>(_onHydrate);
    on<PhotoUploadPageChanged>(_onPageChanged);
    on<PhotoUploadMetadataUpdated>(_onMetadataUpdated);
  }

  List<PhotoUploadMetadata> _buildMetadata(List<PlatformFile> files) {
    return files.map(PhotoUploadMetadata.fromPlatformFile).toList();
  }

  void _onHydrate(PhotoUploadHydrate event, Emitter<PhotoUploadState> emit) {
    final files = event.files;
    emit(
      state.copyWith(
        files: files,
        metadata: _buildMetadata(files),
        currentIndex: 0,
      ),
    );
  }

  void _onPageChanged(
    PhotoUploadPageChanged event,
    Emitter<PhotoUploadState> emit,
  ) {
    if (state.files.isEmpty) return;
    final clampedIndex = event.index.clamp(0, state.files.length - 1);
    emit(state.copyWith(currentIndex: clampedIndex));
  }

  void _onMetadataUpdated(
    PhotoUploadMetadataUpdated event,
    Emitter<PhotoUploadState> emit,
  ) {
    final index = event.index;
    if (index < 0 || index >= state.metadata.length) return;

    final current = state.metadata[index];
    final updated = current.copyWith(
      readPerm: event.readPerm ?? current.readPerm,
      sharePerm: event.sharePerm ?? current.sharePerm,
      userTags: event.userTags ?? current.userTags,
    );

    final next = List<PhotoUploadMetadata>.from(state.metadata);
    next[index] = updated;

    emit(state.copyWith(metadata: next));
  }
}
