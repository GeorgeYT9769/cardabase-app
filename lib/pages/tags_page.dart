import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../util/widgets/custom_snack_bar.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  void showAddDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Add a tag',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.inverseSurface,
              fontSize: 30,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(width: 2.0),
                  ),
                  focusColor: theme.colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  prefixIcon: Icon(
                    Icons.label,
                    color: theme.colorScheme.secondary,
                  ),
                  labelText: 'Tag',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    addTag(controller.text, theme);
                    Navigator.of(context).pop();
                  },
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
                  child: Text(
                    'ADD',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void addTag(String tag, ThemeData theme) {
    final box = Hive.box('settingsBox');
    final tags = box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    if (!tags.contains(tag)) {
      tags.add(tag);
      box.put('tags', tags);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Tag already exists!', false),
      );
    }
  }

  void removeTag(String tag, ThemeData theme) {
    final box = Hive.box('settingsBox');
    final tags = box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    if (tags.contains(tag)) {
      tags.remove(tag);
      box.put('tags', tags);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Tag does not exist!', false),
      );
    }
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
        valueListenable: Hive.box('settingsBox').listenable(),
        builder: (context, box, widget) {
          final tags = box.get('tags', defaultValue: <dynamic>[]) as List?;

          if (tags == null || tags.isEmpty) {
            return Center(
              child: Text(
                'No tags added',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  tags[index] as String,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.inverseSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: Icon(Icons.label, color: theme.colorScheme.secondary),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.secondary),
                  onPressed: () {
                    removeTag(tags[index] as String, theme);
                  },
                ),
              );
            },
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
}
