import 'package:equatable/equatable.dart';
import 'package:frontend/features/events/models/event.dart';

class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoadInProgress extends EventsState {}

class EventsLoadSuccess extends EventsState {
  final List<Event> events;

  const EventsLoadSuccess(this.events);

  @override
  List<Object?> get props => [events];
}

class EventsLoadFailure extends EventsState {
  final String error;

  const EventsLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
