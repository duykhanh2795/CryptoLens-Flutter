part of '../screens/trending_wallets_screen.dart';

void _showTransactionSheet(BuildContext context, WalletTransaction tx) {
  final explorer = _transactionExplorerUrl(tx);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _Dark.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(tx.type.label, style: _Dark.sectionTitle),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: _Dark.textSecondary,
              ),
            ],
          ),
          _DetailRow('Amount', '${_formatNative(tx.amount)} ${tx.symbol}'),
          _DetailRow(
            'Value',
            tx.valueUsd == null ? 'Unavailable' : formatPrice(tx.valueUsd!),
          ),
          _DetailRow(
            'Time',
            DateFormat('MMM dd, yyyy HH:mm').format(tx.timestamp),
          ),
          _DetailRow('Tx hash', shortWalletAddress(tx.id)),
          _DetailRow(
            'Counterparty',
            tx.counterparty == null
                ? 'Unavailable'
                : shortWalletAddress(tx.counterparty!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: tx.id)),
                  child: const Text('Copy Hash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: tx.counterparty == null
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: tx.counterparty!),
                        ),
                  child: const Text('Copy Address'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: explorer == null
                  ? null
                  : () => unawaited(launchUrl(Uri.parse(explorer))),
              style: FilledButton.styleFrom(
                backgroundColor: _Dark.yellow,
                foregroundColor: const Color(0xFF1A1400),
              ),
              child: const Text('Open Explorer'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: _Dark.sub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: _Dark.body.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String? _transactionExplorerUrl(WalletTransaction tx) {
  if (tx.id.startsWith('fallback_') || tx.id.isEmpty) return null;
  final base = switch (tx.networkLabel.toLowerCase()) {
    'ethereum' => 'https://etherscan.io/tx/',
    'polygon' => 'https://polygonscan.com/tx/',
    'bnb chain' => 'https://bscscan.com/tx/',
    _ => null,
  };
  return base == null ? null : '$base${tx.id}';
}

String _formatNative(double value) {
  if (value >= 1) {
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (value > 0) return value.toStringAsPrecision(4);
  return '0';
}

extension on WalletTransactionType {
  String get label => switch (this) {
    WalletTransactionType.received => 'Received',
    WalletTransactionType.sent => 'Sent',
    WalletTransactionType.executed => 'Contract',
  };
}
