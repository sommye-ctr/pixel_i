import 'package:bloc/bloc.dart';

import '../../photos/data/photos_repository.dart';
import '../models/photo.dart';
import 'photos_event.dart';
import 'photos_state.dart';

class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  final PhotosRepository repository;
  List<Photo> _allPhotos = [];
  bool _showFavorites = false;

  PhotosBloc(this.repository) : super(PhotosInitial()) {
    on<PhotosRequested>(_onRequested);
    on<PhotosFavoritesToggled>(_onFavoritesToggled);
  }

  Future<void> _onRequested(
    PhotosRequested event,
    Emitter<PhotosState> emit,
  ) async {
    emit(PhotosLoadInProgress());
    try {
      final photos = await repository.fetchPhotos();
      photos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _allPhotos = photos;
      final filtered = _filteredPhotos();
      emit(PhotosLoadSuccess(filtered, showingFavorites: _showFavorites));
    } catch (e) {
      emit(PhotosLoadFailure(e.toString()));
    }
  }

  Future<void> _onFavoritesToggled(
    PhotosFavoritesToggled event,
    Emitter<PhotosState> emit,
  ) async {
    if (_allPhotos.isEmpty) return;

    _showFavorites = !_showFavorites;
    final filtered = _filteredPhotos();
    emit(PhotosLoadSuccess(filtered, showingFavorites: _showFavorites));
  }

  List<Photo> _filteredPhotos() {
    if (_showFavorites) {
      return _allPhotos.where((p) => p.isLiked == true).toList();
    }
    return List<Photo>.from(_allPhotos);
  }
}
