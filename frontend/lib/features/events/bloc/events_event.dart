import 'package:equatable/equatable.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class EventsRequested extends EventsEvent {}

class MyEventsRequested extends EventsEvent {
  const MyEventsRequested();
}
