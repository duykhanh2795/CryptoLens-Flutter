import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/widgets/alert_common_widgets.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({
    required this.rule,
    required this.liveCoin,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final AlertRule rule;
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
        color: AlertColors.surface,
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
                backgroundColor: AlertColors.surfaceVariant,
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
                  style: AlertColors.rowTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  rule.targetLabel,
                  style: const TextStyle(
                    color: AlertColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current ${rule.metric.format(current)}',
                  style: TextStyle(
                    color: triggered
                        ? AppColors.green
                        : AlertColors.textTertiary,
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
                      ].join(' ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AlertColors.textTertiary,
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
            activeTrackColor: AlertColors.yellow,
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
