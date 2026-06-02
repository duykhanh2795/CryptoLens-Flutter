import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/exchange/domain/exchange.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/widgets/exchange_common_widgets.dart';

enum ConnectStep { selectExchange, enterKeys, validated }

class StepIndicator extends StatelessWidget {
  const StepIndicator({required this.step, super.key});

  final ConnectStep step;

  @override
  Widget build(BuildContext context) {
    final index = ConnectStep.values.indexOf(step);
    const labels = ['Exchange', 'API Keys', 'Confirm'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= index
                      ? ExchangeColors.yellow
                      : ExchangeColors.surface,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= index
                          ? const Color(0xFF1A1400)
                          : ExchangeColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(labels[i], style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          if (i < labels.length - 1)
            const Expanded(
              child: Divider(color: ExchangeColors.surfaceVariant),
            ),
        ],
      ],
    );
  }
}

class ExchangeOption extends StatelessWidget {
  const ExchangeOption({required this.type, required this.onTap, super.key});

  final ExchangeType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ExchangeColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: ExchangeColors.yellow,
          child: Text(
            type.displayName.substring(0, 1),
            style: const TextStyle(color: Color(0xFF1A1400)),
          ),
        ),
        title: Text(type.displayName, style: ExchangeColors.title),
        subtitle: Text(
          type == ExchangeType.binance
              ? 'Read-only trade import'
              : 'Coming soon',
          style: ExchangeColors.sub,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
