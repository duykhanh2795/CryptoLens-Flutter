import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/coin.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/coin_detail_screen.dart';
import '../market/market_controller.dart';
import '../news/news_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.controller,
    required this.onOpenMarkets,
    required this.onOpenNews,
    super.key,
  });

  final MarketController controller;
  final VoidCallback onOpenMarkets;
  final VoidCallback onOpenNews;

  @override
  Widget build(BuildContext context) {
    final trending = controller.coins.take(8).toList();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _HomeTopBar(
            isRefreshing: controller.isRefreshing,
            onRefresh: controller.refresh,
          ),
          const SizedBox(height: 12),
          if (controller.error != null)
            _ErrorBanner(message: controller.error!),
          _BankingDashboardGrid(
            portfolioValue: 0,
            watchlistCount: controller.watchlistedIds.length,
            coverageCount: controller.coins.length,
          ),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: 14),
            _TrendingSectionHeader(onTap: onOpenMarkets),
            const SizedBox(height: 8),
            _TrendingRow(
              coins: trending,
              onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
            ),
            const SizedBox(height: 18),
            _MarketMoveSection(
              title: 'Top Gainers',
              coins: controller.topGainers,
              onSeeAll: onOpenMarkets,
              onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
            ),
            const SizedBox(height: 8),
            _MarketMoveSection(
              title: 'Top Losers',
              coins: controller.topLosers,
              onSeeAll: onOpenMarkets,
              onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
            ),
            const SizedBox(height: 8),
            const _TrendingWalletsHomeSection(),
          ],
          const SizedBox(height: 22),
          NewsPreviewSection(onSeeAll: onOpenNews),
          const SizedBox(height: 14),
          const _AiInsightBanner(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

void _openCoinDetail(
  BuildContext context,
  MarketController controller,
  Coin coin,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CoinDetailScreen(controller: controller, coin: coin),
    ),
  );
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.isRefreshing, required this.onRefresh});

  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3A3A3C), Color(0xFF171719)],
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search assets, wallets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: isRefreshing ? Icons.sync_rounded : Icons.refresh_rounded,
          onTap: onRefresh,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _BankingDashboardGrid extends StatelessWidget {
  const _BankingDashboardGrid({
    required this.portfolioValue,
    required this.watchlistCount,
    required this.coverageCount,
  });

  final double portfolioValue;
  final int watchlistCount;
  final int coverageCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WalletHeroCard(value: portfolioValue),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BankingInfoCard(
                title: 'Transactions',
                subtitle: 'Spent in October',
                icon: Icons.receipt_long_rounded,
                footer: Row(
                  children: const [
                    _MiniDot(Color(0xFF7C6FE8)),
                    _MiniDot(AppColors.green),
                    _MiniDot(AppColors.accent),
                    _MiniDot(AppColors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BankingInfoCard(
                title: 'Cashback',
                subtitle: 'Portfolio rewards',
                icon: Icons.account_balance_wallet_rounded,
                footer: Row(
                  children: [
                    _MiniAssetCoin('B', const Color(0xFF3A3A3D)),
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: _MiniAssetCoin('E', const Color(0xFF555A62)),
                    ),
                    Transform.translate(
                      offset: const Offset(-12, 0),
                      child: _MiniAssetCoin('U', const Color(0xFF757B84)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Column(
              children: const [
                _MiniActionButton(Icons.qr_code_scanner_rounded),
                SizedBox(height: 8),
                _MiniActionButton(Icons.add_rounded),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallServiceCard(
                label: 'Tips and training',
                icon: Icons.school_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallServiceCard(
                label: 'All services',
                icon: Icons.grid_view_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReferCard(
          watchlistCount: watchlistCount,
          coverageCount: coverageCount,
        ),
      ],
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF242426), Color(0xFF121214), Color(0xFF0A0A0B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -24,
            child: Transform.rotate(
              angle: 0.32,
              child: Container(
                width: 180,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 17),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  formatPrice(value),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Portfolio value',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                _MiniAssetCoin('B', const Color(0xFF4A4A4D)),
                Transform.translate(
                  offset: const Offset(-7, 0),
                  child: _MiniAssetCoin('E', const Color(0xFF6D737C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankingInfoCard extends StatelessWidget {
  const _BankingInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171719),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InsetIcon(icon, size: 24, iconSize: 13),
              const Spacer(),
              const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _homeCardTitle,
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _homeCardSub,
          ),
          const Spacer(),
          SizedBox(
            height: 12,
            child: Align(alignment: Alignment.centerLeft, child: footer),
          ),
        ],
      ),
    );
  }
}

class _SmallServiceCard extends StatelessWidget {
  const _SmallServiceCard({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 76,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171719),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InsetIcon(icon, primary: true),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _homeCardTitle,
          ),
        ],
      ),
    );
  }
}

class _ReferCard extends StatelessWidget {
  const _ReferCard({required this.watchlistCount, required this.coverageCount});

  final int watchlistCount;
  final int coverageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF202022), Color(0xFF141416), Color(0xFF0F0F10)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Refer and Earn', style: _homeCardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Share a referral link and get rewarded',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Learn more', style: _homeCardTitle),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$watchlistCount watchlist', style: _homeCardTitle),
                const SizedBox(height: 4),
                Text('$coverageCount assets', style: _homeCardSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsetIcon extends StatelessWidget {
  const _InsetIcon(
    this.icon, {
    this.primary = false,
    this.size = 28,
    this.iconSize = 15,
  });

  final IconData icon;
  final bool primary;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        color: primary ? AppColors.textPrimary : AppColors.textSecondary,
        size: iconSize,
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF171719),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 17),
    );
  }
}

class _MiniAssetCoin extends StatelessWidget {
  const _MiniAssetCoin(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF121214), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  const _MiniDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

const _homeCardTitle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w800,
);

const _homeCardSub = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

class _TrendingSectionHeader extends StatelessWidget {
  const _TrendingSectionHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Pulse',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Live prices and momentum',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('See All'),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendingRow extends StatelessWidget {
  const _TrendingRow({required this.coins, required this.onCoinTap});

  final List<Coin> coins;
  final ValueChanged<Coin> onCoinTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coins.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final coin = coins[index];
          return _TrendingCoinCard(coin: coin, onTap: () => onCoinTap(coin));
        },
      ),
    );
  }
}

