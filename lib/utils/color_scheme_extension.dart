import 'package:flutter/material.dart';
import 'package:lip_reading/utils/app_colors.dart';

extension CustomColorScheme on ColorScheme {
  Color get success => brightness == Brightness.light
      ? AppColors.successLight
      : AppColors.successDark;

  Color get warning => brightness == Brightness.light
      ? AppColors.warningLight
      : AppColors.warningDark;

  Color get onSuccess =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get onWarning =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get buttonColor => brightness == Brightness.light
      ? AppColors.primaryLight
      : AppColors.accentDark;
}
