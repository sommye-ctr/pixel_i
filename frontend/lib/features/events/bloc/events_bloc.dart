import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/events/bloc/events_event.dart';
import 'package:frontend/features/events/bloc/events_state.dart';
import 'package:frontend/features/events/data/events_repository.dart';
import 'package:frontend/features/events/models/event.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsRepository repository;
  EventsBloc(this.repository) : super(EventsInitial()) {
    on<EventsRequested>(_onRequested);
  }

  Future<void> _onRequested(
    EventsRequested state,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoadInProgress());
    try {
      final List<Event> events = await repository.fetchEvents();
      emit(EventsLoadSuccess(events));
    } catch (e) {
      emit(EventsLoadFailure(e.toString()));
    }
  }
}
