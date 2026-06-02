part of '../screens/alerts_screen.dart';

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.rule,
    required this.liveCoin,
    required this.onToggle,
    required this.onDelete,
  });

  final _AlertRule rule;
  final Coin liveCoin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final current = rule.metric.valueOf(liveCoin);
    final triggered = rule.isTriggered(current);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              liveCoin.imageUrl,
              width: 38,
              height: 38,
              errorBuilder: (_, _, _) => const CircleAvatar(
                backgroundColor: _Dark.surfaceVariant,
                child: Icon(Icons.currency_bitcoin),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rule.coin.symbol} ${rule.metric.label}',
                  style: _Dark.rowTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  rule.targetLabel,
                  style: const TextStyle(
                    color: _Dark.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current ${rule.metric.format(current)}',
                  style: TextStyle(
                    color: triggered ? AppColors.green : _Dark.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (rule.status != AlertStatus.active || rule.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      [
                        if (rule.status != AlertStatus.active)
                          rule.status.label,
                        rule.frequency.label,
                        if (rule.note.isNotEmpty) rule.note,
                      ].join(' â€¢ '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Dark.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: rule.enabled,
            onChanged: onToggle,
            activeTrackColor: _Dark.yellow,
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
