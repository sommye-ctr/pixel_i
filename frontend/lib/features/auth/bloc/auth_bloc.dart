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
  factory AuthEvent.signup({
    required String email,
    required String name,
    required String password,
    required String username,
  }) =>
      _Signup(email: email, name: name, password: password, username: username);
  factory AuthEvent.login({
    required String username,
    required String password,
  }) =>
      _Login(username: username, password: password);
  factory AuthEvent.requestOtp(String email) => _RequestOtp(email);
  factory AuthEvent.submitOtp(String email, String otp) =>
      _SubmitOtp(email, otp);
  factory AuthEvent.loginWithOAuth(String token) => _LoginWithOAuth(token);
  factory AuthEvent.logout() => const _Logout();
}

class _Started extends AuthEvent {
  const _Started();
}

class _Signup extends AuthEvent {
  final String email;
  final String name;
  final String password;
  final String username;

  const _Signup({
    required this.email,
    required this.name,
    required this.password,
    required this.username,
  });

  @override
  List<Object?> get props => [email, name, password, username];
}

class _Login extends AuthEvent {
  final String username;
  final String password;

  const _Login({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class _RequestOtp extends AuthEvent {
  final String email;
  const _RequestOtp(this.email);
  @override
  List<Object?> get props => [email];
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

    on<_Signup>((event, emit) async {
      emit(const AuthState(status: AuthStatus.loading));
      try {
        await _repo.signup(
          email: event.email,
          name: event.name,
          password: event.password,
          username: event.username,
        );
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } catch (e) {
        emit(AuthState(status: AuthStatus.error, error: e.toString()));
      }
    });

    on<_Login>((event, emit) async {
      emit(const AuthState(status: AuthStatus.loading));
      try {
        final user = await _repo.login(
          username: event.username,
          password: event.password,
        );
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } catch (e) {
        emit(AuthState(status: AuthStatus.error, error: e.toString()));
      }
    });

    on<_RequestOtp>((event, emit) async {
      emit(const AuthState(status: AuthStatus.loading));
      try {
        await _repo.requestOtp(event.email);
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } catch (e) {
        emit(AuthState(status: AuthStatus.error, error: e.toString()));
      }
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
