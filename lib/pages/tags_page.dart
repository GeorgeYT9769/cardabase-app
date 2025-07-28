import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      builder: (context) => AlertDialog(
        title: Text('Add a tag', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',)),
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
                focusColor: Theme.of(context).colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                prefixIcon: Icon(
                  Icons.label,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Tag',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  addTag(controller.text);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(elevation: 0.0),
                child: Text(
                  'ADD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addTag(String tag) {
    final box = Hive.box('settingsBox');
    final tags = box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    if (!tags.contains(tag)) {
      tags.add(tag);
      box.put('tags', tags);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            )  ,
            content: const Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Tag already exists!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ));
    }
  }

  void removeTag(String tag) {
    final box = Hive.box('settingsBox');
    final tags = box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    if (tags.contains(tag)) {
      tags.remove(tag);
      box.put('tags', tags);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            )  ,
            content: const Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Tag does not exist!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Tags',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'xirod',
              letterSpacing: 5,
              color: Theme.of(context).colorScheme.tertiary,
            )
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: () {Navigator.of(context).pop();},),
        ],
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('settingsBox').listenable(),
        builder: (context, box, widget) {
          final tags = box.get('tags', defaultValue: <dynamic>[]);

          if (tags == null || tags.isEmpty) {
            return Center(
              child: Text(
                'No tags added',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto-Regular.ttf',),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  tags[index],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: Icon(Icons.label, color: Theme.of(context).colorScheme.secondary),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.secondary),
                  onPressed: () {
                    removeTag(tags[index]);
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
