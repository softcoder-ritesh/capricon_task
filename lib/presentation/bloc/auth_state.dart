abstract class AuthState {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}