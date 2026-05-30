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
  final String? nextUrl;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const EventsLoadSuccess(
    this.events, {
    super.showOnlyMyEvents = false,
    this.nextUrl,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  EventsLoadSuccess copyWith({
    List<Event>? events,
    bool? showOnlyMyEvents,
    String? nextUrl,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return EventsLoadSuccess(
      events ?? this.events,
      showOnlyMyEvents: showOnlyMyEvents ?? this.showOnlyMyEvents,
      nextUrl: nextUrl ?? this.nextUrl,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [events, showOnlyMyEvents, nextUrl, hasReachedMax, isLoadingMore];
}

class EventsLoadFailure extends EventsState {
  final String error;

  const EventsLoadFailure(this.error, {super.showOnlyMyEvents = false});

  @override
  List<Object?> get props => [error, showOnlyMyEvents];
}
