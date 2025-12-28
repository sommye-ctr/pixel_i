import 'package:equatable/equatable.dart';

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
