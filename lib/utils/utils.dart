import 'package:responsive_framework/responsive_value.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

double? getSizedBox(context) {
  return ResponsiveValue<double>(
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
  ).value;
}

double? getPadding(context) {
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
