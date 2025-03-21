import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_button.dart';
import 'package:lip_reading/components/custom_fields.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/utils/app_assets.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  static const String routeName = '/signup-screen';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
        AppAssets.background2,
        fit: BoxFit.fill,
      ),
    );
  }

  /// Builds the login form positioned at the bottom of the screen
  Widget _buildLoginForm(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: getSizedBox(context)! * 2,
              ),
              buildNameField(context, nameController),
              SizedBox(
                height: getSizedBox(context),
              ),
              buildEmailField(context, emailController),
              SizedBox(
                height: getSizedBox(context),
              ),
              buildPasswordField(context, passwordController),
              SizedBox(
                height: getSizedBox(context)! * 1.5,
              ),
              _buildActionButtons(),
              SizedBox(
                height: getSizedBox(context)! * 2,
              ),
            ],
          ),
        ),
      ),
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
                  context, LipReadingScreen.routeName);
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
              text: 'Sign Up',
              backgroundColor: AppColors.buttonColor,
              textColor: Colors.white,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final authCubit = context.read<AuthCubit>();
                authCubit.signUp(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
              },
              height: 50,
              width: double.infinity,
            );
          },
        ),
      ],
    );
  }
}
