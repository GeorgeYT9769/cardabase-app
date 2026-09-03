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
      title: const Text('Sort'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                          _caseSensitiveSwitch(theme),
                          const SizedBox(height: 10),
                          _ignoreAccentsSwitch(theme),
                        ],
                      );
                    } else if (value == SortingStyle.custom) {
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          _reorderingModeSwitch(theme),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
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
      ),
      actions: [
        Center(
          child: _selectButton(context),
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

  List<Widget> _tagFilter(ThemeData theme) {
    return [
      Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ValueListenableBuilder<String?>(
          valueListenable: tagFilter,
          builder: (context, selectedTag, _) {
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: _optionTitle(theme, 'Tags:'),
              subtitle: Text(
                selectedTag ?? 'None',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconColor: theme.colorScheme.primary,
              collapsedIconColor: theme.colorScheme.primary,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: allTags
                      .map(
                        (tag) => _tag(theme, tag, selectedTag == tag),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
      const Divider(),
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
      //avatar: isSelected
      //    ? Icon(
      //        Icons.check,
      //        size: 18,
      //        color: theme.colorScheme.onPrimary,
      //      )
      //    : null,
    );
  }

  Widget _selectButton(BuildContext context) {
    return Bounceable(
      onTap: () {},
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('SELECT'),
      ),
    );
  }

  Widget _caseSensitiveSwitch(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: sortNameCaseInsensitive,
      builder: (context, isCaseInsensitive, _) => SwitchListTile(
        title: Text(
          'Case Insensitive',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
          ),
        ),
        activeTrackColor: theme.colorScheme.primary,
        value: sortNameCaseInsensitive.value,
        onChanged: (value) {
          GetIt.I<VibrationProvider>().vibrateSelection();
          sortNameCaseInsensitive.value = value;
        },
      ),
    );
  }

  Widget _ignoreAccentsSwitch(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: sortNameIgnoreAccents,
      builder: (context, ignoreAccents, _) => SwitchListTile(
        title: Text(
          'Ignore Accents',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
          ),
        ),
        activeTrackColor: theme.colorScheme.primary,
        value: sortNameIgnoreAccents.value,
        onChanged: (value) {
          GetIt.I<VibrationProvider>().vibrateSelection();
          sortNameIgnoreAccents.value = value;
        },
      ),
    );
  }

  Widget _reorderingModeSwitch(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: isInReorderingMode,
      builder: (context, value, _) => SwitchListTile(
        title: Text(
          'Reorder mode',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
          ),
        ),
        activeTrackColor: theme.colorScheme.primary,
        value: value,
        onChanged: (newValue) {
          if (sortingStyle.value != SortingStyle.custom) {
            return;
          }
          GetIt.I<VibrationProvider>().vibrateSelection();
          isInReorderingMode.value = newValue;
        },
      ),
    );
  }
}
