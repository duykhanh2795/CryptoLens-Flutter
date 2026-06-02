import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class PortfolioStore {
  static const storageKey = 'cryptolens.portfolio.transactions_csv';
  static const snapshotsKey = 'cryptolens.portfolio.snapshots';

  Future<List<PortfolioTransaction>> load({
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(storageKey);
    if (csv == null || csv.trim().isEmpty) return const [];
    return parseCsv(csv, coinResolver: coinResolver);
  }

  Future<void> save(List<PortfolioTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final csv = exportCsv(transactions);
    if (csv.isEmpty) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, csv);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    await prefs.remove(snapshotsKey);
  }

  Future<List<PortfolioSnapshot>> loadSnapshots({int limit = 90}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(snapshotsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final snapshots =
        decoded
            .whereType<Map<String, Object?>>()
            .map(PortfolioSnapshot.fromJson)
            .whereType<PortfolioSnapshot>()
            .toList()
          ..sort((a, b) => b.dayStart.compareTo(a.dayStart));
    return snapshots.take(limit).toList();
  }

  Future<void> saveSnapshot(PortfolioSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSnapshots(limit: 120);
    final day = _dayStart(snapshot.dayStart);
    final merged = [
      snapshot,
      ...existing.where((item) => _dayStart(item.dayStart) != day),
    ]..sort((a, b) => b.dayStart.compareTo(a.dayStart));
    await prefs.setString(
      snapshotsKey,
      jsonEncode(merged.take(90).map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(snapshotsKey);
  }

  Future<int> mergeImported(
    List<PortfolioTransaction> imported, {
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
  }) async {
    final existing = await load(coinResolver: coinResolver);
    final ids = existing.map((tx) => tx.id).toSet();
    final merged = [...existing];
    var added = 0;
    for (final tx in imported) {
      if (ids.add(tx.id)) {
        merged.insert(0, tx);
        added++;
      }
    }
    await save(merged);
    return added;
  }

  Future<PortfolioImportPreview> previewCsv(
    String input, {
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
  }) async {
    final transactions = parseCsv(input, coinResolver: coinResolver);
    if (transactions.isEmpty) {
      throw const PortfolioCsvException('No valid transactions found.');
    }
    return PortfolioImportPreview(transactions: transactions);
  }

  Future<int> importTransactions(
    List<PortfolioTransaction> imported, {
    required PortfolioImportMode mode,
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
  }) async {
    final normalizedImports = imported.distinctById();
    if (normalizedImports.isEmpty) {
      throw const PortfolioCsvException('No transactions to import.');
    }
    final existing = mode == PortfolioImportMode.append
        ? await load(coinResolver: coinResolver)
        : const <PortfolioTransaction>[];
    final importedIds = normalizedImports.map((tx) => tx.id).toSet();
    final completeHistory = [
      ...existing.where((tx) => !importedIds.contains(tx.id)),
      ...normalizedImports,
    ];
    validateHoldings(completeHistory);
    if (mode == PortfolioImportMode.replace) {
      await clearSnapshots();
    }
    await save(completeHistory..sortByNewest());
    return normalizedImports.length;
  }

  static void validateHoldings(List<PortfolioTransaction> transactions) {
    final sorted = [...transactions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final holdings = <String, double>{};
    for (final tx in sorted) {
      final current = holdings[tx.coin.id] ?? 0;
      if (tx.type == PortfolioTransactionType.buy) {
        holdings[tx.coin.id] = current + tx.quantity;
      } else {
        if (tx.quantity > current + 0.00000001) {
          throw PortfolioValidationException(
            'Imported ${tx.coin.symbol} sells more than current holdings.',
          );
        }
        holdings[tx.coin.id] = current - tx.quantity;
      }
    }
  }

  static String exportCsv(List<PortfolioTransaction> transactions) {
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

  static List<PortfolioTransaction> parseCsv(
    String input, {
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
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
          quantity: double.tryParse(columns[6]) ?? 0,
          price: double.tryParse(columns[7]) ?? coin.currentPrice,
          fee: double.tryParse(columns[8]) ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(columns[9]) ?? DateTime.now().millisecondsSinceEpoch,
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

DateTime _dayStart(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class PortfolioCsvException implements Exception {
  const PortfolioCsvException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PortfolioValidationException implements Exception {
  const PortfolioValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension PortfolioTransactionListOps on List<PortfolioTransaction> {
  List<PortfolioTransaction> distinctById() {
    final ids = <String>{};
    final result = <PortfolioTransaction>[];
    for (final tx in this) {
      if (ids.add(tx.id)) result.add(tx);
    }
    return result;
  }

  void sortByNewest() {
    sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
