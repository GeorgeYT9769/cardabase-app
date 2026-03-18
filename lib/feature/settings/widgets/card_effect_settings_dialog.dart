import 'package:cardabase/feature/settings/editable_model.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';

class CardEffectSettingsDialog extends StatefulWidget {
  const CardEffectSettingsDialog({super.key, required this.initialValue});

  final LoyaltyCardEffectSettings initialValue;

  @override
  State<CardEffectSettingsDialog> createState() =>
      _CardEffectSettingsDialogState();
}

class _CardEffectSettingsDialogState extends State<CardEffectSettingsDialog> {
  late final EditableLoyaltyCardEffectSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialValue.editable();
  }

  @override
  void didUpdateWidget(covariant CardEffectSettingsDialog oldWidget) {
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
        'Card effects',
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
            Text(
              'Warning: may cause lags on some phones. Enable on your own risk.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.red,
                fontSize: 15,
              ),
            ),
            _enableSwitch(theme),
            if (isEnabled) _effectDropdown(theme),
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
        'Effects',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      value: _settings.isEnabled.value,
      onChanged: (value) => _settings.isEnabled.value = value,
    );
  }

  Widget _effectDropdown(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.effect,
      builder: (context, effect, _) => DropdownButton<LoyaltyCardEffect>(
        value: effect,
        elevation: 0,
        dropdownColor: theme.colorScheme.surface,
        style: theme.textTheme.bodyLarge?.copyWith(),
        borderRadius: BorderRadius.circular(10),
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(
            value: LoyaltyCardEffect.snowy,
            child: Text('Snowy'),
          ),
          DropdownMenuItem(
            value: LoyaltyCardEffect.grain,
            child: Text('Grain'),
          ),
          DropdownMenuItem(
            value: LoyaltyCardEffect.glitter,
            child: Text('Glitter'),
          ),
        ],
        onChanged: (value) {
          _settings.effect.value =
              value ?? const LoyaltyCardEffectSettings.defaultValue().effect;
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
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}
