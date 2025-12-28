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

  const PhotosLoadSuccess(this.photos);

  @override
  List<Object?> get props => [photos];
}

class PhotosLoadFailure extends PhotosState {
  final String error;

  const PhotosLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
