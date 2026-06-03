import 'package:cryptolens_flutter/core/utils/json_readers.dart';

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
      openTime: readInt(raw.elementAtOrNull(0)),
      open: readDouble(raw.elementAtOrNull(1)),
      high: readDouble(raw.elementAtOrNull(2)),
      low: readDouble(raw.elementAtOrNull(3)),
      close: readDouble(raw.elementAtOrNull(4)),
      volume: readDouble(raw.elementAtOrNull(5)),
      closeTime: readInt(raw.elementAtOrNull(6)),
    );
  }
}

extension SafeListAccess<T> on List<T> {
  T? elementAtOrNull(int index) =>
      index >= 0 && index < length ? this[index] : null;
}
