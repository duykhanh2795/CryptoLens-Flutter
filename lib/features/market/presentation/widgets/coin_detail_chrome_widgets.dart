part of '../screens/coin_detail_screen.dart';

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.coin,
    required this.controller,
    required this.onRefresh,
    required this.onAlert,
    required this.onWatchlistToggle,
  });

  final Coin coin;
  final MarketController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onAlert;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final watchlisted = controller.watchlistedIds.contains(coin.id);
    return Positioned(
      left: 4,
      right: 4,
      top: 0,
      child: Container(
        height: 44,
        color: _DetailColors.background,
        child: Row(
          children: [
            _TopIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _TopIconButton(icon: Icons.refresh_rounded, onTap: onRefresh),
            _TopIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: onAlert,
            ),
            _TopIconButton(
              icon: watchlisted
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: watchlisted
                  ? _DetailColors.textPrimary
                  : _DetailColors.textSecondary,
              onTap: onWatchlistToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.color = _DetailColors.textSecondary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
