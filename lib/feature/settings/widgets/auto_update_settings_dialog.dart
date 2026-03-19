import 'package:cardabase/feature/settings/editable_model.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';

class AutoUpdateSettingsDialog extends StatefulWidget {
  const AutoUpdateSettingsDialog({
    super.key,
    required this.initialValue,
  });

  final AutoBackupSettings initialValue;

  @override
  State<AutoUpdateSettingsDialog> createState() =>
      _AutoUpdateSettingsDialogState();
}

class _AutoUpdateSettingsDialogState extends State<AutoUpdateSettingsDialog> {
  late final EditableAutoBackupSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = EditableAutoBackupSettings.fromValue(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AutoUpdateSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _settings.loadValue(widget.initialValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Auto Backups',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: ValueListenableBuilder(
        valueListenable: _settings.isEnabled,
        builder: (context, isEnabled, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _enableSwitch(theme),
            const SizedBox(height: 10),
            _intervalSlider(theme),
          ],
        ),
      ),
      actions: [
        Center(
          child: _doneButton(context, theme),
        ),
      ],
    );
  }

  Widget _enableSwitch(ThemeData theme) {
    return SwitchListTile(
      title: Text(
        'Enable Auto Backups',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      value: _settings.isEnabled.value,
      onChanged: (value) => _settings.isEnabled.value = value,
    );
  }

  Widget _intervalSlider(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.interval,
      builder: (context, interval, _) => Slider(
        year2023: false,
        value: interval.inDays.toDouble(),
        min: 1,
        max: 365,
        divisions: 364,
        label: '${interval.inDays} days',
        onChanged: (value) {
          _settings.interval.value = Duration(days: value.round());
        },
      ),
    );
  }

  Widget _doneButton(BuildContext context, ThemeData theme) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      onPressed: () => Navigator.of(context).pop(_settings.seal()),
      child: Text(
        'DONE',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: theme.colorScheme.inverseSurface,
        ),
      ),
    );
  }
}
