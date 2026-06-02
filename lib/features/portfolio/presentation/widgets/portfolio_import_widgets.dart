part of '../screens/portfolio_screen.dart';

class _ImportPreviewPanel extends StatelessWidget {
  const _ImportPreviewPanel({required this.preview, required this.mode});

  final PortfolioImportPreview preview;
  final PortfolioImportMode mode;

  @override
  Widget build(BuildContext context) {
    final first = preview.firstTimestamp;
    final last = preview.lastTimestamp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == PortfolioImportMode.append
                ? 'Append import preview'
                : 'Replace import preview',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _PreviewRow('Transactions', '${preview.transactionCount}'),
          _PreviewRow(
            'Buys / Sells',
            '${preview.buyCount} / ${preview.sellCount}',
          ),
          _PreviewRow('Coins', '${preview.coinCount}'),
          if (first != null && last != null)
            _PreviewRow(
              'Range',
              '${DateFormat('dd MMM yyyy').format(first)} - ${DateFormat('dd MMM yyyy').format(last)}',
            ),
          const SizedBox(height: 8),
          Text(
            mode == PortfolioImportMode.replace
                ? 'Existing portfolio transactions and snapshots will be replaced.'
                : 'Existing transactions are kept; duplicate IDs are skipped.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
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
