import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../market/market_controller.dart';
import '../market/markets_screen.dart';
import '../news/news_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../profile/profile_screen.dart';
import '../watchlist/watchlist_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.controller,
    required this.displayName,
    required this.email,
    required this.onLogout,
    super.key,
  });

  final MarketController controller;
  final String displayName;
  final String email;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = switch (Uri.base.queryParameters['tab']) {
      'markets' => 1,
      'watchlist' => 2,
      'portfolio' => 3,
      'profile' => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        controller: widget.controller,
        onOpenMarkets: () => setState(() => _index = 1),
        onOpenNews: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
      ),
      MarketsScreen(controller: widget.controller),
      WatchlistScreen(controller: widget.controller),
      PortfolioScreen(controller: widget.controller),
      ProfileScreen(
        controller: widget.controller,
        displayName: widget.displayName,
        email: widget.email,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: screens[_index]),
            const _AiAssistantOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
      backgroundColor: AppColors.background,
    );
  }
}

class _AiAssistantOverlay extends StatelessWidget {
  const _AiAssistantOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 92,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showAiSheet(context),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8ECEF),
                  Color(0xFF7C6FE8),
                  Color(0xFF9EA4AD),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.66),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _AiSheet(),
    );
  }
}

class _AiSheet extends StatelessWidget {
  const _AiSheet();

  @override
  Widget build(BuildContext context) {
    const prompts = [
      ('Fast', 'Legal crypto news affecting the market'),
      ('Fast', 'Why is Hyperliquid trending?'),
      ('Deep Research', 'Altcoin setups: SUI, NEAR, LINK'),
      ('Backtest', 'Top 5 crypto equal-weight vs market-cap'),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Text(
              'Gemini chat parity is next; these prompts mirror the Kotlin assistant entry.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (final prompt in prompts)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        prompt.$1,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt.$2,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
      _NavSpec('Markets', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
      _NavSpec('Watchlist', Icons.star_border_rounded, Icons.star_rounded),
      _NavSpec(
        'Portfolio',
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded,
      ),
      _NavSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _BottomNavItem(
                  spec: items[index],
                  selected: selectedIndex == index,
                  onTap: () => onChanged(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              selected ? spec.selectedIcon : spec.icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 23,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)
                .copyWith(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
