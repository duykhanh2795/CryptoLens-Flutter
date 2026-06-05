import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/home/data/home_portfolio_summary_loader.dart';
import 'package:cryptolens_flutter/features/home/domain/home_portfolio_summary.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_format_helpers.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

class BankingDashboardGrid extends StatelessWidget {
  const BankingDashboardGrid({
    required this.controller,
    required this.watchlistCount,
    required this.coverageCount,
    required this.onOpenPortfolio,
    super.key,
  });

  final MarketController controller;
  final int watchlistCount;
  final int coverageCount;
  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<HomePortfolioSummary>(
          future: const HomePortfolioSummaryLoader().load(controller),
          builder: (context, snapshot) {
            return WalletHeroCard(
              summary: snapshot.data ?? HomePortfolioSummary.empty(),
              isLoading: snapshot.connectionState != ConnectionState.done,
              onTap: onOpenPortfolio,
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BankingInfoCard(
                title: 'Transactions',
                subtitle: 'Spent in October',
                icon: Icons.receipt_long_rounded,
                footer: Row(
                  children: const [
                    MiniDot(Color(0xFF7C6FE8)),
                    MiniDot(AppColors.green),
                    MiniDot(AppColors.accent),
                    MiniDot(AppColors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BankingInfoCard(
                title: 'Cashback',
                subtitle: 'Portfolio rewards',
                icon: Icons.account_balance_wallet_rounded,
                footer: Row(
                  children: [
                    MiniAssetCoin('B', const Color(0xFF3A3A3D)),
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: MiniAssetCoin('E', const Color(0xFF555A62)),
                    ),
                    Transform.translate(
                      offset: const Offset(-12, 0),
                      child: MiniAssetCoin('U', const Color(0xFF757B84)),
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
                MiniActionButton(Icons.qr_code_scanner_rounded),
                SizedBox(height: 8),
                MiniActionButton(Icons.add_rounded),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SmallServiceCard(
                label: 'Tips and training',
                icon: Icons.school_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SmallServiceCard(
                label: 'All services',
                icon: Icons.grid_view_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ReferCard(watchlistCount: watchlistCount, coverageCount: coverageCount),
      ],
    );
  }
}

class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({
    required this.summary,
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final HomePortfolioSummary summary;
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
                        const AppInlineLoader(
                          dimension: 10,
                          strokeWidth: 1.6,
                          color: AppColors.textSecondary,
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
                          '${signedHomeMoney(summary.dayChange)} (${formatPercent(summary.dayChangePercent)}) today',
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
                      '${summary.assetCount} assets - Total P&L ${signedHomeMoney(summary.totalPnl)}',
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
                  MiniAssetCoin('B', const Color(0xFF4A4A4D)),
                  Transform.translate(
                    offset: const Offset(-7, 0),
                    child: MiniAssetCoin('E', const Color(0xFF6D737C)),
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

class BankingInfoCard extends StatelessWidget {
  const BankingInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.footer,
    super.key,
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
              InsetIcon(icon, size: 24, iconSize: 13),
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
            style: homeCardTitle,
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: homeCardSub,
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

class SmallServiceCard extends StatelessWidget {
  const SmallServiceCard({required this.label, required this.icon, super.key});

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
          InsetIcon(icon, primary: true),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: homeCardTitle,
          ),
        ],
      ),
    );
  }
}

class ReferCard extends StatelessWidget {
  const ReferCard({
    required this.watchlistCount,
    required this.coverageCount,
    super.key,
  });

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
                const Text('Refer and Earn', style: homeCardTitle),
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
                  child: const Text('Learn more', style: homeCardTitle),
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
                Text('$watchlistCount watchlist', style: homeCardTitle),
                const SizedBox(height: 4),
                Text('$coverageCount assets', style: homeCardSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsetIcon extends StatelessWidget {
  const InsetIcon(
    this.icon, {
    this.primary = false,
    this.size = 28,
    this.iconSize = 15,
    super.key,
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

class MiniActionButton extends StatelessWidget {
  const MiniActionButton(this.icon, {super.key});

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

class MiniAssetCoin extends StatelessWidget {
  const MiniAssetCoin(this.label, this.color, {super.key});

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

class MiniDot extends StatelessWidget {
  const MiniDot(this.color, {super.key});

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

const homeCardTitle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w800,
);

const homeCardSub = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);
