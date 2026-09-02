import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:flutter/material.dart';

class SortingStyleSelector extends StatelessWidget {
  const SortingStyleSelector({
    super.key,
    required this.controller,
  });

  final ValueNotifier<SortingStyle> controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        return DropdownMenu<SortingStyle>(
          dropdownMenuEntries: SortingStyle.values
              .map(
                (value) => DropdownMenuEntry<SortingStyle>(
                  value: value,
                  label: switch (value) {
                    SortingStyle.nameAz => 'Name 0-Z',
                    SortingStyle.nameZa => 'Name Z-0',
                    SortingStyle.latest => 'Latest',
                    SortingStyle.oldest => 'Oldest',
                    SortingStyle.custom => 'Custom',
                  },
                  style: ButtonStyle(
                    elevation: WidgetStateProperty.all(0.0),
                  ),
                ),
              )
              .toList(growable: false),
          initialSelection: value,
          // A DropdownMenu replaces the ambient decoration theme instead of
          // merging with it, so start from the global one.
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            iconColor: theme.colorScheme.primary,
          ),
          onSelected: (value) =>
              controller.value = value ?? SortingStyle.oldest,
        );
      },
    );
  }
}
