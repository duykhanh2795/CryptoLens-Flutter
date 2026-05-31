class Kline {
  const Kline({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
  });

  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;

  factory Kline.fromBinance(List<dynamic> raw) {
    return Kline(
      openTime: _int(raw.elementAtOrNull(0)),
      open: _double(raw.elementAtOrNull(1)),
      high: _double(raw.elementAtOrNull(2)),
      low: _double(raw.elementAtOrNull(3)),
      close: _double(raw.elementAtOrNull(4)),
      volume: _double(raw.elementAtOrNull(5)),
      closeTime: _int(raw.elementAtOrNull(6)),
    );
  }
}

extension _SafeListAccess<T> on List<T> {
  T? elementAtOrNull(int index) =>
      index >= 0 && index < length ? this[index] : null;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
