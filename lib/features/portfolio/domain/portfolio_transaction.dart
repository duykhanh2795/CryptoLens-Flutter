import 'package:cryptolens_flutter/features/market/domain/coin.dart';

enum PortfolioTransactionType {
  buy('Buy'),
  sell('Sell');

  const PortfolioTransactionType(this.label);

  final String label;
}

enum PortfolioImportMode { append, replace }

class PortfolioImportPreview {
  const PortfolioImportPreview({required this.transactions});

  final List<PortfolioTransaction> transactions;

  int get transactionCount => transactions.length;
  int get buyCount => transactions
      .where((tx) => tx.type == PortfolioTransactionType.buy)
      .length;
  int get sellCount => transactions
      .where((tx) => tx.type == PortfolioTransactionType.sell)
      .length;
  int get coinCount => transactions.map((tx) => tx.coin.id).toSet().length;

  DateTime? get firstTimestamp {
    if (transactions.isEmpty) return null;
    return transactions
        .map((tx) => tx.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? get lastTimestamp {
    if (transactions.isEmpty) return null;
    return transactions
        .map((tx) => tx.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.dayStart,
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfitLoss,
    required this.totalProfitLossPercent,
    required this.assetCount,
    required this.createdAt,
  });

  final DateTime dayStart;
  final double totalValue;
  final double totalInvested;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final int assetCount;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'dayStart': dayStart.millisecondsSinceEpoch,
    'totalValue': totalValue,
    'totalInvested': totalInvested,
    'totalProfitLoss': totalProfitLoss,
    'totalProfitLossPercent': totalProfitLossPercent,
    'assetCount': assetCount,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  static PortfolioSnapshot? fromJson(Map<String, Object?> json) {
    return PortfolioSnapshot(
      dayStart: DateTime.fromMillisecondsSinceEpoch(
        (json['dayStart'] as num?)?.toInt() ?? 0,
      ),
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0,
      totalProfitLoss: (json['totalProfitLoss'] as num?)?.toDouble() ?? 0,
      totalProfitLossPercent:
          (json['totalProfitLossPercent'] as num?)?.toDouble() ?? 0,
      assetCount: (json['assetCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class PortfolioTransaction {
  const PortfolioTransaction({
    required this.id,
    required this.coin,
    required this.type,
    required this.quantity,
    required this.price,
    required this.fee,
    required this.timestamp,
    required this.note,
    this.sourceConnectionId,
  });

  final String id;
  final Coin coin;
  final PortfolioTransactionType type;
  final double quantity;
  final double price;
  final double fee;
  final DateTime timestamp;
  final String note;
  final String? sourceConnectionId;

  double get total => quantity * price + fee;
}
