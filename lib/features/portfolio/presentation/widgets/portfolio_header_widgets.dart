part of '../screens/portfolio_screen.dart';

class _PortfolioTopBar extends StatelessWidget {
  const _PortfolioTopBar({
    required this.isBusy,
    required this.onImport,
    required this.onExport,
    required this.onConnect,
    required this.onAdd,
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
        _HeaderIcon(
          icon: Icons.upload_file_rounded,
          tooltip: 'Import',
          onTap: onImport,
        ),
        _HeaderIcon(
          icon: Icons.file_download_rounded,
          tooltip: 'Export',
          onTap: onExport,
        ),
        _HeaderIcon(
          icon: Icons.account_balance_rounded,
          tooltip: 'Connect Exchange',
          onTap: onConnect,
        ),
        _HeaderIcon(icon: Icons.add_rounded, tooltip: 'Add', onTap: onAdd),
      ],
    );
  }
}
