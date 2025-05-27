// File: widgets/scaled_text.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_size_provider.dart';

class ScaledText extends StatelessWidget {
  final String text;
  final double? baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final TextDecoration? decoration;
  final TextStyle? style;

  const ScaledText(
    this.text, {
    Key? key,
    this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.decoration,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        if (fontProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final defaultFontSize = baseFontSize ?? style?.fontSize ?? 16.0;
        final scaleFactor =
            fontProvider.fontSize / 16.0; // 16.0 is default base
        final scaledFontSize = defaultFontSize * scaleFactor;

        final scaledStyle = TextStyle(
          fontSize: scaledFontSize,
          fontWeight: fontWeight ?? style?.fontWeight,
          color: color ?? style?.color,
          height: height ?? style?.height,
          decoration: decoration ?? style?.decoration,
        );

        return Text(
          text,
          style: style != null ? style!.merge(scaledStyle) : scaledStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
