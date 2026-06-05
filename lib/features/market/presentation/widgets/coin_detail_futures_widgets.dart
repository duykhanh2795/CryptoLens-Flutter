import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/market/data/market_api.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_stats_widgets.dart';

class FuturesMetricsPanel extends StatelessWidget {
  const FuturesMetricsPanel({required this.future, super.key});

  final Future<FuturesMetrics>? future;

  @override
  Widget build(BuildContext context) {
    final metricsFuture = future;
    if (metricsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<FuturesMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingState(
            height: 72,
            strokeWidth: 2,
            color: CoinDetailColors.textSecondary,
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            decoration: BoxDecoration(
              color: CoinDetailColors.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppAsyncMessage(
              message: 'Futures metrics unavailable for this symbol.',
              alignment: Alignment.centerLeft,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: CoinDetailColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CoinDetailColors.panel,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Futures',
                style: TextStyle(
                  color: CoinDetailColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickStat(
                      label: 'Mark',
                      value: formatPrice(data.markPrice),
                      color: CoinDetailColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: QuickStat(
                      label: 'Funding',
                      value: '${data.fundingPercent.toStringAsFixed(4)}%',
                      color: data.fundingPercent >= 0
                          ? CoinDetailColors.green
                          : CoinDetailColors.red,
                    ),
                  ),
                  Expanded(
                    child: QuickStat(
                      label: 'Open Interest',
                      value: formatCompactNumber(data.openInterest),
                      color: CoinDetailColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (data.nextFundingTime != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Next funding: ${data.nextFundingTime}',
                  style: const TextStyle(
                    color: CoinDetailColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
