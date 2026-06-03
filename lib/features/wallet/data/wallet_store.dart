import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/storage/json_preferences_store.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';

class WalletStore {
  const WalletStore();

  static const storageKey = StorageKeys.walletWatchlist;
  static const _store = JsonPreferencesStore(storageKey);

  Future<List<WatchedWallet>> load() async {
    final decoded = await _store.load();
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(WatchedWallet.fromJson)
        .whereType<WatchedWallet>()
        .toList();
  }

  Future<void> save(List<WatchedWallet> wallets) async {
    if (wallets.isEmpty) {
      await _store.remove();
      return;
    }
    await _store.save(wallets.map((wallet) => wallet.toJson()).toList());
  }

  Future<void> add(WatchedWallet wallet) async {
    final wallets = await load();
    final exists = wallets.any(
      (item) =>
          item.chain == wallet.chain &&
          item.address.toLowerCase() == wallet.address.toLowerCase(),
    );
    if (exists) return;
    await save([wallet, ...wallets]);
  }
}
