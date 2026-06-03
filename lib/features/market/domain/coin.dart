import 'package:cryptolens_flutter/core/utils/json_readers.dart';

class Coin {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPrice,
    required this.priceChangePercent24h,
    required this.priceChange24h,
    required this.marketCap,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.circulatingSupply,
    required this.rank,
    required this.lastUpdated,
  });

  final String id;
  final String symbol;
  final String name;
  final String imageUrl;
  final double currentPrice;
  final double priceChangePercent24h;
  final double priceChange24h;
  final double marketCap;
  final double volume24h;
  final double high24h;
  final double low24h;
  final double circulatingSupply;
  final int rank;
  final DateTime lastUpdated;

  bool get isPositive => priceChangePercent24h >= 0;
  String get spotSymbol => '${symbol.toUpperCase()}USDT';

  factory Coin.snapshot({
    required String id,
    required String symbol,
    required String name,
    required String imageUrl,
    double currentPrice = 0,
  }) {
    return Coin(
      id: id,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
      currentPrice: currentPrice,
      priceChangePercent24h: 0,
      priceChange24h: 0,
      marketCap: 0,
      volume24h: 0,
      high24h: 0,
      low24h: 0,
      circulatingSupply: 0,
      rank: 0,
      lastUpdated: DateTime.now(),
    );
  }

  Coin copyWith({
    String? id,
    String? symbol,
    String? name,
    String? imageUrl,
    double? currentPrice,
    double? priceChangePercent24h,
    double? priceChange24h,
    double? marketCap,
    double? volume24h,
    double? high24h,
    double? low24h,
    double? circulatingSupply,
    int? rank,
    DateTime? lastUpdated,
  }) {
    return Coin(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChangePercent24h:
          priceChangePercent24h ?? this.priceChangePercent24h,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      marketCap: marketCap ?? this.marketCap,
      volume24h: volume24h ?? this.volume24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      circulatingSupply: circulatingSupply ?? this.circulatingSupply,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory Coin.fromCoinGecko(Map<String, dynamic> json) {
    return Coin(
      id: readString(json['id']),
      symbol: readString(json['symbol']).toUpperCase(),
      name: readString(json['name']),
      imageUrl: readString(json['image']),
      currentPrice: readDouble(json['current_price']),
      priceChangePercent24h: readDouble(json['price_change_percentage_24h']),
      priceChange24h: readDouble(json['price_change_24h']),
      marketCap: readDouble(json['market_cap']),
      volume24h: readDouble(json['total_volume']),
      high24h: readDouble(json['high_24h']),
      low24h: readDouble(json['low_24h']),
      circulatingSupply: readDouble(json['circulating_supply']),
      rank: readInt(json['market_cap_rank']),
      lastUpdated: readDateTime(json['last_updated']),
    );
  }

  Coin applyTicker(PriceTicker ticker) {
    if (ticker.price <= 0) return this;
    return copyWith(
      currentPrice: ticker.price,
      priceChangePercent24h: ticker.priceChangePercent,
      volume24h: ticker.volume,
      high24h: ticker.high,
      low24h: ticker.low,
      lastUpdated: DateTime.now(),
    );
  }
}

class PriceTicker {
  const PriceTicker({
    required this.symbol,
    required this.price,
    required this.priceChangePercent,
    required this.volume,
    required this.high,
    required this.low,
  });

  final String symbol;
  final double price;
  final double priceChangePercent;
  final double volume;
  final double high;
  final double low;

  factory PriceTicker.fromBinance(Map<String, dynamic> json) {
    return PriceTicker(
      symbol: readString(json['symbol']),
      price: readDouble(json['lastPrice']),
      priceChangePercent: readDouble(json['priceChangePercent']),
      volume: readDouble(json['quoteVolume']),
      high: readDouble(json['highPrice']),
      low: readDouble(json['lowPrice']),
    );
  }
}

class CoinDetail {
  const CoinDetail({
    required this.coin,
    required this.description,
    required this.homepageUrl,
    required this.githubUrl,
    required this.allTimeHigh,
    required this.allTimeHighDate,
    required this.allTimeLow,
    required this.allTimeLowDate,
    required this.totalSupply,
    required this.maxSupply,
  });

  final Coin coin;
  final String description;
  final String homepageUrl;
  final String githubUrl;
  final double allTimeHigh;
  final String allTimeHighDate;
  final double allTimeLow;
  final String allTimeLowDate;
  final double totalSupply;
  final double maxSupply;

  factory CoinDetail.fromCoinGecko(Map<String, dynamic> json) {
    final marketData = readObjectMap(json['market_data']);
    final image = readObjectMap(json['image']);
    final links = readObjectMap(json['links']);
    final reposUrl = readObjectMap(links['repos_url']);
    final description = readObjectMap(json['description']);

    double usd(String key) {
      final values = readObjectMap(marketData[key]);
      return readDouble(values['usd']);
    }

    String usdDate(String key) {
      final values = readObjectMap(marketData[key]);
      return readString(values['usd']);
    }

    final coin = Coin(
      id: readString(json['id']),
      symbol: readString(json['symbol']).toUpperCase(),
      name: readString(json['name']),
      imageUrl: readString(image['large']),
      currentPrice: usd('current_price'),
      priceChangePercent24h: readDouble(
        marketData['price_change_percentage_24h'],
      ),
      priceChange24h: 0,
      marketCap: usd('market_cap'),
      volume24h: usd('total_volume'),
      high24h: usd('high_24h'),
      low24h: usd('low_24h'),
      circulatingSupply: readDouble(marketData['circulating_supply']),
      rank: readInt(json['market_cap_rank']),
      lastUpdated: DateTime.now(),
    );

    return CoinDetail(
      coin: coin,
      description: _stripHtml(readString(description['en'])),
      homepageUrl: _firstString(links['homepage']),
      githubUrl: _firstString(reposUrl['github']),
      allTimeHigh: usd('ath'),
      allTimeHighDate: usdDate('ath_date'),
      allTimeLow: usd('atl'),
      allTimeLowDate: usdDate('atl_date'),
      totalSupply: readDouble(marketData['total_supply']),
      maxSupply: readDouble(marketData['max_supply']),
    );
  }
}

String _firstString(Object? value) {
  if (value is List && value.isNotEmpty) {
    return value.whereType<String>().firstWhere(
      (item) => item.trim().isNotEmpty,
      orElse: () => '',
    );
  }
  return '';
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
