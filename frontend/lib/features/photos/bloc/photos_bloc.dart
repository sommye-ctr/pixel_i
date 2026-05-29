import 'package:bloc/bloc.dart';

import '../../photos/data/photos_repository.dart';
import '../models/photo.dart';
import 'photos_event.dart';
import 'photos_state.dart';

class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  final PhotosRepository repository;
  bool _showFavorites = false;

  PhotosBloc(this.repository) : super(PhotosInitial()) {
    on<PhotosRequested>(_onRequested);
    on<PhotosLoadMoreRequested>(_onLoadMoreRequested);
    on<PhotosFavoritesToggled>(_onFavoritesToggled);
    on<PhotosUpdated>(_onPhotosUpdated);
  }

  Future<void> _onRequested(
    PhotosRequested event,
    Emitter<PhotosState> emit,
  ) async {
    emit(PhotosLoadInProgress());
    try {
      final page = await repository.fetchPhotos();
      final filtered = _filteredPhotos();
      emit(
        PhotosLoadSuccess(
          filtered,
          showingFavorites: _showFavorites,
          nextUrl: page.next,
          hasReachedMax: page.next == null,
        ),
      );
    } catch (e) {
      emit(PhotosLoadFailure(e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    PhotosLoadMoreRequested event,
    Emitter<PhotosState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotosLoadSuccess) {
      if (currentState.hasReachedMax ||
          currentState.isLoadingMore ||
          currentState.nextUrl == null)
        return;

      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final page = await repository.fetchPhotos(url: currentState.nextUrl);
        final filtered = _filteredPhotos();
        emit(
          currentState.copyWith(
            photos: filtered,
            isLoadingMore: false,
            nextUrl: page.next,
            hasReachedMax: page.next == null,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onFavoritesToggled(
    PhotosFavoritesToggled event,
    Emitter<PhotosState> emit,
  ) async {
    _showFavorites = !_showFavorites;
    final filtered = _filteredPhotos();
    final currentState = state;
    if (currentState is PhotosLoadSuccess) {
      emit(
        currentState.copyWith(
          photos: filtered,
          showingFavorites: _showFavorites,
        ),
      );
    } else {
      emit(PhotosLoadSuccess(filtered, showingFavorites: _showFavorites));
    }
  }

  Future<void> _onPhotosUpdated(
    PhotosUpdated event,
    Emitter<PhotosState> emit,
  ) async {
    final filtered = _filteredPhotos();
    final currentState = state;
    if (currentState is PhotosLoadSuccess) {
      emit(currentState.copyWith(photos: filtered));
    } else {
      emit(PhotosLoadSuccess(filtered, showingFavorites: _showFavorites));
    }
  }

  List<Photo> _filteredPhotos() {
    final photos = List<Photo>.from(repository.cachedPhotos ?? const []);
    photos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (_showFavorites) {
      return photos.where((p) => p.isLiked == true).toList();
    }
    return photos;
  }
}
