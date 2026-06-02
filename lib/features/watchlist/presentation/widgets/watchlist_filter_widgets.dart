import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/watchlist/presentation/widgets/watchlist_models.dart';

class WatchlistTabsAndFilters extends StatelessWidget {
  const WatchlistTabsAndFilters({
    required this.controller,
    required this.showSearch,
    required this.filter,
    required this.sortOrder,
    required this.onFilterChanged,
    required this.onSortChanged,
    super.key,
  });

  final MarketController controller;
  final bool showSearch;
  final WatchlistFilter filter;
  final WatchlistSortOrder sortOrder;
  final ValueChanged<WatchlistFilter> onFilterChanged;
  final ValueChanged<WatchlistSortOrder> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      WatchlistChipData(
        label: 'Popular',
        selected:
            filter == WatchlistFilter.all &&
            sortOrder == WatchlistSortOrder.defaultOrder,
        onTap: () {
          onFilterChanged(WatchlistFilter.all);
          onSortChanged(WatchlistSortOrder.defaultOrder);
        },
      ),
      WatchlistChipData(
        label: 'Gainers',
        selected: filter == WatchlistFilter.gainers,
        onTap: () => onFilterChanged(WatchlistFilter.gainers),
      ),
      WatchlistChipData(
        label: 'Losers',
        selected: filter == WatchlistFilter.losers,
        onTap: () => onFilterChanged(WatchlistFilter.losers),
      ),
      WatchlistChipData(
        label: 'Price',
        selected:
            sortOrder == WatchlistSortOrder.priceDesc ||
            sortOrder == WatchlistSortOrder.priceAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == WatchlistSortOrder.priceDesc
              ? WatchlistSortOrder.priceAsc
              : WatchlistSortOrder.priceDesc,
        ),
      ),
      WatchlistChipData(
        label: '24h Change',
        selected:
            sortOrder == WatchlistSortOrder.changeDesc ||
            sortOrder == WatchlistSortOrder.changeAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == WatchlistSortOrder.changeDesc
              ? WatchlistSortOrder.changeAsc
              : WatchlistSortOrder.changeDesc,
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
                              sortOrder == WatchlistSortOrder.priceAsc ||
                                      sortOrder == WatchlistSortOrder.changeAsc
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
