import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/editable_model.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/add_tag_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';

import '../../../util/widgets/custom_snack_bar.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final _settingsBox = GetIt.I<SettingsBox>();
  final _cardsBox = GetIt.I<LoyaltyCardsBox>();
  final _settings = EditableSettings.fromValue(const Settings.defaultValue());

  @override
  void initState() {
    super.initState();
    _settings.loadValue(_settingsBox.value);
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  Future<void> showAddDialog(BuildContext context) async {
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => AddTagDialog(
        existingTags: _settings.tags.value,
      ),
    );
    if (!mounted || newTag == null) {
      return;
    }

    _addTag(newTag);
  }

  void _addTag(String tag) {
    if (_settings.tags.contains(tag)) {
      showCustomSnackBar(context, 'Tag already exists!', false);
      return;
    }

    _settings.tags.add(tag);
    _settingsBox.save(_settings.seal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tags',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ValueListenableBuilder(
        valueListenable: _settings.tags,
        builder: (context, tags, _) {
          final tagsFromCards = _cardsBox.values
              .expand((card) => card.tags)
              .toSet()
              .difference(tags.toSet());

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              if (tagsFromCards.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                    child: Text(
                      'Tags from Cards:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.inverseSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      children: tagsFromCards.map((tag) {
                        return OutlinedButton(
                          onPressed: () => _addTag(tag),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(tag),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
              if (tags.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No tags added',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _tag(theme, index),
                    childCount: tags.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Bounceable(
        onTap: () {},
        child: SizedBox(
          height: 70,
          width: 70,
          child: FittedBox(
            child: FloatingActionButton(
              elevation: 0.0,
              enableFeedback: true,
              tooltip: 'Add a tag',
              onPressed: () => showAddDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(ThemeData theme, int tagIndex) {
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            icon: Icons.delete,
            backgroundColor: Colors.red,
            onPressed: (context) {
              _settings.tags.removeAt(tagIndex);
              _settingsBox.save(_settings.seal());
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            icon: Icons.delete,
            backgroundColor: Colors.red,
            onPressed: (context) {
              _settings.tags.removeAt(tagIndex);
              _settingsBox.save(_settings.seal());
            },
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          _settings.tags[tagIndex],
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(Icons.label, color: theme.colorScheme.secondary),
      ),
    );
  }
}
