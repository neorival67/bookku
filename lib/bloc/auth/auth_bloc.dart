import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../models/auth_user.dart';
import '../../services/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthState.unknown()) {
    // Listen to Supabase auth state changes
    _authRepository.authStateChanges.listen((supabase.AuthState authState) {
      if (authState.session != null) {
        add(AuthUserChanged(
          AuthUser.fromSupabaseUser(authState.session!.user),
        ));
      } else {
        add(const AuthUserChanged(null));
      }
    });

    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(AuthUser.fromSupabaseUser(user)));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    try {
      final response = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      
      if (response.user != null) {
        emit(AuthState.authenticated(
          AuthUser.fromSupabaseUser(response.user!),
        ));
      } else {
        emit(const AuthState.unauthenticated(
          errorMessage: 'Login failed',
        ));
      }
    } catch (e) {
      emit(AuthState.unauthenticated(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    try {
      final response = await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      
      if (response.user != null) {
        emit(AuthState.authenticated(
          AuthUser.fromSupabaseUser(response.user!),
        ));
      } else {
        emit(const AuthState.unauthenticated(
          errorMessage: 'Registration failed',
        ));
      }
    } catch (e) {
      emit(AuthState.unauthenticated(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    try {
      await _authRepository.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.unauthenticated(
        errorMessage: e.toString(),
      ));
    }
  }

  void _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }
}
