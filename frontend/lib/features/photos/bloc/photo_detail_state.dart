import 'package:equatable/equatable.dart';
import '../models/photo.dart';

abstract class PhotoDetailState extends Equatable {
  const PhotoDetailState();

  @override
  List<Object?> get props => [];
}

class PhotoDetailInitial extends PhotoDetailState {}

class PhotoDetailLoadInProgress extends PhotoDetailState {}

class PhotoDetailLoadSuccess extends PhotoDetailState {
  final Photo photo;

  const PhotoDetailLoadSuccess(this.photo);

  @override
  List<Object?> get props => [photo];
}

class PhotoDetailLoadFailure extends PhotoDetailState {
  final String error;

  const PhotoDetailLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class PhotoLikeInProgress extends PhotoDetailState {
  final Photo photo;

  const PhotoLikeInProgress(this.photo);

  @override
  List<Object?> get props => [photo];
}

class PhotoLikeSuccess extends PhotoDetailState {
  final Photo photo;

  const PhotoLikeSuccess(this.photo);

  @override
  List<Object?> get props => [photo];
}

class PhotoLikeFailure extends PhotoDetailState {
  final Photo photo;
  final String error;

  const PhotoLikeFailure(this.photo, this.error);

  @override
  List<Object?> get props => [photo, error];
}
