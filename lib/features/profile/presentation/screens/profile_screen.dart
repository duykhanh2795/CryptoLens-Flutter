import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:cryptolens_flutter/features/converter/presentation/screens/converter_screen.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/screens/manage_exchange_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_account_widgets.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_colors.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_settings_widgets.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/screens/wallet_watchlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const ProfileTopBar(),
          AccountInfoCard(displayName: displayName, email: email),
          const SizedBox(height: 22),
          ProfileRow(
            icon: Icons.person_outline_rounded,
            title: 'Verification',
            trailingText: 'Not verified',
            onTap: () => showComingSoon(context, 'Identity verification'),
          ),
          ProfileRow(
            icon: Icons.security_rounded,
            title: 'Security',
            onTap: () => showChangePassword(context),
          ),
          ProfileRow(
            icon: Icons.account_balance_rounded,
            title: 'Connected Exchanges',
            trailingText: 'Binance',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManageExchangeScreen(controller: controller),
              ),
            ),
          ),
          ProfileRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet Watchlist',
            trailingText: 'On-chain',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WalletWatchlistScreen(controller: controller),
              ),
            ),
          ),
          ProfileRow(
            icon: Icons.notifications_none_rounded,
            title: 'Alerts',
            trailingText: 'Price rules',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlertsScreen(controller: controller),
              ),
            ),
          ),
          ProfileRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Converter',
            trailingText: 'Live rates',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConverterScreen(controller: controller),
              ),
            ),
          ),
          ProfileRow(
            icon: Icons.settings_outlined,
            title: 'Settings',
            trailingText: 'Theme, currency',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          ProfileRow(
            icon: Icons.close_rounded,
            title: 'Twitter',
            trailingText: 'Unlinked',
            onTap: () => showComingSoon(context, 'Twitter link'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CompactProfileAction(
                  label: 'Export',
                  icon: Icons.file_download_outlined,
                  onTap: () => showComingSoon(context, 'Export data'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CompactProfileAction(
                  label: 'Clear Portfolio',
                  icon: Icons.delete_forever_outlined,
                  color: AppColors.red,
                  onTap: () => showClearPortfolio(context),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ProfileColors.surfaceVariant,
                foregroundColor: ProfileColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => showLogout(context, onLogout),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'CryptoLens v1.0.0',
              style: TextStyle(
                color: ProfileColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // const SizedBox(height: 88),
        ],
      ),
    );
  }
}
