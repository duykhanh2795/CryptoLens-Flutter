import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/converter/presentation/widgets/converter_theme_helpers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class ConverterCoinPickerSheet extends StatefulWidget {
  const ConverterCoinPickerSheet({
    required this.title,
    required this.coins,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String title;
  final List<Coin> coins;
  final Coin? selected;
  final ValueChanged<Coin> onSelected;

  @override
  State<ConverterCoinPickerSheet> createState() =>
      _ConverterCoinPickerSheetState();
}

class _ConverterCoinPickerSheetState extends State<ConverterCoinPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final coins = widget.coins.where((coin) {
      return query.isEmpty ||
          coin.symbol.toLowerCase().contains(query) ||
          coin.name.toLowerCase().contains(query);
    }).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: ConverterColors.title),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search coin or symbol',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 420,
              child: ListView.separated(
                itemCount: coins.length,
                separatorBuilder: (_, _) => const Divider(
                  color: ConverterColors.surfaceVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final coin = coins[index];
                  final selected = coin.id == widget.selected?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ConverterCoinIcon(coin: coin, size: 36),
                    title: Text(coin.symbol),
                    subtitle: Text(coin.name),
                    trailing: selected
                        ? const Text(
                            'Selected',
                            style: TextStyle(color: ConverterColors.yellow),
                          )
                        : Text(
                            '#${coin.rank}',
                            style: const TextStyle(
                              color: ConverterColors.textTertiary,
                            ),
                          ),
                    onTap: () => widget.onSelected(coin),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConverterCoinIcon extends StatelessWidget {
  const ConverterCoinIcon({required this.coin, required this.size, super.key});

  final Coin? coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (coin == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: ConverterColors.yellow,
        child: const Text(r'$', style: TextStyle(color: Colors.black)),
      );
    }
    return ClipOval(
      child: Image.network(
        coin!.imageUrl,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: ConverterColors.surfaceVariant,
          child: Text(coin!.symbol.isEmpty ? '?' : coin!.symbol[0]),
        ),
      ),
    );
  }
}
