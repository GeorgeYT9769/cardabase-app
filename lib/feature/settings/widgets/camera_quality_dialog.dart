import 'package:cardabase/feature/settings/model.dart';
import 'package:material_ui/material_ui.dart';

/// Labels for [Settings.cameraQuality] (index = stored value).
const cameraQualityLabels = <String>['720p', '1080p', '4K', 'Max'];

const _cameraQualityDescriptions = <String>[
  'Fastest, lowest detail. For very old or slow phones.',
  'Fast, good detail.',
  'Recommended. Sharp card pictures, still light on resources.',
  'Highest resolution the camera offers. Can be slow and use a lot of memory on phones with 50 MP+ cameras.',
];

/// Lets the user pick the in-app camera resolution with a slider.
/// Returns the chosen [Settings.cameraQuality] value, or null if dismissed.
class CameraQualityDialog extends StatefulWidget {
  const CameraQualityDialog({super.key, required this.initialValue});

  final int initialValue;

  @override
  State<CameraQualityDialog> createState() => _CameraQualityDialogState();
}

class _CameraQualityDialogState extends State<CameraQualityDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(0, cameraQualityLabels.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Camera quality'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cameraQualityLabels[_value],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _value.toDouble(),
            max: (cameraQualityLabels.length - 1).toDouble(),
            divisions: cameraQualityLabels.length - 1,
            label: cameraQualityLabels[_value],
            onChanged: (v) => setState(() => _value = v.round()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lower', style: theme.textTheme.bodySmall),
                Text('Higher', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _cameraQualityDescriptions[_value],
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Only affects photos taken with the in-app camera. The saved card picture has the same size at every setting.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_value),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
