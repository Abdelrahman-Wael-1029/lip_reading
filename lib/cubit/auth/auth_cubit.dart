import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  bool isPasswordVisiable = false;
  bool isConfirmPasswordVisiable = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void toggleVisiablity() {
    isPasswordVisiable = !isPasswordVisiable;
    emit(ChangeVisiablity());
  }

  void toggleConfirmVisiablity() {
    isConfirmPasswordVisiable = !isConfirmPasswordVisiable;
    emit(ChangeVisiablity());
  }

  Future<void> signIn(String email, String password) async {
    emit(LoginLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      emit(LoginSuccess());
    } catch (e) {
      print("error"+e.toString());
      emit(LoginFailure(errorMessage: e.toString()));
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    emit(LoginLoading());
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _auth.currentUser!.updateDisplayName(name);

      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailure(errorMessage: e.toString()));
    }
  }
}
