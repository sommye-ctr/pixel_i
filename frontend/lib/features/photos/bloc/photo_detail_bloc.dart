import 'package:bloc/bloc.dart';

import '../data/photos_repository.dart';
import 'photo_detail_event.dart';
import 'photo_detail_state.dart';

class PhotoDetailBloc extends Bloc<PhotoDetailEvent, PhotoDetailState> {
  final PhotosRepository repository;

  PhotoDetailBloc(this.repository) : super(PhotoDetailInitial()) {
    on<PhotoDetailRequested>(_onRequested);
    on<PhotoLikeToggleRequested>(_onLikeToggleRequested);
  }

  Future<void> _onRequested(
    PhotoDetailRequested event,
    Emitter<PhotoDetailState> emit,
  ) async {
    final cached = repository.getById(event.photoId);
    if (cached != null) {
      emit(PhotoDetailLoadSuccess(cached));
    } else {
      emit(PhotoDetailLoadInProgress());
    }
    try {
      final photo = await repository.fetchPhotoById(event.photoId);
      emit(PhotoDetailLoadSuccess(photo));
    } catch (e) {
      if (cached == null) {
        emit(PhotoDetailLoadFailure(e.toString()));
      }
    }
  }

  Future<void> _onLikeToggleRequested(
    PhotoLikeToggleRequested event,
    Emitter<PhotoDetailState> emit,
  ) async {
    final photo = event.photo;
    emit(PhotoLikeInProgress(photo));

    try {
      final updatedPhoto = await repository.toggleLikePhoto(
        photo.id,
        photo.isLiked != true,
      );
      repository.upsertPhoto(updatedPhoto);
      emit(PhotoLikeSuccess(updatedPhoto));
    } catch (e) {
      emit(PhotoLikeFailure(photo, e.toString()));
    }
  }
}
