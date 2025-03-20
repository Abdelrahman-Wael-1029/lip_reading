import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_value.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final FontWeight? fontWeight;
  final double? borderRadius;
  final bool isDisable;
  final Color? backgroundcolorDisable;
  final Color? textColorDisable;
  final EdgeInsets? margin;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderColor,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.isDisable = false,
    this.backgroundcolorDisable,
    this.textColorDisable,
    this.margin,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 15),
      ),
      child: ElevatedButton.icon(
        onPressed: isDisable ? null : onPressed,
        style: ElevatedButton.styleFrom(
          surfaceTintColor: Colors.transparent,
          backgroundColor: isDisable ? backgroundcolorDisable : backgroundColor,
          padding: EdgeInsets.zero,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 15),
              side: BorderSide(color: borderColor ?? Colors.transparent)),
          shadowColor: Colors.transparent,
        ),
        icon: icon ?? const SizedBox.shrink(),
        label: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDisable ? textColorDisable : textColor,
              fontSize: fontSize ??
                  ResponsiveValue<double>(
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
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
