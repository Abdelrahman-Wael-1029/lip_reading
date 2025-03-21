import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  bool isPasswordVisiable = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isPasswordVisiablity => isPasswordVisiable;

  void toggleVisiablity() {
    isPasswordVisiable = !isPasswordVisiable;
    emit(ChangeVisiablity());
    
  }
  Future<void> signIn(String email, String password) async {
    emit(LoginLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailure(errorMessage: e.toString()));
    }
  }
}
