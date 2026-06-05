import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:cryptolens_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/markets_screen.dart';
import 'package:cryptolens_flutter/features/news/presentation/screens/news_screen.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/screens/portfolio_screen.dart';
import 'package:cryptolens_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/screens/trending_wallets_screen.dart';
import 'package:cryptolens_flutter/features/watchlist/presentation/screens/watchlist_screen.dart';

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
        onOpenPortfolio: () => setState(() => _index = 3),
        onOpenNews: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
        onOpenWallets: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TrendingWalletsScreen(controller: widget.controller),
          ),
        ),
        onOpenAi: () => _openAiAssistant(context),
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
            FloatingAiButton(onTap: () => _openAiAssistant(context)),
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

  void _openAiAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(controller: widget.controller),
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
