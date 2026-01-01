import 'package:equatable/equatable.dart';

class EventCreateState extends Equatable {
  const EventCreateState();

  @override
  List<Object?> get props => [];
}

class EventCreateInitial extends EventCreateState {
  const EventCreateInitial();
}

class EventCreateInProgress extends EventCreateState {
  const EventCreateInProgress();
}

class EventCreateSuccess extends EventCreateState {
  const EventCreateSuccess();
}

class EventCreateFailure extends EventCreateState {
  final String error;

  const EventCreateFailure(this.error);

  @override
  List<Object?> get props => [error];
}
