import 'package:intl/intl.dart';

import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';

String formatNativeAmount(double value) {
  if (value >= 1) {
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (value > 0) return value.toStringAsPrecision(4);
  return '0';
}

Map<String, List<WalletTransaction>> groupWalletTransactionsByDay(
  List<WalletTransaction> items,
) {
  final formatter = DateFormat('MMM dd, yyyy');
  final groups = <String, List<WalletTransaction>>{};
  for (final item in items) {
    final key = formatter.format(item.timestamp);
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups;
}

String? transactionExplorerUrl(WalletTransaction tx) {
  if (tx.id.startsWith('fallback_') || tx.id.isEmpty) return null;
  final base = switch (tx.networkLabel.toLowerCase()) {
    'ethereum' => 'https://etherscan.io/tx/',
    'polygon' => 'https://polygonscan.com/tx/',
    'bnb chain' => 'https://bscscan.com/tx/',
    _ => null,
  };
  return base == null ? null : '$base${tx.id}';
}

extension WalletTransactionTypeLabel on WalletTransactionType {
  String get label => switch (this) {
    WalletTransactionType.received => 'Received',
    WalletTransactionType.sent => 'Sent',
    WalletTransactionType.executed => 'Contract',
  };
}
