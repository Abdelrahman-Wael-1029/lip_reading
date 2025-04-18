import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_button.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';
import 'package:lip_reading/utils/app_assets.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  static const String routeName = '/login-screen';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            _buildLoginForm(context),
          ],
        ),
      ),
    );
  }

  /// Builds the background image
  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppAssets.background1,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the login form positioned at the bottom of the screen
  Widget _buildLoginForm(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmailField(context),
            const SizedBox(height: 15),
            _buildPasswordField(context),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// Builds the email input field
  Widget _buildEmailField(BuildContext context) {
    return customTextFormField(
      context: context,
      hintText: 'Email',
      controller: emailController,
      prefixIcon: const Icon(Icons.mail),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) {
        if (emailController.text.isEmpty) return 'this is field is required';
        return null;
      },
    );
  }

  /// Builds the password input field with visibility toggle
  Widget _buildPasswordField(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        var authCubit = context.read<AuthCubit>();
        return customTextFormField(
          context: context,
          hintText: 'Password',
          controller: passwordController,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            onPressed: authCubit.toggleVisiablity,
            icon: Icon(
              authCubit.isConfirmPasswordVisiable
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: !authCubit.isPasswordVisiable,
          validator: (_) {
        if (passwordController.text.isEmpty) return 'this is field is required';
        return null;
      },
        );
      },
    );
  }

  /// Builds login and guest buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Successful!')),
              );
              Navigator.pushReplacementNamed(
                  context, '/home'); // Navigate to home screen
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage)),
              );
            }
          },
          builder: (context, state) {
            if (state is LoginLoading) {
              return const CircularProgressIndicator();
            }
            return CustomButton(
              text: 'Login',
              onPressed: () {
                final authCubit = context.read<AuthCubit>();
                authCubit.signIn(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
              },
              height: 50,
              width: 250,
            );
          },
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Join as Guest',
          onPressed: () {},
          height: 50,
          width: 250,
        ),
      ],
    );
  }
}
