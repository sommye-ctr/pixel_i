import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/resources/strings.dart';
import 'photo_upload_event.dart';
import 'photo_upload_state.dart';

class PhotoUploadBloc extends Bloc<PhotoUploadEvent, PhotoUploadState> {
  static const int maxFiles = 20;

  PhotoUploadBloc() : super(const PhotoUploadState()) {
    on<PhotoUploadPickRequested>(_onPickRequested);
    on<PhotoUploadCleared>(_onCleared);
    on<PhotoUploadHydrate>(_onHydrate);
  }

  Future<void> _onPickRequested(
    PhotoUploadPickRequested event,
    Emitter<PhotoUploadState> emit,
  ) async {
    if (state.picking) return;
    emit(state.copyWith(picking: true, error: null));

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) {
      emit(state.copyWith(picking: false));
      return;
    }

    final files = result.files;
    if (files.length > maxFiles) {
      emit(state.copyWith(picking: false, error: photoUploadTooMany));
      return;
    }

    emit(state.copyWith(picking: false, files: files, error: null));
  }

  void _onCleared(PhotoUploadCleared event, Emitter<PhotoUploadState> emit) {
    emit(state.copyWith(files: const [], error: null));
  }

  void _onHydrate(PhotoUploadHydrate event, Emitter<PhotoUploadState> emit) {
    final files = event.files;
    if (files.length > maxFiles) {
      emit(state.copyWith(error: photoUploadTooMany));
    } else {
      emit(state.copyWith(files: files, error: null));
    }
  }
}
