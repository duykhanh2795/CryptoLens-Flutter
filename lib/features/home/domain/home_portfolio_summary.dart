class HomePortfolioSummary {
  const HomePortfolioSummary({
    required this.totalValue,
    required this.dayChange,
    required this.dayChangePercent,
    required this.totalPnl,
    required this.assetCount,
    required this.transactionCount,
  });

  final double totalValue;
  final double dayChange;
  final double dayChangePercent;
  final double totalPnl;
  final int assetCount;
  final int transactionCount;

  static HomePortfolioSummary empty() => const HomePortfolioSummary(
    totalValue: 0,
    dayChange: 0,
    dayChangePercent: 0,
    totalPnl: 0,
    assetCount: 0,
    transactionCount: 0,
  );
}
