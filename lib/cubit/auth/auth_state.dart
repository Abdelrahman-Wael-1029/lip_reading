abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}
class ChangeVisiablity extends AuthState {}
class LoginLoading extends AuthState {}
class LoginSuccess extends AuthState {}
class LoginFailure extends AuthState {
  final String errorMessage;
  LoginFailure({required this.errorMessage});
}
