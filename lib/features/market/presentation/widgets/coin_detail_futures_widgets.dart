part of '../screens/coin_detail_screen.dart';

class _FuturesMetricsPanel extends StatelessWidget {
  const _FuturesMetricsPanel({required this.future});

  final Future<FuturesMetrics>? future;

  @override
  Widget build(BuildContext context) {
    final metricsFuture = future;
    if (metricsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<FuturesMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DetailColors.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Futures metrics unavailable for this symbol.',
              style: TextStyle(
                color: _DetailColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DetailColors.panel,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Futures',
                style: TextStyle(
                  color: _DetailColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickStat(
                      label: 'Mark',
                      value: formatPrice(data.markPrice),
                      color: _DetailColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _QuickStat(
                      label: 'Funding',
                      value: '${data.fundingPercent.toStringAsFixed(4)}%',
                      color: data.fundingPercent >= 0
                          ? _DetailColors.green
                          : _DetailColors.red,
                    ),
                  ),
                  Expanded(
                    child: _QuickStat(
                      label: 'Open Interest',
                      value: formatCompactNumber(data.openInterest),
                      color: _DetailColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (data.nextFundingTime != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Next funding: ${data.nextFundingTime}',
                  style: const TextStyle(
                    color: _DetailColors.textSecondary,
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
