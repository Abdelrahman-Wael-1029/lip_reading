import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';

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
      print("error$e");
      emit(LoginFailure(errorMessage: 'Cannot login try again'));
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
      emit(LoginFailure(errorMessage: 'Cannot create user try again'));
    }
  }

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, LoginScreen.routeName, (route) => false);
    }
  }
}
