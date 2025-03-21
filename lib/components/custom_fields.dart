import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/auth/auth_state.dart';

/// Builds the email input field
Widget buildEmailField(BuildContext context, TextEditingController controller) {
  return customTextFormField(
    context: context,
    hintText: 'Email',
    controller: controller,
    backgroundColor: Colors.white,
    prefixIcon: const Icon(Icons.mail),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (_) {
      if (controller.text.isEmpty) return 'this is field is required';
      return null;
    },
  );
}

/// Builds the name input field
Widget buildNameField(BuildContext context, TextEditingController controller) {
  return customTextFormField(
    backgroundColor: Colors.white,
    context: context,
    hintText: 'Name',
    controller: controller,
    prefixIcon: const Icon(Icons.person),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (_) {
      if (controller.text.isEmpty) return 'this is field is required';
      return null;
    },
  );
}

/// Builds the password input field with visibility toggle
Widget buildPasswordField(
    BuildContext context, TextEditingController controller) {
  return BlocConsumer<AuthCubit, AuthState>(
    listener: (context, state) {},
    builder: (context, state) {
      var authCubit = context.read<AuthCubit>();
      return customTextFormField(
        backgroundColor: Colors.white,
        context: context,
        hintText: 'Password',
        controller: controller,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          onPressed: authCubit.toggleVisiablity,
          icon: Icon(
            authCubit.isPasswordVisiablity
                ? Icons.visibility
                : Icons.visibility_off,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: !authCubit.isPasswordVisiable,
        validator: (_) {
          if (controller.text.isEmpty) return 'this is field is required';
          return null;
        },
      );
    },
  );
}
