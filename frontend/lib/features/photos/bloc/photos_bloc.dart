import 'package:bloc/bloc.dart';

import '../../photos/data/photos_repository.dart';
import 'photos_event.dart';
import 'photos_state.dart';

class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  final PhotosRepository repository;

  PhotosBloc(this.repository) : super(PhotosInitial()) {
    on<PhotosRequested>(_onRequested);
  }

  Future<void> _onRequested(
    PhotosRequested event,
    Emitter<PhotosState> emit,
  ) async {
    emit(PhotosLoadInProgress());
    try {
      final photos = await repository.fetchPhotos();
      photos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(PhotosLoadSuccess(photos));
    } catch (e) {
      emit(PhotosLoadFailure(e.toString()));
    }
  }
}
