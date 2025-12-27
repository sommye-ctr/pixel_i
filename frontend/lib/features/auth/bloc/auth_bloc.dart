import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/auth_repository.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );

  @override
  List<Object?> get props => [status, user, error];
}

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];

  factory AuthEvent.started() => const _Started();
  factory AuthEvent.submitOtp(String email, String otp) =>
      _SubmitOtp(email, otp);
  factory AuthEvent.loginWithOAuth(String token) => _LoginWithOAuth(token);
  factory AuthEvent.logout() => const _Logout();
}

class _Started extends AuthEvent {
  const _Started();
}

class _Logout extends AuthEvent {
  const _Logout();
}

class _SubmitOtp extends AuthEvent {
  final String email;
  final String otp;
  const _SubmitOtp(this.email, this.otp);
  @override
  List<Object?> get props => [email, otp];
}

class _LoginWithOAuth extends AuthEvent {
  final String token;
  const _LoginWithOAuth(this.token);
  @override
  List<Object?> get props => [token];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  AuthBloc(this._repo) : super(const AuthState()) {
    on<_Started>((event, emit) async {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });

    on<_SubmitOtp>((event, emit) async {
      emit(const AuthState(status: AuthStatus.loading));
      try {
        final user = await _repo.verifyEmail(event.email, event.otp);
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } catch (e) {
        emit(AuthState(status: AuthStatus.error, error: e.toString()));
      }
    });

    // on<_LoginWithOAuth>((event, emit) async {
    //   emit(const AuthState(status: AuthStatus.loading));
    //   try {
    //     final user = await _repo.loginWithOAuth(event.token);
    //     emit(AuthState(status: AuthStatus.authenticated, user: user));
    //   } catch (e) {
    //     emit(AuthState(status: AuthStatus.error, error: e.toString()));
    //   }
    // });
    on<_Logout>((event, emit) async {
      await _repo.logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });
  }
}
