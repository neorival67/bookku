import 'package:equatable/equatable.dart';
import '../../models/auth_user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(AuthUser user)
      : this._(
          status: AuthStatus.authenticated,
          user: user,
        );

  const AuthState.unauthenticated({String? errorMessage})
      : this._(
          status: AuthStatus.unauthenticated,
          errorMessage: errorMessage,
        );

  const AuthState.loading()
      : this._(
          isLoading: true,
        );

  @override
  List<Object?> get props => [status, user, errorMessage, isLoading];
}
