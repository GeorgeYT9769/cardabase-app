import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../util/vibration_provider.dart';

class SortingStyleSelector extends StatelessWidget {
  const SortingStyleSelector({
    super.key,
    required this.controller,
  });

  final ValueNotifier<SortingStyle> controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<SortingStyle>(
      valueListenable: controller,
      builder: (context, selectedValue, _) {
        final index = SortingStyle.values.indexOf(selectedValue);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sort by:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _getIcon(selectedValue),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLabel(selectedValue),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Slider(
              year2023: false,
              value: index.toDouble(),
              min: 0,
              max: (SortingStyle.values.length - 1).toDouble(),
              divisions: SortingStyle.values.length - 1,
              onChanged: (double newValue) {
                GetIt.I<VibrationProvider>().vibrateSelection();
                controller.value = SortingStyle.values[newValue.round()];
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getIcon(SortingStyle style) {
    return switch (style) {
      SortingStyle.nameAz => Icons.sort_by_alpha,
      SortingStyle.nameZa => Icons.sort_by_alpha,
      SortingStyle.latest => Icons.history,
      SortingStyle.oldest => Icons.update_disabled,
      SortingStyle.mostUsed => Icons.trending_up,
      SortingStyle.leastUsed => Icons.trending_down,
      SortingStyle.custom => Icons.edit_note,
    };
  }

  String _getLabel(SortingStyle style) {
    return switch (style) {
      SortingStyle.nameAz => 'A-Z',
      SortingStyle.nameZa => 'Z-A',
      SortingStyle.latest => 'Latest',
      SortingStyle.oldest => 'Oldest',
      SortingStyle.mostUsed => 'Most Used',
      SortingStyle.leastUsed => 'Least Used',
      SortingStyle.custom => 'Custom',
    };
  }
}
