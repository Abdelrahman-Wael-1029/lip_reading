import 'package:flutter/material.dart';

/// AppColors defines all color constants used in the application
class AppColors {
  // Primary colors
  static const Color primaryLight = Color(0xFF3F51B5);  // Indigo
  static const Color primaryDark = Color(0xFF303F9F);   // Darker Indigo

  // Accent colors
  static const Color accentLight = Color(0xFFFFC107);   // Amber
  static const Color accentDark = Color(0xFFFFAB00);    // Darker Amber

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);  // Light Grey
  static const Color backgroundDark = Color(0xFF121212);   // Dark Grey

  // Surface colors (cards, sheets, etc.)
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color.fromARGB(255, 53, 53, 53);  // Slightly lighter than background dark

  // Error colors
  static const Color errorLight = Color(0xFFD32F2F);   // Red
  static const Color errorDark = Color(0xFFEF5350);    // Lighter Red for dark theme

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);  // Almost Black
  static const Color textSecondaryLight = Color(0xFF757575); // Medium Grey
  static const Color textPrimaryDark = Color(0xFFE0E0E0);   // Almost White
  static const Color textSecondaryDark = Color(0xFF9E9E9E); // Medium Grey

  // Divider colors  
  static const Color dividerLight = Color(0xFFBDBDBD);  // Light Grey
  static const Color dividerDark = Color(0xFF424242);   // Dark Grey

  // Status colors
  static const Color successLight = Color(0xFF4CAF50);  // Green
  static const Color successDark = Color(0xFF66BB6A);   // Lighter Green for dark theme
  static const Color warningLight = Color(0xFFFFC107);  // Amber
  static const Color warningDark = Color(0xFFFFD54F);   // Lighter Amber for dark theme
  static const Color infoLight = Color(0xFF2196F3);     // Blue
  static const Color infoDark = Color(0xFF64B5F6);      // Lighter Blue for dark theme

  // Special purpose colors
  static const Color disabledLight = Color(0xFFE0E0E0); // Light Grey
  static const Color disabledDark = Color(0xFF424242);  // Dark Grey
  static const Color connectivityOnline = Color(0xFF4CAF50); // Green
  static const Color connectivityOffline = Color(0xFFD32F2F); // Red
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
}
