import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';

class MarketInfoSection extends StatelessWidget {
  const MarketInfoSection({
    required this.coin,
    required this.detail,
    super.key,
  });

  final Coin coin;
  final CoinDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <_MarketInfoRowData>[
      _MarketInfoRowData(
        'Market Cap Rank',
        coin.rank > 0 ? 'NO.${coin.rank}' : 'N/A',
      ),
      _MarketInfoRowData(
        'Market Cap',
        formatCompactUsd(coin.marketCap),
        subValue: 'â‰ˆ${formatCompactUsd(coin.marketCap)}',
      ),
      _MarketInfoRowData('24h Volume', formatCompactUsd(coin.volume24h)),
      _MarketInfoRowData('24h High', formatPrice(coin.high24h)),
      _MarketInfoRowData('24h Low', formatPrice(coin.low24h)),
      _MarketInfoRowData(
        'All Time High',
        formatPrice(detail.allTimeHigh),
        subValue: [
          'â‰ˆ${formatPrice(detail.allTimeHigh)}',
          if (_dateOnly(detail.allTimeHighDate).isNotEmpty)
            _dateOnly(detail.allTimeHighDate),
        ].join('\n'),
      ),
      _MarketInfoRowData(
        'All Time Low',
        formatPrice(detail.allTimeLow),
        subValue: [
          'â‰ˆ${formatPrice(detail.allTimeLow)}',
          if (_dateOnly(detail.allTimeLowDate).isNotEmpty)
            _dateOnly(detail.allTimeLowDate),
        ].join('\n'),
      ),
      _MarketInfoRowData(
        'Circulating Supply',
        '${formatCompactNumber(coin.circulatingSupply)} ${coin.symbol}',
      ),
      _MarketInfoRowData(
        'Total Supply',
        '${formatCompactNumber(detail.totalSupply)} ${coin.symbol}',
      ),
      if (detail.maxSupply > 0)
        _MarketInfoRowData(
          'Max Supply',
          '${formatCompactNumber(detail.maxSupply)} ${coin.symbol}',
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${coin.symbol}',
            style: const TextStyle(
              color: CoinDetailColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < rows.length; i++) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: _InfoRow(row: rows[i]),
            ),
            if (i != rows.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

class _MarketInfoRowData {
  const _MarketInfoRowData(this.label, this.value, {this.subValue});

  final String label;
  final String value;
  final String? subValue;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});

  final _MarketInfoRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CoinDetailColors.textTertiary,
              fontSize: 14,
              height: 1.18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 154,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: CoinDetailColors.textPrimary,
                  fontSize: 14,
                  height: 1.18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (row.subValue != null && row.subValue!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  row.subValue!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: CoinDetailColors.textTertiary,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _dateOnly(String raw) {
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}
