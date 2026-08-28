import 'package:flutter/material.dart';

import '../constants.dart';

enum CustomFontFamily { primary, secondary }

class CustomFont extends StatelessWidget {
  final String text;
  final CustomFontFamily family;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const CustomFont(
    this.text, {
    super.key,
    this.family = CustomFontFamily.secondary,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle fallback =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final TextStyle base = (style ?? fallback).copyWith(
      fontFamily: family == CustomFontFamily.primary
          ? kFontPrimary
          : kFontSecondary,
      fontSize: fontSize ?? style?.fontSize,
      fontWeight: fontWeight ?? style?.fontWeight,
      color: color ?? style?.color ?? scheme.onSurface,
    );
    return Text(
      text,
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
