import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/events/bloc/event_create_event.dart';
import 'package:frontend/features/events/bloc/event_create_state.dart';
import 'package:frontend/features/events/data/events_repository.dart';

class EventCreateBloc extends Bloc<EventCreateEvent, EventCreateState> {
  final EventsRepository repository;

  EventCreateBloc(this.repository) : super(const EventCreateInitial()) {
    on<EventCreateRequested>(_onEventCreateRequested);
  }

  Future<void> _onEventCreateRequested(
    EventCreateRequested event,
    Emitter<EventCreateState> emit,
  ) async {
    emit(const EventCreateInProgress());
    try {
      await repository.createEvent(
        title: event.title,
        readPerm: event.readPerm,
        writePerm: event.writePerm,
      );
      emit(const EventCreateSuccess());
    } catch (e) {
      emit(EventCreateFailure(e.toString()));
    }
  }
}
