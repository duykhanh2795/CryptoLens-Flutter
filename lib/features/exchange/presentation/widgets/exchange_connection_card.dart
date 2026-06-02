part of '../screens/manage_exchange_screen.dart';

class _ExchangeConnectionCard extends StatelessWidget {
  const _ExchangeConnectionCard({
    required this.connection,
    required this.syncing,
    required this.onToggle,
    required this.onDelete,
    required this.onSync,
  });

  final ExchangeConnection connection;
  final bool syncing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final lastSync = connection.lastSyncAt == null
        ? 'Never synced'
        : 'Last sync: ${DateFormat('dd MMM yyyy, HH:mm').format(connection.lastSyncAt!)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: connection.isActive
                    ? _Dark.yellow
                    : _Dark.surfaceVariant,
                child: Text(
                  connection.exchangeType.displayName.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF1A1400),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(connection.label, style: _Dark.title),
                    Text(connection.exchangeType.displayName, style: _Dark.sub),
                  ],
                ),
              ),
              Switch(value: connection.isActive, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 12),
          Text(connection.maskedApiKey, style: _Dark.sub),
          Text(lastSync, style: _Dark.sub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: !connection.isActive || syncing ? null : onSync,
                  icon: syncing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Sync'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
