import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/errors/app_exception.dart';
import 'package:cryptolens_flutter/core/storage/json_preferences_store.dart';
import 'package:cryptolens_flutter/core/storage/preferences_store.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_csv_codec.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class PortfolioStore {
  const PortfolioStore();

  static const storageKey = StorageKeys.portfolioTransactionsCsv;
  static const snapshotsKey = StorageKeys.portfolioSnapshots;
  static const _preferences = PreferencesStore();
  static const _snapshotStore = JsonPreferencesStore(snapshotsKey);
  static const _csvCodec = PortfolioCsvCodec();

  Future<List<PortfolioTransaction>> load({
    required Coin Function(
      String coinId,
      String symbol,
      String name,
      String imageUrl,
    )
    coinResolver,
  }) async {
    final csv = await _preferences.getString(storageKey);
    if (csv == null || csv.trim().isEmpty) return const [];
    return _csvCodec.decode(csv, coinResolver: coinResolver);
  }

  Future<void> save(List<PortfolioTransaction> transactions) async {
    final csv = _csvCodec.encode(transactions);
    if (csv.isEmpty) {
      await _preferences.remove(storageKey);
    } else {
      await _preferences.setString(storageKey, csv);
    }
  }

  Future<void> clear() async {
    await _preferences.removeAll([storageKey, snapshotsKey]);
  }

  Future<List<PortfolioSnapshot>> loadSnapshots({int limit = 90}) async {
    final decoded = await _snapshotStore.load();
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
    final existing = await loadSnapshots(limit: 120);
    final day = _dayStart(snapshot.dayStart);
    final merged = [
      snapshot,
      ...existing.where((item) => _dayStart(item.dayStart) != day),
    ]..sort((a, b) => b.dayStart.compareTo(a.dayStart));
    await _snapshotStore.save(
      merged.take(90).map((item) => item.toJson()).toList(),
    );
  }

  Future<void> clearSnapshots() async {
    await _snapshotStore.remove();
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
    final transactions = _csvCodec.decode(input, coinResolver: coinResolver);
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
    return _csvCodec.encode(transactions);
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
    return _csvCodec.decode(input, coinResolver: coinResolver);
  }
}

DateTime _dayStart(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class PortfolioCsvException extends AppException {
  const PortfolioCsvException(super.message);
}

class PortfolioValidationException extends AppException {
  const PortfolioValidationException(super.message);
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
