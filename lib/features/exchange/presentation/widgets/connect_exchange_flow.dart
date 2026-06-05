import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/core/validation/validators.dart';
import 'package:cryptolens_flutter/features/exchange/data/exchange_store.dart';
import 'package:cryptolens_flutter/features/exchange/domain/exchange.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/widgets/exchange_common_widgets.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/widgets/exchange_step_widgets.dart';

class ConnectExchangeScreen extends StatefulWidget {
  const ConnectExchangeScreen({super.key});

  @override
  State<ConnectExchangeScreen> createState() => ConnectExchangeScreenState();
}

class ConnectExchangeScreenState extends State<ConnectExchangeScreen> {
  final _store = ExchangeStore();
  final _binance = BinanceExchangeService();
  final _label = TextEditingController();
  final _apiKey = TextEditingController();
  final _secret = TextEditingController();
  ExchangeType _exchangeType = ExchangeType.binance;
  ConnectStep _step = ConnectStep.selectExchange;
  ApiKeyValidation? _validation;
  bool _busy = false;
  bool _showSecret = false;

  @override
  void dispose() {
    _label.dispose();
    _apiKey.dispose();
    _secret.dispose();
    _binance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExchangeColors.background,
      appBar: AppBar(
        title: Text(switch (_step) {
          ConnectStep.selectExchange => 'Connect Exchange',
          ConnectStep.enterKeys => 'Enter API Keys',
          ConnectStep.validated => 'Confirm Connection',
        }),
        backgroundColor: ExchangeColors.background,
        foregroundColor: ExchangeColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          StepIndicator(step: _step),
          const SizedBox(height: 18),
          switch (_step) {
            ConnectStep.selectExchange => _selectExchangeStep(),
            ConnectStep.enterKeys => _enterKeysStep(),
            ConnectStep.validated => _validatedStep(),
          },
        ],
      ),
    );
  }

  Widget _selectExchangeStep() {
    return Column(
      children: [
        for (final type in ExchangeType.values)
          ExchangeOption(
            type: type,
            onTap: () {
              if (type != ExchangeType.binance) {
                _showMessage('${type.displayName} integration coming soon');
                return;
              }
              setState(() {
                _exchangeType = type;
                _step = ConnectStep.enterKeys;
                _label.text = '${type.displayName} main';
              });
            },
          ),
      ],
    );
  }

  Widget _enterKeysStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _label,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKey,
          decoration: const InputDecoration(labelText: 'API Key'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _secret,
          obscureText: !_showSecret,
          decoration: InputDecoration(
            labelText: 'API Secret',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showSecret = !_showSecret),
              icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _validate,
          child: _busy
              ? const AppInlineLoader(dimension: 18, strokeWidth: 2)
              : const Text('Validate And Connect'),
        ),
      ],
    );
  }

  Widget _validatedStep() {
    final validation = _validation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ExchangeColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_exchangeType.displayName, style: ExchangeColors.title),
              const SizedBox(height: 8),
              Text(_label.text.trim(), style: ExchangeColors.sub),
              const SizedBox(height: 8),
              Text(
                validation?.accountType ?? 'Spot',
                style: const TextStyle(
                  color: ExchangeColors.yellow,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                validation?.canTrade == true
                    ? 'Warning: key has trading permission'
                    : 'Read access validated',
                style: TextStyle(
                  color: validation?.canTrade == true
                      ? AppColors.red
                      : AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save Connection'),
        ),
        TextButton(
          onPressed: () => setState(() => _step = ConnectStep.enterKeys),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Future<void> _validate() async {
    final validationError = Validators.exchangeCredentials(
      apiKey: _apiKey.text,
      secret: _secret.text,
    );
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }
    setState(() => _busy = true);
    final result = await _binance.validate(
      _apiKey.text.trim(),
      _secret.text.trim(),
    );
    setState(() => _busy = false);
    if (!result.isValid) {
      _showMessage(result.errorMessage ?? 'Validation failed');
      return;
    }
    setState(() {
      _validation = result;
      _step = ConnectStep.validated;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final connection = await _store.add(
      exchangeType: _exchangeType,
      label: _label.text,
      apiKey: _apiKey.text,
      secret: _secret.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(connection);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
