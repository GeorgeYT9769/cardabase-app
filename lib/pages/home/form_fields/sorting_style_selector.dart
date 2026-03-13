import 'package:flutter/material.dart';

enum SortingStyle {
  nameAz,
  nameZa,
  latest,
  oldest;

  String toDbValue() {
    return switch (this) {
      SortingStyle.nameAz => 'nameaz',
      SortingStyle.nameZa => 'nameza',
      SortingStyle.latest => 'latest',
      SortingStyle.oldest => 'oldest',
    };
  }

  static SortingStyle fromDbValue(String value) {
    return switch (value) {
      'nameaz' => SortingStyle.nameAz,
      'nameza' => SortingStyle.nameZa,
      'latest' => SortingStyle.latest,
      _ => SortingStyle.oldest,
    };
  }
}

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
                  },
                  style: ButtonStyle(
                    elevation: WidgetStateProperty.all(0.0),
                  ),
                ),
              )
              .toList(growable: false),
          initialSelection: value,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 2.0),
            ),
            focusColor: theme.colorScheme.primary,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(10),
            ),
            labelStyle: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.secondary),
            iconColor: theme.colorScheme.primary,
          ),
          onSelected: (value) =>
              controller.value = value ?? SortingStyle.oldest,
        );
      },
    );
  }
}
