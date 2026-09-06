import 'dart:math' as math;

import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/pages/home/home_page.dart';
 import 'package:cardabase/pages/lock_screen.dart';
import 'package:cardabase/pages/terms_of_service.dart';
import 'package:cardabase/util/widgets/cdb_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, SystemNavigator;
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

import '../util/expressive_loading_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  final String currentAppVersion;

  const WelcomeScreen({super.key, required this.currentAppVersion});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final settingsBox = GetIt.I<SettingsBox>();
  String? changelog;
  bool expanded = false;
  late int days = calculateDaysUntilEndOfAndroid();

  @override
  void initState() {
    super.initState();
    loadChangelog();
  }

  int calculateDaysUntilEndOfAndroid() {
    int days;
    DateTime end = DateTime(2026, 10, 1);
    DateTime now = DateTime.now();
    Duration difference = end.difference(now);
    days = difference.inDays;
    return days > 0 ? days : 0;
  }

  Future<void> loadChangelog() async {
    try {
      final String changelogText = await rootBundle.loadString('CHANGELOG.txt');
      final String? versionLog =
          _extractChangelogForVersion(changelogText, widget.currentAppVersion);
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
      if (lines[i].contains('$version:')) {
        start = i;
        break;
      }
    }
    if (start == -1) return null;

    final buffer = StringBuffer();
    for (int i = start; i < lines.length; i++) {
      if (i != start &&
          RegExp(r'^\d{1,2}\.\d{1,2}\.\d{4}').hasMatch(lines[i])) {
        break;
      }
      buffer.writeln(lines[i]);
    }
    return buffer.toString().trim();
  }

  void continueToApp() async {
    final editable = settingsBox.value.editable();
    editable.lastSeenAppVersion.value =
        widget.currentAppVersion;
    await settingsBox.save(editable.seal());
    editable.dispose();

    if (!mounted) {
      return;
    }
    final passwordBox = GetIt.I<Box>(instanceName: 'passwordBox');
    final storedPassword = passwordBox.get('PW');
    final hasPassword = storedPassword is String && storedPassword.isNotEmpty;
    final lockApp = passwordBox.get('lock_app', defaultValue: false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            (hasPassword && lockApp) ? const LockScreen() : const Homepage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isErrorOrEmpty = changelog == 'No changelog found for this version.' ||
        changelog == 'Failed to load changelog.';
    final hasEnoughLines = (changelog?.split('\n').length ?? 0) > 3;
    final showExpandButton = !isErrorOrEmpty && hasEnoughLines;

    final changelogWidget = changelog == null
        ? ExpressiveLoadingIndicator(
            color: Theme.of(context).colorScheme.tertiary,
            constraints: const BoxConstraints(
              minWidth: 64.0,
              minHeight: 64.0,
              maxWidth: 64.0,
              maxHeight: 64.0,
            ),
            polygons: [
              MaterialShapes.softBurst,
              MaterialShapes.pentagon,
              MaterialShapes.pill,
            ],
            semanticsLabel: 'Loading',
            semanticsValue: 'In progress',
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's new in version ${widget.currentAppVersion}:",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              if (!showExpandButton)
                Text(
                  changelog!,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                )
              else
                AnimatedCrossFade(
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFirstLines(changelog!, 3),
                        style:
                            theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              changelog!,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontSize: 16),
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
      extendBodyBehindAppBar: true,
      appBar: CdbAppBar(
        title: 'Welcome',
        leading: Transform.rotate(
          angle: math.pi,
          child: IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () => SystemNavigator.pop(),
          ),
        ),
        actions: [
          Transform.rotate(
            angle: math.pi,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.colorScheme.secondary,
              ),
              onPressed: continueToApp,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (days > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 5, 20, 10),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your phone is about to stop being yours.\nTime left: $days days.\nFor more info visit keepandroidopen.org',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 30),
                    changelogWidget,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Bounceable(
                  onTap: () {},
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width / 4,
                    child: OutlinedButton(
                      onPressed: continueToApp,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                        ),
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
                        final editable = settingsBox.value.editable();
                        editable.lastSeenAppVersion.value =
                            widget.currentAppVersion;
                        await settingsBox.save(editable.seal());
                        editable.dispose();

                        if (!context.mounted) {
                          return;
                        }
                        final passwordBox = GetIt.I<Box>(instanceName: 'passwordBox');
                        final storedPassword = passwordBox.get('PW');
                        final hasPassword = storedPassword is String && storedPassword.isNotEmpty;
                        final lockApp = passwordBox.get('lock_app', defaultValue: false);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                (hasPassword && lockApp) ? const LockScreen() : const Homepage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.inverseSurface,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        minimumSize: const Size.square(40),
                      ),
                      child: Text(
                        'Skip for now',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.inverseSurface,),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  child: Text(
                    'By entering the app, you agree to the Terms of Service',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstLines(String text, int lines) {
    final splitted = text.split('\n');
    return splitted.take(lines).join('\n');
  }
}
