import 'package:equatable/equatable.dart';

abstract class PhotosEvent extends Equatable {
  const PhotosEvent();

  @override
  List<Object?> get props => [];
}

class PhotosRequested extends PhotosEvent {}
