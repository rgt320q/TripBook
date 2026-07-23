import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripbook/l10n/app_localizations.dart';

class DurationSelector extends StatefulWidget {
  final int? initialDurationMinutes;
  final ValueChanged<int?> onChanged;
  final bool readOnly;

  const DurationSelector({
    super.key,
    this.initialDurationMinutes,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  final List<int> _presets = [0, 15, 30, 45, 60, 120, 180];
  String? _selectedOption;
  late TextEditingController _customController;
  String _customUnit = 'minutes'; // 'minutes' or 'hours'

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    final initial = widget.initialDurationMinutes ?? 0;
    _customController = TextEditingController();

    if (_presets.contains(initial)) {
      _selectedOption = initial.toString();
    } else {
      _selectedOption = 'custom';
      if (initial % 60 == 0 && initial != 0) {
        _customController.text = (initial ~/ 60).toString();
        _customUnit = 'hours';
      } else {
        _customController.text = initial.toString();
        _customUnit = 'minutes';
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _handleOptionChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedOption = value;
    });
    _emitChange();
  }

  void _emitChange() {
    if (_selectedOption == 'custom') {
      final val = int.tryParse(_customController.text) ?? 0;
      final total = _customUnit == 'hours' ? val * 60 : val;
      widget.onChanged(total == 0 ? null : total);
    } else {
      final val = int.parse(_selectedOption!);
      widget.onChanged(val == 0 ? null : val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedOption,
          decoration: InputDecoration(
            labelText: l10n.estimatedDurationLabel,
            border: const OutlineInputBorder(),
            enabled: !widget.readOnly,
          ),
          items: [
            ..._presets.map((minutes) {
              String label;
              if (minutes == 0) {
                label = l10n.notSet;
              } else if (minutes < 60) {
                label = '$minutes ${l10n.durationUnitMinutes.toLowerCase()}';
              } else {
                label = '${minutes ~/ 60} ${l10n.durationUnitHours.toLowerCase()}';
              }
              return DropdownMenuItem(
                value: minutes.toString(),
                child: Text(label),
              );
            }),
            DropdownMenuItem(
              value: 'custom',
              child: Text(l10n.custom),
            ),
          ],
          onChanged: widget.readOnly ? null : _handleOptionChange,
        ),
        if (_selectedOption == 'custom') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: widget.readOnly,
                  decoration: InputDecoration(
                    labelText: l10n.custom,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _emitChange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _customUnit,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'minutes',
                      child: Text(l10n.durationUnitMinutes),
                    ),
                    DropdownMenuItem(
                      value: 'hours',
                      child: Text(l10n.durationUnitHours),
                    ),
                  ],
                  onChanged: widget.readOnly ? null : (value) {
                    if (value != null) {
                      setState(() {
                        _customUnit = value;
                      });
                      _emitChange();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
