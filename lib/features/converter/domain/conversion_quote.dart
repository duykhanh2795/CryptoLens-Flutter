class ConversionQuote {
  const ConversionQuote({
    required this.result,
    required this.directRate,
    required this.inverseRate,
  });

  final double result;
  final double directRate;
  final double inverseRate;

  factory ConversionQuote.fromPrices({
    required double amount,
    required double fromUsdPrice,
    required double toUsdPrice,
  }) {
    final fromValue = fromUsdPrice <= 0 ? 0.0 : amount * fromUsdPrice;
    final result = toUsdPrice <= 0 ? 0.0 : fromValue / toUsdPrice;
    final directRate = fromUsdPrice <= 0 || toUsdPrice <= 0
        ? 0.0
        : fromUsdPrice / toUsdPrice;
    return ConversionQuote(
      result: result,
      directRate: directRate,
      inverseRate: directRate <= 0 ? 0.0 : 1 / directRate,
    );
  }
}

class ConverterAssetSelection {
  const ConverterAssetSelection.usd() : coinId = 'usd', usdPrice = 1.0;

  const ConverterAssetSelection.coin({
    required this.coinId,
    required this.usdPrice,
  });

  final String coinId;
  final double usdPrice;
}
