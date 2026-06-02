part of '../screens/home_screen.dart';

class _BankingDashboardGrid extends StatelessWidget {
  const _BankingDashboardGrid({
    required this.controller,
    required this.watchlistCount,
    required this.coverageCount,
    required this.onOpenPortfolio,
  });

  final MarketController controller;
  final int watchlistCount;
  final int coverageCount;
  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<_HomePortfolioSummary>(
          future: _HomePortfolioSummary.load(controller),
          builder: (context, snapshot) {
            return _WalletHeroCard(
              summary: snapshot.data ?? _HomePortfolioSummary.empty(),
              isLoading: snapshot.connectionState != ConnectionState.done,
              onTap: onOpenPortfolio,
            );
          },
        ),
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
  const _WalletHeroCard({
    required this.summary,
    required this.isLoading,
    required this.onTap,
  });

  final _HomePortfolioSummary summary;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayUp = summary.dayChange >= 0;
    final pnlUp = summary.totalPnl >= 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
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
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Portfolio',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox.square(
                          dimension: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.6),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(summary.totalValue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (summary.transactionCount == 0)
                    const Text(
                      '0 assets - Add your first transaction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(
                          '${_signedMoney(summary.dayChange)} (${formatPercent(summary.dayChangePercent)}) today',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: dayUp ? AppColors.green : AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.assetCount} assets - Total P&L ${_signedMoney(summary.totalPnl)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pnlUp ? AppColors.textSecondary : AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
      ),
    );
  }
}

class _HomePortfolioSummary {
  const _HomePortfolioSummary({
    required this.totalValue,
    required this.dayChange,
    required this.dayChangePercent,
    required this.totalPnl,
    required this.assetCount,
    required this.transactionCount,
  });

  final double totalValue;
  final double dayChange;
  final double dayChangePercent;
  final double totalPnl;
  final int assetCount;
  final int transactionCount;

  static _HomePortfolioSummary empty() => const _HomePortfolioSummary(
    totalValue: 0,
    dayChange: 0,
    dayChangePercent: 0,
    totalPnl: 0,
    assetCount: 0,
    transactionCount: 0,
  );

  static Future<_HomePortfolioSummary> load(MarketController controller) async {
    final store = PortfolioStore();
    final transactions = await store.load(
      coinResolver: (coinId, symbol, name, imageUrl) {
        for (final coin in controller.coins) {
          if (coin.id == coinId) return coin;
        }
        return Coin(
          id: coinId,
          symbol: symbol,
          name: name,
          imageUrl: imageUrl,
          currentPrice: 0,
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
      },
    );
    if (transactions.isEmpty) return empty();

    final byCoin = <String, List<PortfolioTransaction>>{};
    for (final tx in transactions) {
      byCoin.putIfAbsent(tx.coin.id, () => []).add(tx);
    }

    var totalValue = 0.0;
    var invested = 0.0;
    var realized = 0.0;
    var dayChange = 0.0;
    var assetCount = 0;

    for (final entry in byCoin.entries) {
      final txs = [...entry.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var quantity = 0.0;
      var costBasis = 0.0;
      var coinRealized = 0.0;
      for (final tx in txs) {
        if (tx.type == PortfolioTransactionType.buy) {
          quantity += tx.quantity;
          costBasis += tx.quantity * tx.price + tx.fee;
        } else {
          final average = quantity <= 0 ? 0.0 : costBasis / quantity;
          final sold = math.min(quantity, tx.quantity);
          coinRealized += sold * (tx.price - average) - tx.fee;
          quantity -= sold;
          costBasis -= average * sold;
        }
      }
      if (quantity <= 0.00000001) {
        realized += coinRealized;
        continue;
      }
      final coin = _liveCoin(controller, entry.key) ?? txs.last.coin;
      final value = quantity * coin.currentPrice;
      totalValue += value;
      invested += costBasis;
      realized += coinRealized;
      dayChange += quantity * coin.priceChange24h;
      assetCount++;
    }

    final previousValue = math.max(totalValue - dayChange, 0.01);
    return _HomePortfolioSummary(
      totalValue: totalValue,
      dayChange: dayChange,
      dayChangePercent: dayChange / previousValue * 100,
      totalPnl: totalValue - invested + realized,
      assetCount: assetCount,
      transactionCount: transactions.length,
    );
  }

  static Coin? _liveCoin(MarketController controller, String coinId) {
    for (final coin in controller.coins) {
      if (coin.id == coinId) return coin;
    }
    return null;
  }
}

String _signedMoney(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatPrice(value.abs())}';
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
