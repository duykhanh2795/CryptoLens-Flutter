part of '../screens/converter_screen.dart';

class _AssetPicker extends StatelessWidget {
  const _AssetPicker({
    required this.title,
    required this.isUsd,
    required this.coin,
    required this.onUsdChanged,
    required this.onCoinTap,
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
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _Dark.textSecondary,
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
                  color: _Dark.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _CoinIcon(coin: coin, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        coin == null
                            ? 'Select coin'
                            : '${coin!.symbol} - ${coin!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Dark.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _Dark.textSecondary,
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