class _TrendingCoinCard extends StatelessWidget {
  const _TrendingCoinCard({required this.coin, required this.onTap});

  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = coin.isPositive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 146,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${coin.name}  /  ${coin.symbol}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatPrice(coin.currentPrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  formatPercent(coin.priceChangePercent24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '|',
                  style: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatSignedPriceDelta(coin.priceChange24h),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 42,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: _sparklineValues(coin),
                  color: changeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketMoveSection extends StatelessWidget {
  const _MarketMoveSection({
    required this.title,
    required this.coins,
    required this.onSeeAll,
    required this.onCoinTap,
  });

  final String title;
  final List<Coin> coins;
  final VoidCallback onSeeAll;
  final ValueChanged<Coin> onCoinTap;

  @override
  Widget build(BuildContext context) {
    if (coins.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('More'),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        for (final coin in coins)
          _MarketMoveRow(coin: coin, onTap: () => onCoinTap(coin)),
      ],
    );
  }
}

class _MarketMoveRow extends StatelessWidget {
  const _MarketMoveRow({required this.coin, required this.onTap});

  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = coin.isPositive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coin.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPercent(coin.priceChangePercent24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPrice(coin.currentPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingWalletsHomeSection extends StatelessWidget {
  const _TrendingWalletsHomeSection();

  static const _wallets = [
    ('Ethereum', '0x742d...44e', '+18.4%', '3.8M'),
    ('BSC', '0x8894...88f', '+9.2%', '1.9M'),
    ('Polygon', '0x3f5c...1b7', '-2.1%', '860K'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Trending Addresses',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('More'),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        for (final wallet in _wallets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.$1,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        wallet.$2,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  wallet.$4,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  wallet.$3,
                  style: TextStyle(
                    color: wallet.$3.startsWith('-')
                        ? AppColors.red
                        : AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AiInsightBanner extends StatelessWidget {
  const _AiInsightBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accentContainer,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Market Insight',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Get AI-powered Buy/Sell signals in Vietnamese',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.red)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.000001);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = (1 - (values[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

List<double> _sparklineValues(Coin coin) {
  final base = coin.currentPrice <= 0 ? 1.0 : coin.currentPrice;
  final direction = coin.isPositive ? 1.0 : -1.0;
  final amplitude = (coin.priceChangePercent24h.abs() / 100).clamp(
    0.009,
    0.055,
  );
  final seed = coin.id.hashCode.abs();
  return List.generate(18, (index) {
    final progress = index / 17.0;
    final wave = math.sin((index + seed % 5) * 1.18) * 0.46;
    final counter = math.cos(index * 1.73 + seed % 9) * 0.24;
    final jitter = (((seed >> (index % 12)) & 7) - 3) / 15.0;
    final trend = (progress - 0.5) * direction * 0.95;
    return base * (1.0 + (wave + counter + jitter + trend) * amplitude);
  });
}

String _formatSignedPriceDelta(double value) {
  final absolute = value.abs();
  final formatted = absolute >= 1
      ? formatPrice(absolute)
      : formatPrice(absolute);
  return '${value >= 0 ? '+' : '-'}${formatted.replaceFirst(r'$', r'$')}';
}
