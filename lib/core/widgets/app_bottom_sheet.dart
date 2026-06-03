import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';

class AppBottomSheetScaffold extends StatelessWidget {
  const AppBottomSheetScaffold({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.showHandle = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.copyWith(
        bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHandle) ...[
              const Center(child: AppBottomSheetHandle()),
              const SizedBox(height: 18),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
