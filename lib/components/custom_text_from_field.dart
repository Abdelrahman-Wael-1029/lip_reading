import 'package:flutter/material.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';
import 'package:responsive_framework/responsive_value.dart';
import 'package:responsive_framework/responsive_wrapper.dart';


Widget customTextFormField({
  required BuildContext context,
  String? hintText,
  String? Function(String?)? validator,
  TextEditingController? controller,
  bool obscureText = false,
  TextInputType? keyboardType,
  Widget? suffixIcon,
  Widget? prefixIcon,
  bool readOnly = false,
  bool enabled = true,
  bool autofocus = false,
  int minLines = 1,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  int maxLines = 1,
  void Function(String)? onChanged,
  void Function()? onTap,
  void Function(String)? onFieldSubmitted,
  void Function(String?)? onSaved,
  void Function()? onEditingComplete,
  Color? hintColor,
  textDirection = TextDirection.ltr,
  String obscuringCharacter = '•',
  double? borderRadius,
  TextInputAction? textInputAction,
  AutovalidateMode? autovalidateMode,
}) {
  return SizedBox(
    child: TextFormField(
      autovalidateMode: autovalidateMode?? AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction ?? TextInputAction.next,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      textDirection: textDirection,
      minLines: minLines,
      obscuringCharacter: obscuringCharacter,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: ResponsiveValue<double>(
          context,
          defaultValue: 16.0,
          valueWhen: [
            const Condition.smallerThan(
              name: MOBILE,
              value: 16.0,
            ),
            const Condition.smallerThan(
              name: TABLET,
              value: 18.0,
            ),
            const Condition.smallerThan(
              name: DESKTOP,
              value: 20.0,
            ),
          ],
        ).value,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        hintStyle: TextStyle(
          fontSize: ResponsiveValue<double>(
            context,
            defaultValue: 16.0,
            valueWhen: [
              const Condition.smallerThan(
                name: MOBILE,
                value: 16.0,
              ),
              const Condition.smallerThan(
                name: TABLET,
                value: 18.0,
              ),
              const Condition.smallerThan(
                name: DESKTOP,
                value: 20.0,
              ),
            ],
          ).value,
          fontWeight: FontWeight.w300,
          color: hintColor ?? AppColors.grey,
        ),
        contentPadding: padding ??=
             EdgeInsets.symmetric(horizontal: getPadding(context)??14, vertical: getPadding(context)??20),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        errorStyle: TextStyle(
          fontSize: ResponsiveValue<double>(
            context,
            defaultValue: 16.0,
            valueWhen: [
              const Condition.smallerThan(
                name: MOBILE,
                value: 16.0,
              ),
              const Condition.smallerThan(
                name: TABLET,
                value: 18.0,
              ),
              const Condition.smallerThan(
                name: DESKTOP,
                value: 20.0,
              ),
            ],
          ).value,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(
          ),
        ),
      ),
      validator: validator,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      onSaved: onSaved,
      onEditingComplete: onEditingComplete,
    ),
  );
}