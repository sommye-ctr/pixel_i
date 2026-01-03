import 'package:equatable/equatable.dart';
import '../models/photo.dart';

abstract class PhotosEvent extends Equatable {
  const PhotosEvent();

  @override
  List<Object?> get props => [];
}

class PhotosRequested extends PhotosEvent {}

class PhotosFavoritesToggled extends PhotosEvent {}

class PhotoUpdated extends PhotosEvent {
  final Photo photo;

  const PhotoUpdated(this.photo);

  @override
  List<Object?> get props => [photo];
}
