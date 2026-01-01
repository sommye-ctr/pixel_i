import 'package:equatable/equatable.dart';

abstract class EventCreateEvent extends Equatable {
  const EventCreateEvent();

  @override
  List<Object?> get props => [];
}

class EventCreateRequested extends EventCreateEvent {
  final String title;
  final String readPerm;
  final String writePerm;

  const EventCreateRequested({
    required this.title,
    required this.readPerm,
    required this.writePerm,
  });

  @override
  List<Object?> get props => [title, readPerm, writePerm];
}
