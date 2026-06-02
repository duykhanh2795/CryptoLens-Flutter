import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';

class PortfolioTopBar extends StatelessWidget {
  const PortfolioTopBar({
    required this.isBusy,
    required this.onImport,
    required this.onExport,
    required this.onConnect,
    required this.onAdd,
    super.key,
  });

  final bool isBusy;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onConnect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Portfolio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isBusy) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        PortfolioHeaderIcon(
          icon: Icons.upload_file_rounded,
          tooltip: 'Import',
          onTap: onImport,
        ),
        PortfolioHeaderIcon(
          icon: Icons.file_download_rounded,
          tooltip: 'Export',
          onTap: onExport,
        ),
        PortfolioHeaderIcon(
          icon: Icons.account_balance_rounded,
          tooltip: 'Connect Exchange',
          onTap: onConnect,
        ),
        PortfolioHeaderIcon(
          icon: Icons.add_rounded,
          tooltip: 'Add',
          onTap: onAdd,
        ),
      ],
    );
  }
}

class PortfolioHeaderIcon extends StatelessWidget {
  const PortfolioHeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 38, height: 40),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textSecondary, size: 22),
    );
  }
}
