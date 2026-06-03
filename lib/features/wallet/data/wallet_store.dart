import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';

class WalletStore {
  static const storageKey = StorageKeys.walletWatchlist;

  Future<List<WatchedWallet>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(WatchedWallet.fromJson)
        .whereType<WatchedWallet>()
        .toList();
  }

  Future<void> save(List<WatchedWallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    if (wallets.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(
      storageKey,
      jsonEncode(wallets.map((wallet) => wallet.toJson()).toList()),
    );
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
