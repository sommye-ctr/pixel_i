import 'package:equatable/equatable.dart';
import '../models/photo.dart';

abstract class PhotoDetailEvent extends Equatable {
  const PhotoDetailEvent();

  @override
  List<Object?> get props => [];
}

class PhotoDetailRequested extends PhotoDetailEvent {
  final String photoId;

  const PhotoDetailRequested(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

class PhotoLikeToggleRequested extends PhotoDetailEvent {
  final Photo photo;

  const PhotoLikeToggleRequested(this.photo);

  @override
  List<Object?> get props => [photo];
}
