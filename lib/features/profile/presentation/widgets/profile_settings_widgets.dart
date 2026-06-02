part of '../screens/profile_screen.dart';

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
