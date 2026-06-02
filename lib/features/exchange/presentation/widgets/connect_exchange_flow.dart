part of '../screens/manage_exchange_screen.dart';

class _ConnectExchangeScreen extends StatefulWidget {
  const _ConnectExchangeScreen();

  @override
  State<_ConnectExchangeScreen> createState() => _ConnectExchangeScreenState();
}

class _ConnectExchangeScreenState extends State<_ConnectExchangeScreen> {
  final _store = ExchangeStore();
  final _binance = BinanceExchangeService();
  final _label = TextEditingController();
  final _apiKey = TextEditingController();
  final _secret = TextEditingController();
  ExchangeType _exchangeType = ExchangeType.binance;
  _ConnectStep _step = _ConnectStep.selectExchange;
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
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: Text(switch (_step) {
          _ConnectStep.selectExchange => 'Connect Exchange',
          _ConnectStep.enterKeys => 'Enter API Keys',
          _ConnectStep.validated => 'Confirm Connection',
        }),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StepIndicator(step: _step),
          const SizedBox(height: 18),
          switch (_step) {
            _ConnectStep.selectExchange => _selectExchangeStep(),
            _ConnectStep.enterKeys => _enterKeysStep(),
            _ConnectStep.validated => _validatedStep(),
          },
        ],
      ),
    );
  }

  Widget _selectExchangeStep() {
    return Column(
      children: [
        for (final type in ExchangeType.values)
          _ExchangeOption(
            type: type,
            onTap: () {
              if (type != ExchangeType.binance) {
                _showMessage('${type.displayName} integration coming soon');
                return;
              }
              setState(() {
                _exchangeType = type;
                _step = _ConnectStep.enterKeys;
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
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
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
            color: _Dark.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_exchangeType.displayName, style: _Dark.title),
              const SizedBox(height: 8),
              Text(_label.text.trim(), style: _Dark.sub),
              const SizedBox(height: 8),
              Text(
                validation?.accountType ?? 'Spot',
                style: const TextStyle(
                  color: _Dark.yellow,
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
          onPressed: () => setState(() => _step = _ConnectStep.enterKeys),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Future<void> _validate() async {
    if (_apiKey.text.trim().isEmpty || _secret.text.trim().isEmpty) {
      _showMessage('API Key and API Secret are required');
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
      _step = _ConnectStep.validated;
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
