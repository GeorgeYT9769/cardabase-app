import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/pages/home/form_fields/number_of_columns_slider.dart';
import 'package:cardabase/pages/home/form_fields/sorting_style_selector.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';

class CardListViewOptionsDialog extends StatelessWidget {
  const CardListViewOptionsDialog({
    super.key,
    required this.allTags,
    required this.isInReorderingMode,
    required this.tagFilter,
    required this.sortingStyle,
    required this.numberOfColumns,
    required this.sortNameCaseInsensitive,
    required this.sortNameIgnoreAccents,
  });

  final List<String> allTags;
  final ValueNotifier<bool> isInReorderingMode;
  final ValueNotifier<String?> tagFilter;
  final ValueNotifier<SortingStyle> sortingStyle;
  final ValueNotifier<int> numberOfColumns;
  final ValueNotifier<bool> sortNameCaseInsensitive;
  final ValueNotifier<bool> sortNameIgnoreAccents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Sort',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: SizedBox(
        height: 400,
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          child: Column(
            children: <Widget>[
              if (allTags.isNotEmpty) ..._tagFilter(theme),
              _optionTitle(theme, 'Sort by:'),
              const SizedBox(height: 10),
              SortingStyleSelector(controller: sortingStyle),
              ValueListenableBuilder<SortingStyle>(
                valueListenable: sortingStyle,
                builder: (context, value, _) {
                  if (value == SortingStyle.nameAz ||
                      value == SortingStyle.nameZa) {
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: sortNameCaseInsensitive,
                          builder: (context, isCaseInsensitive, _) =>
                              SwitchListTile(
                            title: Text(
                              'Case Insensitive',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.inverseSurface,
                              ),
                            ),
                            activeTrackColor: theme.colorScheme.primary,
                            value: isCaseInsensitive,
                            onChanged: (value) {
                              GetIt.I<VibrationProvider>().vibrateSelection();
                              sortNameCaseInsensitive.value = value;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: sortNameIgnoreAccents,
                          builder: (context, ignoreAccents, _) =>
                              SwitchListTile(
                            title: Text(
                              'Ignore Accents',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.inverseSurface,
                              ),
                            ),
                            activeTrackColor: theme.colorScheme.primary,
                            value: ignoreAccents,
                            onChanged: (value) {
                              GetIt.I<VibrationProvider>().vibrateSelection();
                              sortNameIgnoreAccents.value = value;
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 10),
              _divider(theme),
              const SizedBox(height: 10),
              _optionTitle(theme, 'Reorder Mode:'),
              ValueListenableBuilder(
                valueListenable: isInReorderingMode,
                builder: (context, value, _) => SwitchListTile(
                  title: Text(
                    isInReorderingMode.value ? 'On' : 'Off',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                    ),
                  ),
                  activeTrackColor: theme.colorScheme.primary,
                  value: value,
                  onChanged: (newValue) {
                    GetIt.I<VibrationProvider>().vibrateSelection();
                    isInReorderingMode.value = newValue;
                  },
                ),
              ),
              const SizedBox(height: 10),
              _divider(theme),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: numberOfColumns,
                builder: (context, value, _) => _optionTitle(
                  theme,
                  'Columns: $value',
                ),
              ),
              const SizedBox(height: 10),
              NumberOfColumnsSlider(controller: numberOfColumns),
            ],
          ),
        ),
      ),
      actions: [
        Center(
          child: Bounceable(
            onTap: () {},
            child: OutlinedButton(
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'SELECT',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.inverseSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        color: theme.colorScheme.inverseSurface,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.primary,
      thickness: 1.0,
    );
  }

  List<Widget> _tagFilter(ThemeData theme) {
    return [
      _optionTitle(theme, 'Tags:'),
      const SizedBox(height: 10),
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        scrollDirection: Axis.horizontal,
        child: ValueListenableBuilder(
          valueListenable: tagFilter,
          builder: (context, tagFilter, _) => Row(
            children: allTags
                .map(
                  (tag) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _tag(theme, tag, tagFilter == tag),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
      const SizedBox(height: 5),
      _divider(theme),
      const SizedBox(height: 10),
    ];
  }

  Widget _tag(ThemeData theme, String tag, bool isSelected) {
    return ActionChip(
      label: Text(tag),
      onPressed: () => tagFilter.value = isSelected ? null : tag,
      labelStyle: theme.textTheme.bodyLarge?.copyWith(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.inverseSurface,
      ),
      backgroundColor: isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.onInverseSurface,
      elevation: isSelected ? null : 0.0,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
      avatar: isSelected
          ? Icon(
              Icons.check,
              size: 18,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }
}
