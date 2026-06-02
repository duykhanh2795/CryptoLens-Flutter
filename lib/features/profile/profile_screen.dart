import 'package:flutter/material.dart';

import '../../core/services/crypto_auth_service.dart';
import '../../core/services/portfolio_store.dart';
import '../../core/services/settings_store.dart';
import '../../core/theme/app_theme.dart';
import '../alerts/alerts_screen.dart';
import '../converter/converter_screen.dart';
import '../exchange/manage_exchange_screen.dart';
import '../market/market_controller.dart';
import '../wallet/wallet_watchlist_screen.dart';

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

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _ProfileColors.textPrimary,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Account Info',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfileColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.manage_accounts_outlined,
              color: _ProfileColors.textPrimary,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                color: _ProfileColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: const Text(
                'Standard',
                style: TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 22, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _ProfileAvatar(name: displayName),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        displayName.isEmpty ? 'CryptoLens User' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ProfileColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _AccountInfoLine(
                  label: 'CryptoLens UID',
                  value: _profileUid(email),
                  icon: Icons.content_copy_outlined,
                ),
                const SizedBox(height: 18),
                _AccountInfoLine(
                  label: 'Registration info',
                  value: email.isEmpty ? 'Not available' : email,
                  icon: Icons.visibility_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: _ProfileColors.divider),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade to Pro 1',
                            style: TextStyle(
                              color: _ProfileColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sync exchanges and wallet activity to level up',
                            style: TextStyle(
                              color: _ProfileColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.08,
                              minHeight: 7,
                              color: _ProfileColors.yellow,
                              backgroundColor: _ProfileColors.surfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showComingSoon(context, 'Benefits'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Benefits',
                            style: TextStyle(
                              color: _ProfileColors.yellow,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _ProfileColors.yellow,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final initial = cleanName.isEmpty
        ? 'C'
        : cleanName.substring(0, 1).toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: _ProfileColors.yellow,
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF111214),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _ProfileColors.surfaceVariant,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: _ProfileColors.textPrimary,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountInfoLine extends StatelessWidget {
  const _AccountInfoLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 142,
          child: Text(
            label,
            style: const TextStyle(
              color: _ProfileColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ProfileColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _ProfileColors.textTertiary, size: 19),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 18),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(icon, color: _ProfileColors.textPrimary, size: 25),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 24),
              SizedBox(
                width: 116,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _ProfileColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ] else
              const SizedBox(width: 158),
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.textTertiary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactProfileAction extends StatelessWidget {
  const _CompactProfileAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = _ProfileColors.textPrimary,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _ProfileColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  final _store = SettingsStore();
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await _store.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _ProfileColors.textPrimary,
                    size: 20,
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: _ProfileColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const _SettingsSectionHeader('General'),
            _SelectionRow(
              title: 'Currency',
              value: _settings.currency.label,
              options: AppCurrency.values.map((value) => value.label).toList(),
              onSelected: (value) => _save(
                _settings.copyWith(
                  currency: AppCurrency.values.firstWhere(
                    (item) => item.label == value,
                    orElse: () => AppCurrency.usd,
                  ),
                ),
              ),
            ),
            _SelectionRow(
              title: 'Theme',
              value: _settings.theme.label,
              options: AppThemeMode.values.map((value) => value.label).toList(),
              onSelected: (value) => _save(
                _settings.copyWith(
                  theme: AppThemeMode.values.firstWhere(
                    (item) => item.label == value,
                    orElse: () => AppThemeMode.system,
                  ),
                ),
              ),
            ),
            _SelectionRow(
              title: 'Language',
              value: _settings.language.label,
              options: AppLanguage.values.map((value) => value.label).toList(),
              onSelected: (value) => _save(
                _settings.copyWith(
                  language: AppLanguage.values.firstWhere(
                    (item) => item.label == value,
                    orElse: () => AppLanguage.english,
                  ),
                ),
              ),
            ),
            _SelectionRow(
              title: 'Price Format',
              value: _settings.priceFormat.label,
              options: PriceDisplayFormat.values
                  .map((value) => value.label)
                  .toList(),
              onSelected: (value) => _save(
                _settings.copyWith(
                  priceFormat: PriceDisplayFormat.values.firstWhere(
                    (item) => item.label == value,
                    orElse: () => PriceDisplayFormat.compact,
                  ),
                ),
              ),
            ),
            const _SettingsDivider(),
            const _SettingsSectionHeader('Privacy'),
            _SwitchRow(
              title: 'Show Portfolio Value',
              value: _settings.showPortfolioValue,
              onChanged: (value) =>
                  _save(_settings.copyWith(showPortfolioValue: value)),
            ),
            _SwitchRow(
              title: 'Biometric Lock',
              value: _settings.biometricLock,
              onChanged: (value) =>
                  _save(_settings.copyWith(biometricLock: value)),
            ),
            const _SettingsDivider(),
            const _SettingsSectionHeader('Notifications'),
            _SwitchRow(
              title: 'Push Notifications',
              value: _settings.enableNotifications,
              onChanged: (value) =>
                  _save(_settings.copyWith(enableNotifications: value)),
            ),
            const _SettingsDivider(),
            const _SettingsSectionHeader('Data'),
            const _InfoRow(title: 'Data Source', value: 'Binance - CoinGecko'),
            const _InfoRow(title: 'Price Refresh', value: 'Realtime'),
            const _SettingsDivider(),
            const _SettingsSectionHeader('About'),
            const _InfoRow(title: 'Version', value: '1.0.0'),
            const _InfoRow(title: 'Built with', value: 'Flutter - Dart'),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _ProfileColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSelection(context, title, value, options, onSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: _ProfileColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: _ProfileColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: _ProfileColors.yellow,
              inactiveThumbColor: _ProfileColors.textTertiary,
              inactiveTrackColor: _ProfileColors.surfaceVariant,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ProfileColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _ProfileColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Divider(color: _ProfileColors.divider, height: 1),
    );
  }
}

class _ProfileColors {
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceVariant = AppColors.surfaceVariant;
  static const divider = AppColors.divider;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textTertiary = AppColors.textTertiary;
  static const yellow = Color(0xFFF0B90B);
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is being ported from Kotlin.')),
  );
}

void _showChangePassword(BuildContext context) {
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  var visible = false;
  var saving = false;
  String? error;
  showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: _ProfileColors.surface,
        title: const Text(
          'Change Password',
          style: TextStyle(color: _ProfileColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassword,
              obscureText: !visible,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPassword,
              obscureText: !visible,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: visible,
              onChanged: (value) =>
                  setDialogState(() => visible = value ?? false),
              title: const Text(
                'Show password',
                style: TextStyle(color: _ProfileColors.textSecondary),
              ),
            ),
            if (error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _ProfileColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setDialogState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await CryptoAuthService().updatePassword(
                        newPassword: newPassword.text,
                        confirmPassword: confirmPassword.text,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated')),
                      );
                    } on CryptoAuthException catch (authError) {
                      setDialogState(() {
                        error = authError.message;
                        saving = false;
                      });
                    } catch (exception) {
                      setDialogState(() {
                        error = exception.toString();
                        saving = false;
                      });
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileColors.yellow,
            ),
            child: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF1A1400)),
                  ),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    newPassword.dispose();
    confirmPassword.dispose();
  });
}

