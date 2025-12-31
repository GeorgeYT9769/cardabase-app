import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/pages/homepage.dart';
import 'package:flutter/services.dart' show rootBundle;

class WelcomeScreen extends StatefulWidget {
  final String currentAppVersion;

  const WelcomeScreen({Key? key, required this.currentAppVersion}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? changelog;
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    loadChangelog();
  }

  Future<void> loadChangelog() async {
    try {
      final String changelogText = await rootBundle.loadString('CHANGELOG.txt');
      final String? versionLog = _extractChangelogForVersion(changelogText, widget.currentAppVersion);
      setState(() {
        changelog = versionLog ?? 'No changelog found for this version.';
      });
    } catch (e) {
      setState(() {
        changelog = 'Failed to load changelog.';
      });
    }
  }

  String? _extractChangelogForVersion(String changelogText, String version) {
    final lines = changelogText.split('\n');
    int start = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(version + ':')) {
        start = i;
        break;
      }
    }
    if (start == -1) return null;

    final buffer = StringBuffer();
    for (int i = start; i < lines.length; i++) {
      if (i != start && RegExp(r'^\d{1,2}\.\d{1,2}\.\d{4}').hasMatch(lines[i])) break;
      buffer.writeln(lines[i]);
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final changelogWidget = changelog == null
        ? const CircularProgressIndicator()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What\'s new in version ${widget.currentAppVersion}:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20,),
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFirstLines(changelog!, 3),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => setState(() => expanded = true),
                      ),
                    ),
                  ],
                ),
                secondChild: SizedBox(
                  height: 180,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            changelog!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                          ),
                        ),
                      ),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up),
                          onPressed: () => setState(() => expanded = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Cardabase!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 25,),),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 30),
              changelogWidget,
              Text('Important: New storage system -> ERRORS. To fix this, export and import all your cards to convert them.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 40),
              Bounceable(
                onTap: () {},
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 4,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Hive.box('settingsBox').put('lastSeenAppVersion', widget.currentAppVersion);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Homepage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 22, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Bounceable(
                onTap: () {},
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 7,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Hive.box('settingsBox').put('lastSeenAppVersion', widget.currentAppVersion);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Homepage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.inverseSurface, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                      ),
                      minimumSize: const Size.square(40)
                    ),
                    child: Text('Skip for now', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface),),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFirstLines(String text, int lines) {
    final splitted = text.split('\n');
    return splitted.take(lines).join('\n');
  }
}