import 'package:flutter/material.dart';
import 'package:lip_reading/utils/app_colors.dart';

var lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.backgroundColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
  textTheme: TextTheme(
    bodyLarge: TextStyle(),
  ),
);
