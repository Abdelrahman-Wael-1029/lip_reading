import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_button.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  static const String routeName = '/signup-screen';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
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
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(
                  height: getSizedBox(context)! * 1.5,
                ),
                Text(
                  'Name',
                  style: Theme.of(context).textTheme.titleLarge!,
                ),
                SizedBox(
                  height: getSizedBox(context)! / 2,
                ),
                customTextFormField(
                  backgroundColor: Colors.white,
                  context: context,
                  hintText: 'Name',
                  controller: nameController,
                  prefixIcon: const Icon(
                    Icons.person,
                    color: AppColors.grey,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) {
                    if (nameController.text.isEmpty) {
                      return 'this is field is required';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: getSizedBox(context),
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
                  height: getSizedBox(context),
                ),
                Text(
                  'Confirm Password',
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
                      hintText: 'Confirm Password',
                      controller: confirmPasswordController,
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.grey,
                      ),
                      suffixIcon: IconButton(
                        onPressed: authCubit.toggleConfirmVisiablity,
                        icon: Icon(
                          authCubit.isConfirmPasswordVisiable
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      obscureText: !authCubit.isConfirmPasswordVisiable,
                      validator: (_) {
                        if (confirmPasswordController.text !=
                            passwordController.text) {
                          return 'Password does not match';
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
                    const Text('Already have an account? '),
                    InkWell(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, LoginScreen.routeName),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: AppColors.primaryColor),
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
                text: 'Sign Up',
                backgroundColor: AppColors.buttonColor,
                textColor: AppColors.white,
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
          // aready have an account button
        ],
      ),
    );
  }
}
