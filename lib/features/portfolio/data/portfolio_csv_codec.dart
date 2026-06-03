import 'package:cryptolens_flutter/core/utils/json_readers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_resolver.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class PortfolioCsvCodec {
  const PortfolioCsvCodec();

  String encode(List<PortfolioTransaction> transactions) {
    if (transactions.isEmpty) return '';
    final rows = [
      'id,coinId,symbol,name,imageUrl,type,quantity,price,fee,timestamp,note,sourceConnectionId',
      for (final tx in transactions)
        [
          tx.id,
          tx.coin.id,
          tx.coin.symbol,
          tx.coin.name,
          tx.coin.imageUrl,
          tx.type.name,
          tx.quantity.toStringAsFixed(12),
          tx.price.toStringAsFixed(8),
          tx.fee.toStringAsFixed(8),
          tx.timestamp.millisecondsSinceEpoch.toString(),
          tx.note,
          tx.sourceConnectionId ?? '',
        ].map(_escapeCsv).join(','),
    ];
    return rows.join('\n');
  }

  List<PortfolioTransaction> decode(
    String input, {
    required CoinSnapshotResolver coinResolver,
  }) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    final imported = <PortfolioTransaction>[];
    for (final line in lines.skip(1)) {
      final columns = _splitCsv(line);
      if (columns.length < 11) continue;
      final coin = coinResolver(columns[1], columns[2], columns[3], columns[4]);
      imported.add(
        PortfolioTransaction(
          id: columns[0].isEmpty ? newPortfolioId() : columns[0],
          coin: coin,
          type: columns[5] == 'sell'
              ? PortfolioTransactionType.sell
              : PortfolioTransactionType.buy,
          quantity: readDouble(columns[6]),
          price: readDouble(columns[7], fallback: coin.currentPrice),
          fee: readDouble(columns[8]),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            readInt(
              columns[9],
              fallback: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
          note: columns[10],
          sourceConnectionId: columns.length > 11 && columns[11].isNotEmpty
              ? columns[11]
              : null,
        ),
      );
    }
    return imported.where((tx) => tx.quantity > 0 && tx.price >= 0).toList();
  }
}

String newPortfolioId() => DateTime.now().microsecondsSinceEpoch.toString();

String _escapeCsv(String value) {
  if (!value.contains(RegExp('[,"\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}

List<String> _splitCsv(String row) {
  final values = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var i = 0; i < row.length; i++) {
    final char = row[i];
    if (char == '"') {
      if (quoted && i + 1 < row.length && row[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      values.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  values.add(buffer.toString());
  return values;
}
