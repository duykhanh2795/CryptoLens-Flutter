part of '../screens/watchlist_screen.dart';

class _WatchlistTabsAndFilters extends StatelessWidget {
  const _WatchlistTabsAndFilters({
    required this.controller,
    required this.showSearch,
    required this.filter,
    required this.sortOrder,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final MarketController controller;
  final bool showSearch;
  final _WatchlistFilter filter;
  final _WatchlistSortOrder sortOrder;
  final ValueChanged<_WatchlistFilter> onFilterChanged;
  final ValueChanged<_WatchlistSortOrder> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _WatchlistChipData(
        label: 'Popular',
        selected:
            filter == _WatchlistFilter.all &&
            sortOrder == _WatchlistSortOrder.defaultOrder,
        onTap: () {
          onFilterChanged(_WatchlistFilter.all);
          onSortChanged(_WatchlistSortOrder.defaultOrder);
        },
      ),
      _WatchlistChipData(
        label: 'Gainers',
        selected: filter == _WatchlistFilter.gainers,
        onTap: () => onFilterChanged(_WatchlistFilter.gainers),
      ),
      _WatchlistChipData(
        label: 'Losers',
        selected: filter == _WatchlistFilter.losers,
        onTap: () => onFilterChanged(_WatchlistFilter.losers),
      ),
      _WatchlistChipData(
        label: 'Price',
        selected:
            sortOrder == _WatchlistSortOrder.priceDesc ||
            sortOrder == _WatchlistSortOrder.priceAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == _WatchlistSortOrder.priceDesc
              ? _WatchlistSortOrder.priceAsc
              : _WatchlistSortOrder.priceDesc,
        ),
      ),
      _WatchlistChipData(
        label: '24h Change',
        selected:
            sortOrder == _WatchlistSortOrder.changeDesc ||
            sortOrder == _WatchlistSortOrder.changeAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == _WatchlistSortOrder.changeDesc
              ? _WatchlistSortOrder.changeAsc
              : _WatchlistSortOrder.changeDesc,
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Watchlist',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 22),
              Text(
                'Coins',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 14),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: controller.setSearchQuery,
                      cursorColor: AppColors.accent,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Search symbol or name',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (controller.searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: () => controller.setSearchQuery(''),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: chip.onTap,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: chip.selected
                          ? AppColors.surfaceVariant
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: chip.selected ? 10 : 0,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            chip.label,
                            style: TextStyle(
                              color: chip.selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (chip.sortIcon) ...[
                            const SizedBox(width: 2),
                            Icon(
                              sortOrder == _WatchlistSortOrder.priceAsc ||
                                      sortOrder == _WatchlistSortOrder.changeAsc
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
