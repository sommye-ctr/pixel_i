import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/notification_utils.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/notifications_repository.dart';
import '../models/notification_item.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsInitialized extends NotificationsEvent {}

class NotificationsLoadRequested extends NotificationsEvent {}

class NotificationsErrorCleared extends NotificationsEvent {}

class NotificationsMarkRead extends NotificationsEvent {
  final String id;
  const NotificationsMarkRead(this.id);
  @override
  List<Object?> get props => [id];
}

class _NotificationsWsRawReceived extends NotificationsEvent {
  final dynamic raw;
  const _NotificationsWsRawReceived(this.raw);
}

class _NotificationsWsStatusChanged extends NotificationsEvent {
  final bool connected;
  final String? error;
  const _NotificationsWsStatusChanged(this.connected, [this.error]);
}

// State
class NotificationsState extends Equatable {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool loading;
  final bool connected;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.connected = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    bool? loading,
    bool? connected,
    String? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      connected: connected ?? this.connected,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, unreadCount, loading, connected, error];
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  NotificationsBloc(this.repository) : super(const NotificationsState()) {
    on<NotificationsInitialized>(_onInitialized);
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsErrorCleared>(_onErrorCleared);
    on<NotificationsMarkRead>(_onMarkRead);
    on<_NotificationsWsRawReceived>(_onWsRawReceived);
    on<_NotificationsWsStatusChanged>(_onWsStatusChanged);
  }

  void _onErrorCleared(
    NotificationsErrorCleared event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  Future<void> _onInitialized(
    NotificationsInitialized event,
    Emitter<NotificationsState> emit,
  ) async {
    await _loadList(emit);
    await _connect(emit);
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _loadList(emit);
  }

  Future<void> _loadList(Emitter<NotificationsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await repository.fetchNotifications();
      final unread = items.where((n) => !n.read).length;
      emit(state.copyWith(items: items, unreadCount: unread, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onMarkRead(
    NotificationsMarkRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final updated = await repository.markAsRead(event.id);
      if (updated == null) {
        emit(state.copyWith(error: 'Failed to mark as read'));
        return;
      }
      final updatedItems = state.items.map((n) {
        if (n.id == updated.id) {
          return updated;
        }
        return n;
      }).toList();
      final unread = updatedItems.where((n) => !n.read).length;
      emit(
        state.copyWith(items: updatedItems, unreadCount: unread, error: null),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _connect(Emitter<NotificationsState> emit) async {
    await _disposeChannel();
    try {
      _channel = await repository.connectNotificationsChannel();
      add(const _NotificationsWsStatusChanged(true));
      _sub = _channel!.stream.listen(
        (raw) => add(_NotificationsWsRawReceived(raw)),
        onError: (err) =>
            add(_NotificationsWsStatusChanged(false, err.toString())),
        onDone: () => add(const _NotificationsWsStatusChanged(false)),
        cancelOnError: false,
      );
    } catch (e) {
      add(_NotificationsWsStatusChanged(false, e.toString()));
      // retry after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!isClosed) add(NotificationsInitialized());
      });
    }
  }

  Future<void> _onWsRawReceived(
    _NotificationsWsRawReceived event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      if (event.raw is String && event.raw.isNotEmpty) {
        final map = json.decode(event.raw as String) as Map<String, dynamic>;
        final notif = NotificationItem.fromMap(map);
        final msg = NotificationUtils.formatNotification(notif);
        if (msg != null && msg.isNotEmpty) {
          showSimpleNotification(
            Text(msg),
            background: const Color(0xFF323232),
            autoDismiss: true,
            duration: const Duration(seconds: 3),
            contentPadding: EdgeInsets.all(defaultSpacing),
          );
        }
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
    await _loadList(emit);
  }

  void _onWsStatusChanged(
    _NotificationsWsStatusChanged event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(connected: event.connected, error: event.error));
    if (!event.connected && !isClosed) {
      // attempt reconnect
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) add(NotificationsInitialized());
      });
    }
  }

  Future<void> _disposeChannel() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  Future<void> close() async {
    await _disposeChannel();
    return super.close();
  }
}
