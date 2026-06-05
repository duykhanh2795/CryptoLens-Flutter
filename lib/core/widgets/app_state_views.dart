import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/widgets/empty_state.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    this.height = 180,
    this.strokeWidth = 3,
    this.color,
    super.key,
  });

  final double height;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color,
        ),
      ),
    );
  }
}

class AppEmptyStateBlock extends StatelessWidget {
  const AppEmptyStateBlock({
    required this.icon,
    required this.title,
    required this.message,
    this.height = 420,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: EmptyState(icon: icon, title: title, message: message),
    );
  }
}

class AppAsyncMessage extends StatelessWidget {
  const AppAsyncMessage({
    required this.message,
    this.padding = const EdgeInsets.all(14),
    this.alignment = Alignment.center,
    this.textAlign = TextAlign.center,
    this.style,
    super.key,
  });

  final String message;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: Text(
          message,
          textAlign: textAlign,
          style:
              style ??
              const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({
    this.dimension = 18,
    this.strokeWidth = 2,
    this.color,
    super.key,
  });

  final double dimension;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppColors.accent,
      ),
    );
  }
}
