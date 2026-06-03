import 'dart:math';

import 'package:cryptolens_flutter/core/utils/json_readers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

enum WalletChain {
  bitcoin('Bitcoin', 'BTC', [
    'bitcoin',
  ], 'https://www.blockchain.com/explorer/addresses/btc/'),
  ethereum('Ethereum', 'ETH', ['ethereum'], 'https://etherscan.io/address/'),
  bnbChain('BNB Chain', 'BNB', ['binancecoin'], 'https://bscscan.com/address/'),
  polygon('Polygon', 'POL', [
    'polygon-ecosystem-token',
    'matic-network',
  ], 'https://polygonscan.com/address/');

  const WalletChain(
    this.label,
    this.nativeSymbol,
    this.priceCoinIds,
    this.explorerBaseUrl,
  );

  final String label;
  final String nativeSymbol;
  final List<String> priceCoinIds;
  final String explorerBaseUrl;

  String get moralisChain => switch (this) {
    WalletChain.ethereum => 'eth',
    WalletChain.bnbChain => 'bsc',
    WalletChain.polygon => 'polygon',
    WalletChain.bitcoin => 'btc',
  };

  String? get alchemyNetwork => switch (this) {
    WalletChain.ethereum => 'eth-mainnet',
    WalletChain.bnbChain => 'bnb-mainnet',
    WalletChain.polygon => 'polygon-mainnet',
    WalletChain.bitcoin => null,
  };
}

