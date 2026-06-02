import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/profile/data/settings_store.dart';
import 'package:cryptolens_flutter/features/profile/domain/settings.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_colors.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      backgroundColor: ProfileColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: ProfileColors.textPrimary,
                    size: 20,
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: ProfileColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SettingsSectionHeader('General'),
            SelectionRow(
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
            SelectionRow(
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
            SelectionRow(
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
            SelectionRow(
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
            const SettingsDivider(),
            const SettingsSectionHeader('Privacy'),
            SwitchRow(
              title: 'Show Portfolio Value',
              value: _settings.showPortfolioValue,
              onChanged: (value) =>
                  _save(_settings.copyWith(showPortfolioValue: value)),
            ),
            SwitchRow(
              title: 'Biometric Lock',
              value: _settings.biometricLock,
              onChanged: (value) =>
                  _save(_settings.copyWith(biometricLock: value)),
            ),
            const SettingsDivider(),
            const SettingsSectionHeader('Notifications'),
            SwitchRow(
              title: 'Push Notifications',
              value: _settings.enableNotifications,
              onChanged: (value) =>
                  _save(_settings.copyWith(enableNotifications: value)),
            ),
            const SettingsDivider(),
            const SettingsSectionHeader('Data'),
            const InfoRow(title: 'Data Source', value: 'Binance - CoinGecko'),
            const InfoRow(title: 'Price Refresh', value: 'Realtime'),
            const SettingsDivider(),
            const SettingsSectionHeader('About'),
            const InfoRow(title: 'Version', value: '1.0.0'),
            const InfoRow(title: 'Built with', value: 'Flutter - Dart'),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: ProfileColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SelectionRow extends StatelessWidget {
  const SelectionRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          showProfileSelection(context, title, value, options, onSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ProfileColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: ProfileColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: ProfileColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
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
                  color: ProfileColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: ProfileColors.yellow,
              inactiveThumbColor: ProfileColors.textTertiary,
              inactiveTrackColor: ProfileColors.surfaceVariant,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({required this.title, required this.value, super.key});

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
                color: ProfileColors.textPrimary,
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
                color: ProfileColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Divider(color: ProfileColors.divider, height: 1),
    );
  }
}
