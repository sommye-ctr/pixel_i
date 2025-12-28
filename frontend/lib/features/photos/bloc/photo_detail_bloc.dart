import 'package:bloc/bloc.dart';

import '../data/photos_repository.dart';
import 'photo_detail_event.dart';
import 'photo_detail_state.dart';

class PhotoDetailBloc extends Bloc<PhotoDetailEvent, PhotoDetailState> {
  final PhotosRepository repository;

  PhotoDetailBloc(this.repository) : super(PhotoDetailInitial()) {
    on<PhotoDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    PhotoDetailRequested event,
    Emitter<PhotoDetailState> emit,
  ) async {
    emit(PhotoDetailLoadInProgress());
    try {
      final photo = await repository.fetchPhotoById(event.photoId);
      emit(PhotoDetailLoadSuccess(photo));
    } catch (e) {
      emit(PhotoDetailLoadFailure(e.toString()));
    }
  }
}
