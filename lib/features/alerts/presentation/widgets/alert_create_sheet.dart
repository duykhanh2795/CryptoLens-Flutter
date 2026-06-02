part of '../screens/alerts_screen.dart';

class _CreateAlertSheet extends StatefulWidget {
  const _CreateAlertSheet({
    required this.coins,
    required this.onCreate,
    this.initialCoin,
    this.initialMetric,
  });

  final List<Coin> coins;
  final ValueChanged<_AlertRule> onCreate;
  final Coin? initialCoin;
  final AlertMetric? initialMetric;

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  late Coin _coin = widget.initialCoin ?? widget.coins.first;
  late AlertMetric _metric = widget.initialMetric ?? AlertMetric.price;
  AlertDirection _direction = AlertDirection.above;
  AlertValueType _valueType = AlertValueType.number;
  AlertFrequency _frequency = AlertFrequency.oneTime;
  final _target = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultTarget();
  }

  @override
  void dispose() {
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = double.tryParse(_target.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Alert', style: _Dark.title),
            const SizedBox(height: 16),
            DropdownButtonFormField<Coin>(
              initialValue: _coin,
              isExpanded: true,
              dropdownColor: _Dark.surface,
              decoration: const InputDecoration(labelText: 'Coin'),
              items: [
                for (final coin in widget.coins)
                  DropdownMenuItem(
                    value: coin,
                    child: Text(
                      '${coin.symbol} - ${coin.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (coin) {
                if (coin == null) return;
                setState(() {
                  _coin = coin;
                  _setDefaultTarget();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AlertMetric>(
              initialValue: _metric,
              isExpanded: true,
              dropdownColor: _Dark.surface,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: AlertMetric.values
                  .map(
                    (metric) => DropdownMenuItem(
                      value: metric,
                      child: Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (metric) {
                if (metric == null) return;
                setState(() {
                  _metric = metric;
                  _setDefaultTarget();
                });
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertValueType>(
              segments: const [
                ButtonSegment(
                  value: AlertValueType.number,
                  label: Text('Number'),
                ),
                ButtonSegment(
                  value: AlertValueType.percent,
                  label: Text('Percent'),
                ),
              ],
              selected: {_valueType},
              onSelectionChanged: (value) => setState(() {
                _valueType = value.first;
                _setDefaultTarget();
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertDirection>(
              segments: const [
                ButtonSegment(
                  value: AlertDirection.above,
                  label: Text('Above'),
                ),
                ButtonSegment(
                  value: AlertDirection.below,
                  label: Text('Below'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (value) =>
                  setState(() => _direction = value.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertFrequency>(
              segments: const [
                ButtonSegment(
                  value: AlertFrequency.oneTime,
                  label: Text('One Time'),
                ),
                ButtonSegment(
                  value: AlertFrequency.persistent,
                  label: Text('Persistent'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (value) =>
                  setState(() => _frequency = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _valueType == AlertValueType.percent
                    ? 'Target move (%)'
                    : 'Target ${_metric.unitLabel}',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Breakout alert',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _previewText(target),
              style: const TextStyle(
                color: _Dark.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: target <= 0
                    ? null
                    : () {
                        widget.onCreate(
                          _AlertRule(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            coin: _coin,
                            metric: _metric,
                            direction: _direction,
                            target: target,
                            baselineValue: _currentMetricValue(),
                            valueType: _valueType,
                            frequency: _frequency,
                            status: AlertStatus.active,
                            note: _note.text.trim(),
                            enabled: true,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                child: const Text('Create Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _currentMetricValue() => switch (_metric) {
    AlertMetric.price => _coin.currentPrice,
    AlertMetric.volume => _coin.volume24h,
    AlertMetric.marketCap => _coin.marketCap,
  };

  void _setDefaultTarget() {
    if (_valueType == AlertValueType.percent) {
      _target.text = '1';
      return;
    }
    final value = _currentMetricValue();
    _target.text = value > 0 ? value.toStringAsFixed(2) : '';
  }

  String _previewText(double target) {
    final baseline = _currentMetricValue();
    if (_valueType == AlertValueType.percent) {
      final threshold = _direction == AlertDirection.above
          ? baseline * (1 + target / 100)
          : baseline * (1 - target / 100);
      return 'Baseline ${_metric.format(baseline)} -> trigger at ${_metric.format(threshold)}';
    }
    return 'Current ${_metric.format(baseline)}';
  }
}
