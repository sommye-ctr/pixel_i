import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/events/bloc/events_event.dart';
import 'package:frontend/features/events/bloc/events_state.dart';
import 'package:frontend/features/events/data/events_repository.dart';
import 'package:frontend/features/events/models/event.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository repository;
  final AuthRepository authRepository;

  EventsBloc(this.repository, this.authRepository)
    : super(const EventsInitial()) {
    on<EventsRequested>(_onRequested);
    on<MyEventsRequested>(_onMyEventsRequested);
  }

  Future<void> _onRequested(
    EventsRequested state,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoadInProgress(showOnlyMyEvents: this.state.showOnlyMyEvents));
    try {
      final List<Event> events = await repository.fetchEvents();
      emit(EventsLoadSuccess(events, showOnlyMyEvents: false));
    } catch (e) {
      emit(EventsLoadFailure(e.toString(), showOnlyMyEvents: false));
    }
  }

  Future<void> _onMyEventsRequested(
    MyEventsRequested state,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoadInProgress(showOnlyMyEvents: true));
    try {
      final currentUser = authRepository.currentUser;

      if (currentUser == null) {
        emit(EventsLoadFailure('User not logged in', showOnlyMyEvents: true));
        return;
      }

      final List<Event> events = await repository.fetchEvents();

      final myEvents = events
          .where((event) => event.coordinator.id == currentUser.id)
          .toList();

      emit(EventsLoadSuccess(myEvents, showOnlyMyEvents: true));
    } catch (e) {
      emit(EventsLoadFailure(e.toString(), showOnlyMyEvents: true));
    }
  }
}
