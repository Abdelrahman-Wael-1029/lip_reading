import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_button.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';
import 'package:lip_reading/screens/auth/signup_screen.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  static const String routeName = '/login-screen';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: getSizedBox(context)! * 2,
                ),
                Center(
                  child: Text(
                    'Welcome to Lip Reading',
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SizedBox(
                  height: getSizedBox(context)! * 1.5,
                ),
                Text(
                  'Email',
                  style: Theme.of(context).textTheme.titleLarge!,
                ),
                SizedBox(
                  height: getSizedBox(context)! / 2,
                ),
                customTextFormField(
                  context: context,
                  hintText: 'Email',
                  controller: emailController,
                  backgroundColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.mail,
                    color: AppColors.grey,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) {
                    if (emailController.text.isEmpty) {
                      return 'this is field is required';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: getSizedBox(context),
                ),
                Text(
                  'Password',
                  style: Theme.of(context).textTheme.titleLarge!,
                ),
                SizedBox(
                  height: getSizedBox(context)! / 2,
                ),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    var authCubit = context.read<AuthCubit>();
                    return customTextFormField(
                      backgroundColor: Colors.white,
                      context: context,
                      hintText: 'Password',
                      controller: passwordController,
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.grey,
                      ),
                      suffixIcon: IconButton(
                        onPressed: authCubit.toggleVisiablity,
                        icon: Icon(
                          authCubit.isPasswordVisiable
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      obscureText: !authCubit.isPasswordVisiable,
                      validator: (_) {
                        if (passwordController.text.isEmpty) {
                          return 'this is field is required';
                        }
                        return null;
                      },
                    );
                  },
                ),
                SizedBox(
                  height: getSizedBox(context)! * 1.5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    InkWell(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, SignupScreen.routeName),
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildActionButtons(context),
      ),
    );
  }

  /// Builds login and guest buttons
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(getPadding(context)!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: getSizedBox(context)! / 2,
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
                return const LinearProgressIndicator();
              }
              return CustomButton(
                text: 'Log in',
                backgroundColor: AppColors.buttonColor,
                textColor: AppColors.white,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final authCubit = context.read<AuthCubit>();
                  authCubit.signIn(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                },
                height: 50,
                width: double.infinity,
              );
            },
          ),
          // aready have an account button
        ],
      ),
    );
  }
}
