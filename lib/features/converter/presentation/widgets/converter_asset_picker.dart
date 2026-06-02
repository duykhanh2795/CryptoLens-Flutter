import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/converter/presentation/widgets/converter_coin_picker_sheet.dart';
import 'package:cryptolens_flutter/features/converter/presentation/widgets/converter_theme_helpers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class ConverterAssetPicker extends StatelessWidget {
  const ConverterAssetPicker({
    required this.title,
    required this.isUsd,
    required this.coin,
    required this.onUsdChanged,
    required this.onCoinTap,
    super.key,
  });

  final String title;
  final bool isUsd;
  final Coin? coin;
  final ValueChanged<bool> onUsdChanged;
  final VoidCallback onCoinTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConverterColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ConverterColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('USD')),
              ButtonSegment(value: false, label: Text('Crypto')),
            ],
            selected: {isUsd},
            onSelectionChanged: (value) => onUsdChanged(value.first),
          ),
          if (!isUsd) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onCoinTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ConverterColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ConverterCoinIcon(coin: coin, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        coin == null
                            ? 'Select coin'
                            : '${coin!.symbol} - ${coin!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ConverterColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ConverterColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