class WatchedWallet {
  const WatchedWallet({
    required this.id,
    required this.label,
    required this.chain,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final String label;
  final WalletChain chain;
  final String address;
  final DateTime createdAt;

  String get shortAddress => shortWalletAddress(address);

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'chain': chain.name,
    'address': address,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  static WatchedWallet? fromJson(Map<String, Object?> json) {
    final address = json['address']?.toString();
    if (address == null || address.length < 8) return null;
    return WatchedWallet(
      id: readString(
        json['id'],
        fallback: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      label: readString(json['label'], fallback: 'Wallet'),
      chain:
          readEnum(WalletChain.values, json['chain']) ??
          _legacyChain(json['chain']) ??
          WalletChain.ethereum,
      address: address,
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class TrendingWallet {
  const TrendingWallet({
    required this.chain,
    required this.address,
    required this.label,
    required this.nativeBalance,
    required this.txCount,
    required this.valueUsd,
    required this.changePercent24h,
    required this.avatarSeed,
  });

  final WalletChain chain;
  final String address;
  final String label;
  final double nativeBalance;
  final int txCount;
  final double? valueUsd;
  final double changePercent24h;
  final int avatarSeed;

  String get displayName => shortWalletAddress(address);
  String get shortAddress => shortWalletAddress(address);
  bool get isPositive => changePercent24h >= 0;
}

class TrendingWalletDetail {
  const TrendingWalletDetail({
    required this.wallet,
    required this.assets,
    required this.history,
    this.historyNote,
  });

  final TrendingWallet wallet;
  final List<WalletAsset> assets;
  final List<WalletTransaction> history;
  final String? historyNote;

  double? get totalValueUsd {
    final values = assets.map((asset) => asset.valueUsd).whereType<double>();
    if (values.isEmpty) return null;
    return values.fold<double>(0, (sum, value) => sum + value);
  }
}

class WalletAsset {
  const WalletAsset({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    required this.changePercent24h,
    required this.chain,
    this.networkLabel,
    this.contractAddress,
    this.coinId,
    this.logoUrl,
  });

  final String symbol;
  final String name;
  final double quantity;
  final double? priceUsd;
  final double? valueUsd;
  final double changePercent24h;
  final WalletChain chain;
  final String? networkLabel;
  final String? contractAddress;
  final String? coinId;
  final String? logoUrl;

  String get displayNetwork => networkLabel ?? chain.label;
}

enum WalletTransactionType { received, sent, executed }

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.symbol,
    required this.amount,
    required this.valueUsd,
    required this.counterparty,
    required this.timestamp,
    required this.networkLabel,
  });

  final String id;
  final WalletTransactionType type;
  final String symbol;
  final double amount;
  final double? valueUsd;
  final String? counterparty;
  final DateTime timestamp;
  final String networkLabel;
}

class TrendingWalletSeed {
  const TrendingWalletSeed({
    required this.label,
    required this.address,
    required this.chain,
    required this.changePercent24h,
    required this.avatarSeed,
    required this.fallbackNativeBalance,
    required this.fallbackTxCount,
  });

  final String label;
  final String address;
  final WalletChain chain;
  final double changePercent24h;
  final int avatarSeed;
  final double fallbackNativeBalance;
  final int fallbackTxCount;
}

List<TrendingWallet> buildTrendingWallets(List<Coin> coins) {
  final wallets = [
    for (var i = 0; i < trendingWalletSeeds.length; i++)
      _seedToWallet(trendingWalletSeeds[i], i, coins),
  ];
  wallets.sortByValueDesc();
  return wallets;
}

TrendingWalletDetail buildTrendingWalletDetail(
  TrendingWallet wallet,
  List<Coin> coins, {
  List<WalletAsset>? indexedAssets,
  List<WalletTransaction>? indexedHistory,
  String? historyNote,
}) {
  final nativeCoin = _nativeCoin(wallet.chain, coins);
  final nativeAsset = WalletAsset(
    symbol: wallet.chain.nativeSymbol,
    name: wallet.chain.label,
    quantity: wallet.nativeBalance,
    priceUsd: nativeCoin?.currentPrice,
    valueUsd: wallet.valueUsd,
    changePercent24h:
        nativeCoin?.priceChangePercent24h ?? wallet.changePercent24h,
    chain: wallet.chain,
    coinId: nativeCoin?.id,
    logoUrl: nativeCoin?.imageUrl,
  );
  final fallbackAssets = _fallbackAssets(wallet, coins);
  final assets = [
    nativeAsset,
    ...(indexedAssets?.where((asset) => asset.quantity > 0) ?? fallbackAssets),
  ]..sort((a, b) => (b.valueUsd ?? 0).compareTo(a.valueUsd ?? 0));

  return TrendingWalletDetail(
    wallet: wallet,
    assets: assets,
    history:
        indexedHistory?.take(80).toList() ?? _fallbackHistory(wallet, assets),
    historyNote: historyNote,
  );
}

String shortWalletAddress(String address) {
  if (address.length <= 14) return address;
  return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
}

extension TrendingWalletListSort on List<TrendingWallet> {
  void sortByValueDesc() {
    sort((a, b) => (b.valueUsd ?? 0).compareTo(a.valueUsd ?? 0));
  }
}

const trendingWalletSeeds = [
  TrendingWalletSeed(
    label: 'Binance BTC Cold',
    address: '34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo',
    chain: WalletChain.bitcoin,
    changePercent24h: 0.02,
    avatarSeed: 11,
    fallbackNativeBalance: 248597.0,
    fallbackTxCount: 1049,
  ),
  TrendingWalletSeed(
    label: 'Genesis Wallet',
    address: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    chain: WalletChain.bitcoin,
    changePercent24h: -0.27,
    avatarSeed: 23,
    fallbackNativeBalance: 99.68,
    fallbackTxCount: 3765,
  ),
  TrendingWalletSeed(
    label: 'Mt. Gox Trustee',
    address: '1FeexV6bAHb8ybZjqQMjJrcCrHGW9sb6uF',
    chain: WalletChain.bitcoin,
    changePercent24h: -1.18,
    avatarSeed: 29,
    fallbackNativeBalance: 79957.26,
    fallbackTxCount: 341,
  ),
  TrendingWalletSeed(
    label: 'Beacon Deposit',
    address: '0x00000000219ab540356cBB839Cbe05303d7705Fa',
    chain: WalletChain.ethereum,
    changePercent24h: 3.73,
    avatarSeed: 37,
    fallbackNativeBalance: 2186.5,
    fallbackTxCount: 145632,
  ),
  TrendingWalletSeed(
    label: 'Binance 14',
    address: '0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549',
    chain: WalletChain.ethereum,
    changePercent24h: 0.82,
    avatarSeed: 39,
    fallbackNativeBalance: 1314.2,
    fallbackTxCount: 86421,
  ),
  TrendingWalletSeed(
    label: 'Binance ETH',
    address: '0x28C6c06298d514Db089934071355E5743bf21d60',
    chain: WalletChain.ethereum,
    changePercent24h: 1.64,
    avatarSeed: 41,
    fallbackNativeBalance: 1489.9,
    fallbackTxCount: 128770,
  ),
  TrendingWalletSeed(
    label: 'Bitfinex Cold',
    address: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    chain: WalletChain.ethereum,
    changePercent24h: -0.34,
    avatarSeed: 43,
    fallbackNativeBalance: 945.7,
    fallbackTxCount: 11842,
  ),
  TrendingWalletSeed(
    label: 'Kraken',
    address: '0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0',
    chain: WalletChain.ethereum,
    changePercent24h: 0.45,
    avatarSeed: 47,
    fallbackNativeBalance: 521.4,
    fallbackTxCount: 74438,
  ),
  TrendingWalletSeed(
    label: 'Crypto.com',
    address: '0x46340b20830761efd32832A74d7169B29FEB9758',
    chain: WalletChain.ethereum,
    changePercent24h: -0.91,
    avatarSeed: 49,
    fallbackNativeBalance: 397.8,
    fallbackTxCount: 38752,
  ),
  TrendingWalletSeed(
    label: 'Vitalik',
    address: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
    chain: WalletChain.ethereum,
    changePercent24h: -2.2,
    avatarSeed: 53,
    fallbackNativeBalance: 241.6,
    fallbackTxCount: 2641,
  ),
  TrendingWalletSeed(
    label: 'Ethereum Foundation',
    address: '0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe',
    chain: WalletChain.ethereum,
    changePercent24h: 0.18,
    avatarSeed: 59,
    fallbackNativeBalance: 318.4,
    fallbackTxCount: 6419,
  ),
  TrendingWalletSeed(
    label: 'Uniswap Treasury',
    address: '0x1a9C8182C09F50C8318d769245beA52c32BE35BC',
    chain: WalletChain.ethereum,
    changePercent24h: 2.41,
    avatarSeed: 61,
    fallbackNativeBalance: 136.0,
    fallbackTxCount: 2811,
  ),
  TrendingWalletSeed(
    label: 'Aave Collector',
    address: '0x25F2226B597E8F9514B3F68F00f494cF4f286491',
    chain: WalletChain.ethereum,
    changePercent24h: 1.09,
    avatarSeed: 63,
    fallbackNativeBalance: 110.3,
    fallbackTxCount: 8154,
  ),
  TrendingWalletSeed(
    label: 'ENS DAO',
    address: '0xFe89cc7aBB2C4183683ab71653C4CDC9B02D44b7',
    chain: WalletChain.ethereum,
    changePercent24h: -0.58,
    avatarSeed: 65,
    fallbackNativeBalance: 73.2,
    fallbackTxCount: 1456,
  ),
  TrendingWalletSeed(
    label: 'Polygon Foundation',
    address: '0x0000000000000000000000000000000000001010',
    chain: WalletChain.polygon,
    changePercent24h: 0.96,
    avatarSeed: 67,
    fallbackNativeBalance: 10789126.0,
    fallbackTxCount: 574982,
  ),
  TrendingWalletSeed(
    label: 'Polygon Bridge',
    address: '0xA0c68C638235ee32657e8f720a23ceC1bFc77C77',
    chain: WalletChain.polygon,
    changePercent24h: 1.22,
    avatarSeed: 69,
    fallbackNativeBalance: 7164521.0,
    fallbackTxCount: 188425,
  ),
  TrendingWalletSeed(
    label: 'BNB Whale',
    address: '0x8894E0a0c962CB723c1976a4421c95949bE2D4E3',
    chain: WalletChain.bnbChain,
    changePercent24h: -0.73,
    avatarSeed: 71,
    fallbackNativeBalance: 134218.0,
    fallbackTxCount: 285692,
  ),
  TrendingWalletSeed(
    label: 'Binance BNB Hot',
    address: '0xF977814e90dA44bFA03b6295A0616a897441aceC',
    chain: WalletChain.bnbChain,
    changePercent24h: 0.31,
    avatarSeed: 73,
    fallbackNativeBalance: 90431.0,
    fallbackTxCount: 184916,
  ),
];

TrendingWallet _seedToWallet(
  TrendingWalletSeed seed,
  int index,
  List<Coin> coins,
) {
  final nativeCoin = _nativeCoin(seed.chain, coins);
  final nativeBalance = seed.fallbackNativeBalance;
  return TrendingWallet(
    chain: seed.chain,
    address: seed.address,
    label: seed.label,
    nativeBalance: nativeBalance,
    txCount: seed.fallbackTxCount,
    valueUsd: nativeCoin == null
        ? null
        : nativeBalance * nativeCoin.currentPrice,
    changePercent24h: seed.changePercent24h,
    avatarSeed: seed.avatarSeed + index,
  );
}

List<WalletAsset> _fallbackAssets(TrendingWallet wallet, List<Coin> coins) {
  final pool = coins
      .where((coin) => coin.symbol != wallet.chain.nativeSymbol)
      .take(8)
      .toList();
  return [
    for (var i = 0; i < min(pool.length, 6); i++)
      WalletAsset(
        symbol: pool[i].symbol,
        name: pool[i].name,
        quantity: (0.08 + i * 0.043) * (wallet.avatarSeed % 7 + 1),
        priceUsd: pool[i].currentPrice,
        valueUsd:
            pool[i].currentPrice *
            (0.08 + i * 0.043) *
            (wallet.avatarSeed % 7 + 1),
        changePercent24h: pool[i].priceChangePercent24h,
        chain: wallet.chain,
        networkLabel: wallet.chain.label,
        coinId: pool[i].id,
        logoUrl: pool[i].imageUrl,
      ),
  ];
}

List<WalletTransaction> _fallbackHistory(
  TrendingWallet wallet,
  List<WalletAsset> assets,
) {
  final now = DateTime.now();
  final symbols = assets.isEmpty
      ? [wallet.chain.nativeSymbol]
      : assets.map((asset) => asset.symbol).take(6).toList();
  return [
    for (var i = 0; i < symbols.length; i++)
      WalletTransaction(
        id: 'fallback_${wallet.address}_$i',
        type: WalletTransactionType
            .values[i % WalletTransactionType.values.length],
        symbol: symbols[i],
        amount: 0.01 + i * 0.037,
        valueUsd: assets
            .where((asset) => asset.symbol == symbols[i])
            .firstOrNull
            ?.priceUsd,
        counterparty: wallet.address,
        timestamp: now.subtract(Duration(hours: 3 + i * 7)),
        networkLabel: wallet.chain.label,
      ),
  ];
}

Coin? _nativeCoin(WalletChain chain, List<Coin> coins) {
  for (final id in chain.priceCoinIds) {
    for (final coin in coins) {
      if (coin.id == id) return coin;
    }
  }
  for (final coin in coins) {
    if (coin.symbol.toUpperCase() == chain.nativeSymbol) return coin;
  }
  return null;
}

WalletChain? _legacyChain(Object? raw) {
  final name = raw?.toString();
  if (name == 'bsc') return WalletChain.bnbChain;
  return null;
}
