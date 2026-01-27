import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/comments_repository.dart';
import '../models/comment.dart';

// Events
abstract class CommentsEvent extends Equatable {
  const CommentsEvent();
  @override
  List<Object?> get props => [];
}

class CommentsLoadRequested extends CommentsEvent {
  final String photoId;
  const CommentsLoadRequested(this.photoId);
  @override
  List<Object?> get props => [photoId];
}

class CommentRepliesLoadRequested extends CommentsEvent {
  final String photoId;
  final String parentId;
  const CommentRepliesLoadRequested(this.photoId, this.parentId);
  @override
  List<Object?> get props => [photoId, parentId];
}

class SendCommentRequested extends CommentsEvent {
  final String photoId;
  final String text;
  final String? parentId;

  const SendCommentRequested(this.photoId, this.text, {this.parentId});

  @override
  List<Object?> get props => [photoId, text, parentId];
}

// State
class CommentsState extends Equatable {
  final List<Comment> comments;
  final Map<String, List<Comment>> replies;
  final bool loading;
  final Map<String, bool> loadingReplies;
  final String? error;

  const CommentsState({
    this.comments = const [],
    this.replies = const {},
    this.loading = false,
    this.loadingReplies = const {},
    this.error,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    Map<String, List<Comment>>? replies,
    bool? loading,
    Map<String, bool>? loadingReplies,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      replies: replies ?? this.replies,
      loading: loading ?? this.loading,
      loadingReplies: loadingReplies ?? this.loadingReplies,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    comments,
    replies,
    loading,
    loadingReplies,
    error,
  ];
}

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentsRepository repository;

  CommentsBloc(this.repository) : super(const CommentsState()) {
    on<CommentsLoadRequested>(_onLoadRequested);
    on<CommentRepliesLoadRequested>(_onRepliesRequested);
    on<SendCommentRequested>(_onSendRequested);
  }

  Future<void> _onLoadRequested(
    CommentsLoadRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await repository.fetchTopLevelComments(event.photoId);
      emit(state.copyWith(comments: list, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onRepliesRequested(
    CommentRepliesLoadRequested event,
    Emitter<CommentsState> emit,
  ) async {
    final loadingReplies = Map<String, bool>.from(state.loadingReplies);
    loadingReplies[event.parentId] = true;
    emit(state.copyWith(loadingReplies: loadingReplies, error: null));
    try {
      final replies = await repository.fetchReplies(
        event.photoId,
        event.parentId,
      );
      final newReplies = Map<String, List<Comment>>.from(state.replies);
      newReplies[event.parentId] = replies;
      loadingReplies[event.parentId] = false;
      emit(state.copyWith(replies: newReplies, loadingReplies: loadingReplies));
    } catch (e) {
      loadingReplies[event.parentId] = false;
      emit(state.copyWith(loadingReplies: loadingReplies, error: e.toString()));
    }
  }

  Future<void> _onSendRequested(
    SendCommentRequested event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      final created = await repository.sendComment(
        event.photoId,
        event.text,
        parentId: event.parentId,
      );

      if (event.parentId == null) {
        final newList = List<Comment>.from(state.comments);
        newList.insert(0, created);
        emit(state.copyWith(comments: newList));
      } else {
        final newReplies = Map<String, List<Comment>>.from(state.replies);
        final list = List<Comment>.from(newReplies[event.parentId] ?? []);
        list.add(created);
        newReplies[event.parentId!] = list;
        emit(state.copyWith(replies: newReplies));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