void _showClearPortfolio(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _ProfileColors.surface,
      icon: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
      title: const Text(
        'Clear Portfolio?',
        style: TextStyle(color: _ProfileColors.textPrimary),
      ),
      content: const Text(
        'This removes all local portfolio transactions. Exchange connections stay linked and can be synced again.',
        style: TextStyle(color: _ProfileColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _ProfileColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () async {
            await PortfolioStore().clear();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Portfolio cleared')));
          },
          child: const Text('Clear', style: TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}

void _showLogout(BuildContext context, VoidCallback onLogout) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _ProfileColors.surface,
      icon: const Icon(Icons.logout_rounded, color: AppColors.red),
      title: const Text(
        'Log Out?',
        style: TextStyle(color: _ProfileColors.textPrimary),
      ),
      content: const Text(
        'Your portfolio data will remain saved locally on this device.',
        style: TextStyle(color: _ProfileColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _ProfileColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onLogout();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
}

String _profileUid(String email) {
  final hash = email.codeUnits.fold<int>(
    0,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );
  return hash.toString().padLeft(9, '0').substring(0, 9);
}

void _showSelection(
  BuildContext context,
  String title,
  String selected,
  List<String> options,
  ValueChanged<String> onSelected,
) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: _ProfileColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Divider(color: _ProfileColors.divider, height: 1),
          for (final option in options)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onSelected(option);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: option == selected
                              ? _ProfileColors.yellow
                              : _ProfileColors.textPrimary,
                          fontWeight: option == selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (option == selected)
                      const Icon(
                        Icons.check_rounded,
                        color: _ProfileColors.yellow,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _ProfileColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
