import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/auth/data/crypto_auth_service.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/profile/data/settings_store.dart';
import 'package:cryptolens_flutter/features/profile/domain/settings.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:cryptolens_flutter/features/converter/presentation/screens/converter_screen.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/screens/manage_exchange_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/screens/wallet_watchlist_screen.dart';

part '../widgets/profile_colors.dart';
part '../widgets/profile_account_widgets.dart';
part '../widgets/profile_settings_widgets.dart';
part '../widgets/profile_dialogs.dart';

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
      backgroundColor: _ProfileColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const _ProfileTopBar(),
          _AccountInfoCard(displayName: displayName, email: email),
          const SizedBox(height: 22),
          _ProfileRow(
            icon: Icons.person_outline_rounded,
            title: 'Verification',
            trailingText: 'Not verified',
            onTap: () => _showComingSoon(context, 'Identity verification'),
          ),
          _ProfileRow(
            icon: Icons.security_rounded,
            title: 'Security',
            onTap: () => _showChangePassword(context),
          ),
          _ProfileRow(
            icon: Icons.account_balance_rounded,
            title: 'Connected Exchanges',
            trailingText: 'Binance',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManageExchangeScreen(controller: controller),
              ),
            ),
          ),
          _ProfileRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet Watchlist',
            trailingText: 'On-chain',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WalletWatchlistScreen(controller: controller),
              ),
            ),
          ),
          _ProfileRow(
            icon: Icons.notifications_none_rounded,
            title: 'Alerts',
            trailingText: 'Price rules',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlertsScreen(controller: controller),
              ),
            ),
          ),
          _ProfileRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Converter',
            trailingText: 'Live rates',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConverterScreen(controller: controller),
              ),
            ),
          ),
          _ProfileRow(
            icon: Icons.settings_outlined,
            title: 'Settings',
            trailingText: 'Theme, currency',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const _SettingsScreen())),
          ),
          _ProfileRow(
            icon: Icons.close_rounded,
            title: 'Twitter',
            trailingText: 'Unlinked',
            onTap: () => _showComingSoon(context, 'Twitter link'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CompactProfileAction(
                  label: 'Export',
                  icon: Icons.file_download_outlined,
                  onTap: () => _showComingSoon(context, 'Export data'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactProfileAction(
                  label: 'Clear Portfolio',
                  icon: Icons.delete_forever_outlined,
                  color: AppColors.red,
                  onTap: () => _showClearPortfolio(context),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileColors.surfaceVariant,
                foregroundColor: _ProfileColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showLogout(context, onLogout),
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
                color: _ProfileColors.textTertiary,
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
