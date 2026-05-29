import 'package:equatable/equatable.dart';
import '../models/photo.dart';

abstract class PhotosState extends Equatable {
  const PhotosState();

  @override
  List<Object?> get props => [];
}

class PhotosInitial extends PhotosState {}

class PhotosLoadInProgress extends PhotosState {}

class PhotosLoadSuccess extends PhotosState {
  final List<Photo> photos;
  final bool showingFavorites;
  final String? nextUrl;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const PhotosLoadSuccess(
    this.photos, {
    this.showingFavorites = false,
    this.nextUrl,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  PhotosLoadSuccess copyWith({
    List<Photo>? photos,
    bool? showingFavorites,
    String? nextUrl,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return PhotosLoadSuccess(
      photos ?? this.photos,
      showingFavorites: showingFavorites ?? this.showingFavorites,
      nextUrl: nextUrl ?? this.nextUrl,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    photos,
    showingFavorites,
    nextUrl,
    hasReachedMax,
    isLoadingMore,
  ];
}

class PhotosLoadFailure extends PhotosState {
  final String error;

  const PhotosLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
