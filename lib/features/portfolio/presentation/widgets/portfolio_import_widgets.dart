import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class ImportPreviewPanel extends StatelessWidget {
  const ImportPreviewPanel({
    required this.preview,
    required this.mode,
    super.key,
  });

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
          PreviewRow('Transactions', '${preview.transactionCount}'),
          PreviewRow(
            'Buys / Sells',
            '${preview.buyCount} / ${preview.sellCount}',
          ),
          PreviewRow('Coins', '${preview.coinCount}'),
          if (first != null && last != null)
            PreviewRow(
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

class PreviewRow extends StatelessWidget {
  const PreviewRow(this.label, this.value, {super.key});

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
