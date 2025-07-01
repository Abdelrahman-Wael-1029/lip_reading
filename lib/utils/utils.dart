import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_value.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

double? getSizedBox(context) {
  return ResponsiveValue<double>(
    context,
    defaultValue: 28.0,
    valueWhen: [
      const Condition.smallerThan(
        name: MOBILE,
        value: 20.0,
      ),
      const Condition.smallerThan(
        name: TABLET,
        value: 24.0,
      ),
      const Condition.smallerThan(
        name: DESKTOP,
        value: 28.0,
      ),
    ],
  ).value;
}

double? getPadding(context) {
  return ResponsiveValue<double>(
    context,
    defaultValue: 20.0,
    valueWhen: [
      const Condition.smallerThan(
        name: MOBILE,
        value: 8.0,
      ),
      const Condition.smallerThan(
        name: TABLET,
        value: 10.0,
      ),
      const Condition.smallerThan(
        name: DESKTOP,
        value: 12.0,
      ),
    ],
  ).value;
}

double? getMediumFontSize(context) {
  return ResponsiveValue<double>(
    context,
    defaultValue: 16.0,
    valueWhen: [
      const Condition.smallerThan(
        name: MOBILE,
        value: 12.0,
      ),
      const Condition.smallerThan(
        name: TABLET,
        value: 16.0,
      ),
      const Condition.smallerThan(
        name: DESKTOP,
        value: 20.0,
      ),
    ],
  ).value;
}

double? getLargeFontSize(context) {
  return ResponsiveValue<double>(
    context,
    defaultValue: 20.0,
    valueWhen: [
      const Condition.smallerThan(name: MOBILE, value: 18),
      const Condition.smallerThan(
        name: TABLET,
        value: 20.0,
      ),
      const Condition.smallerThan(
        name: DESKTOP,
        value: 24.0,
      ),
    ],
  ).value;
}

double? getSizeImage(BuildContext context) {
  double screenHeight = MediaQuery.of(context).size.height;

  return ResponsiveValue<double>(
    context,
    defaultValue: screenHeight * 0.4, // 40% of screen height
    valueWhen: [
      Condition.smallerThan(
        name: MOBILE,
        value: screenHeight * 0.3, // 30% of screen height
      ),
      Condition.smallerThan(
        name: TABLET,
        value: screenHeight * 0.35, // 35% of screen height
      ),
      Condition.smallerThan(
        name: DESKTOP,
        value: screenHeight * 0.4, // 40% of screen height
      ),
    ],
  ).value;
}
