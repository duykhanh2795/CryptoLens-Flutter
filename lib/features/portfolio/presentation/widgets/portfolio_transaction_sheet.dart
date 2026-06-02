import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_format_helpers.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    required this.coins,
    required this.availableQuantityByCoin,
    required this.onConfirm,
    super.key,
  });

  final List<Coin> coins;
  final Map<String, double> availableQuantityByCoin;
  final ValueChanged<PortfolioTransaction> onConfirm;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late Coin _coin = widget.coins.first;
  PortfolioTransactionType _type = PortfolioTransactionType.buy;
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _fee = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _price.text = _coin.currentPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _fee.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    final fee = double.tryParse(_fee.text) ?? 0;
    final total = quantity * price + fee;
    final availableQuantity = widget.availableQuantityByCoin[_coin.id] ?? 0;
    final sellTooMuch =
        _type == PortfolioTransactionType.sell && quantity > availableQuantity;
    final canSubmit =
        quantity > 0 &&
        price >= 0 &&
        (_type == PortfolioTransactionType.buy || !sellTooMuch);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Transaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TypeButton(
                  label: 'BUY',
                  selected: _type == PortfolioTransactionType.buy,
                  color: AppColors.green,
                  onTap: () =>
                      setState(() => _type = PortfolioTransactionType.buy),
                ),
                const SizedBox(width: 8),
                TypeButton(
                  label: 'SELL',
                  selected: _type == PortfolioTransactionType.sell,
                  color: AppColors.red,
                  onTap: () =>
                      setState(() => _type = PortfolioTransactionType.sell),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<Coin>(
              initialValue: _coin,
              decoration: const InputDecoration(labelText: 'Coin'),
              items: [
                for (final coin in widget.coins)
                  DropdownMenuItem(
                    value: coin,
                    child: Text('${coin.symbol} - ${coin.name}'),
                  ),
              ],
              onChanged: (coin) {
                if (coin == null) return;
                setState(() {
                  _coin = coin;
                  _price.text = coin.currentPrice.toStringAsFixed(2);
                });
              },
            ),
            const SizedBox(height: 12),
            SheetField(
              controller: _quantity,
              label: 'Quantity',
              hint: 'e.g. 0.5',
              onChanged: (_) => setState(() {}),
            ),
            if (_type == PortfolioTransactionType.sell) ...[
              const SizedBox(height: 6),
              Text(
                'Available: ${trimPortfolioValue(availableQuantity)} ${_coin.symbol}',
                style: TextStyle(
                  color: sellTooMuch ? AppColors.red : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SheetField(
              controller: _price,
              label: 'Price per coin (USD)',
              hint: 'e.g. 65000',
              prefix: r'$',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SheetField(
              controller: _fee,
              label: 'Fee (optional)',
              hint: 'e.g. 1.5',
              prefix: r'$',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. DCA strategy',
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(total),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _type == PortfolioTransactionType.buy
                      ? AppColors.green
                      : AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: !canSubmit
                    ? null
                    : () {
                        widget.onConfirm(
                          PortfolioTransaction(
                            id: newPortfolioId(),
                            coin: _coin,
                            type: _type,
                            quantity: quantity,
                            price: price,
                            fee: fee,
                            timestamp: DateTime.now(),
                            note: _note.text.trim(),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                child: Text(
                  'Confirm ${_type.label.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeButton extends StatelessWidget {
  const TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class SheetField extends StatelessWidget {
  const SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.prefix,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
      ),
    );
  }
}
