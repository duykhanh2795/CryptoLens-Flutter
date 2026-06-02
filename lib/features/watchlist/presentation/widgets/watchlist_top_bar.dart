part of '../screens/watchlist_screen.dart';

class _WatchlistTopBar extends StatelessWidget {
  const _WatchlistTopBar({
    required this.controller,
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.onSort,
  });

  final MarketController controller;
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Text(
              'CL',
              style: TextStyle(
                color: AppColors.background,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.circle, size: 9, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                controller.isRefreshing ? 'SYNC' : 'LIVE',
                style: TextStyle(
                  color: controller.isRefreshing
                      ? AppColors.textTertiary
                      : AppColors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Search',
                onPressed: onSearchToggle,
                icon: Icon(
                  Icons.search_rounded,
                  size: 27,
                  color: isSearchVisible
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Sort',
                onPressed: onSort,
                icon: const Icon(
                  Icons.sort_rounded,
                  size: 27,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 27,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
