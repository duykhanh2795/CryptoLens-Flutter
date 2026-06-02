import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/state/wallet_detail_state.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_colors.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_format_helpers.dart';

class AvatarPainter extends CustomPainter {
  const AvatarPainter({
    required this.seed,
    required this.base,
    required this.colors,
  });

  final int seed;
  final Color base;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = base;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    final cell = size.width / 5;
    for (var x = 0; x < 5; x++) {
      for (var y = 0; y < 5; y++) {
        if (((x * 31 + y * 17 + seed) % 3) == 0) {
          paint.color = colors[(x + y + seed).abs() % colors.length].withValues(
            alpha: 0.9,
          );
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.base != base;
}

class WalletAvatar extends StatelessWidget {
  const WalletAvatar({
    required this.chain,
    required this.seed,
    required this.size,
    super.key,
  });

  final WalletChain chain;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    const colors = [
      WalletColors.yellow,
      Color(0xFF8A8F98),
      Color(0xFF7C6FE8),
      Color(0xFF56606B),
      Color(0xFFFF7182),
    ];
    final base = colors[seed.abs() % colors.length];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: AvatarPainter(seed: seed, base: base, colors: colors),
          ),
          Container(
            width: size * 0.37,
            height: size * 0.37,
            decoration: const BoxDecoration(
              color: WalletColors.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              chain.nativeSymbol.substring(0, 1),
              style: TextStyle(
                color: WalletColors.yellow,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletMiniChart extends StatelessWidget {
  const WalletMiniChart({required this.isPositive, super.key});

  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 92),
      painter: _MiniChartPainter(
        color: isPositive ? AppColors.green : AppColors.red,
      ),
      child: const SizedBox(height: 92, width: double.infinity),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  const _MiniChartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      0.18,
      0.34,
      0.28,
      0.48,
      0.26,
      0.62,
      0.42,
      0.55,
      0.72,
      0.50,
      0.66,
      0.78,
    ];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = 28 + (size.width - 56) * i / max(points.length - 1, 1);
      final y = 14 + (size.height - 28) * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) =>
      oldDelegate.color != color;
}

class WalletTabs extends StatelessWidget {
  const WalletTabs({
    required this.selectedTab,
    required this.onChanged,
    super.key,
  });

  final WalletDetailTab selectedTab;
  final ValueChanged<WalletDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in WalletDetailTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(tab),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        color: selectedTab == tab
                            ? WalletColors.yellow
                            : WalletColors.textSecondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: selectedTab == tab
                        ? WalletColors.yellow
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ChangePill extends StatelessWidget {
  const ChangePill({required this.percent, super.key});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final positive = percent >= 0;
    final color = positive ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '${positive ? '+' : '-'}${percent.abs().toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AssetRow extends StatelessWidget {
  const AssetRow({required this.asset, super.key});

  final WalletAsset asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          WalletAvatar(
            chain: asset.chain,
            seed: asset.symbol.hashCode,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${asset.symbol} ${formatNativeAmount(asset.quantity)}',
                  style: WalletColors.assetTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${asset.displayNetwork}  â€¢  ${asset.valueUsd == null ? 'Value unavailable' : formatCompactUsd(asset.valueUsd!)}',
                  style: WalletColors.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              formatPercent(asset.changePercent24h),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: asset.changePercent24h >= 0
                    ? AppColors.green
                    : AppColors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              asset.priceUsd == null ? '-' : formatPrice(asset.priceUsd!),
              style: WalletColors.assetTitle,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.tx, required this.onTap, super.key});

  final WalletTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = tx.type == WalletTransactionType.received;
    final color = positive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                tx.symbol.isEmpty ? '?' : tx.symbol.substring(0, 1),
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.type.label, style: WalletColors.assetTitle),
                  const SizedBox(height: 3),
                  Text(
                    tx.counterparty == null
                        ? tx.networkLabel
                        : '${positive ? 'from' : 'to'} ${shortWalletAddress(tx.counterparty!)}',
                    style: WalletColors.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${positive ? '+' : '-'}${formatNativeAmount(tx.amount)} ${tx.symbol}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                Text(
                  tx.valueUsd == null ? '' : formatPrice(tx.valueUsd!),
                  style: WalletColors.sub,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WalletInfoNotice extends StatelessWidget {
  const WalletInfoNotice({
    required this.message,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String message;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WalletColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: WalletColors.notice),
    );
  }
}
