part of '../screens/manage_exchange_screen.dart';

enum _ConnectStep { selectExchange, enterKeys, validated }

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _ConnectStep step;

  @override
  Widget build(BuildContext context) {
    final index = _ConnectStep.values.indexOf(step);
    const labels = ['Exchange', 'API Keys', 'Confirm'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= index ? _Dark.yellow : _Dark.surface,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= index
                          ? const Color(0xFF1A1400)
                          : _Dark.textSecondary,
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
            const Expanded(child: Divider(color: _Dark.surfaceVariant)),
        ],
      ],
    );
  }
}

class _ExchangeOption extends StatelessWidget {
  const _ExchangeOption({required this.type, required this.onTap});

  final ExchangeType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _Dark.surface,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _Dark.yellow,
          child: Text(
            type.displayName.substring(0, 1),
            style: const TextStyle(color: Color(0xFF1A1400)),
          ),
        ),
        title: Text(type.displayName, style: _Dark.title),
        subtitle: Text(
          type == ExchangeType.binance
              ? 'Read-only trade import'
              : 'Coming soon',
          style: _Dark.sub,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
