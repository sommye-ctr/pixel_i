import 'package:equatable/equatable.dart';
import 'package:frontend/features/events/models/event.dart';

class EventsState extends Equatable {
  final bool showOnlyMyEvents;

  const EventsState({this.showOnlyMyEvents = false});

  @override
  List<Object?> get props => [showOnlyMyEvents];
}

class EventsInitial extends EventsState {
  const EventsInitial({super.showOnlyMyEvents = false});
}

class EventsLoadInProgress extends EventsState {
  const EventsLoadInProgress({super.showOnlyMyEvents = false});
}

class EventsLoadSuccess extends EventsState {
  final List<Event> events;

  const EventsLoadSuccess(this.events, {super.showOnlyMyEvents = false});

  @override
  List<Object?> get props => [events, showOnlyMyEvents];
}

class EventsLoadFailure extends EventsState {
  final String error;

  const EventsLoadFailure(this.error, {super.showOnlyMyEvents = false});

  @override
  List<Object?> get props => [error, showOnlyMyEvents];
}
