import 'dart:async';

import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/auto_update.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/settings_page.dart';
import 'package:cardabase/get_it.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'feature/cards/get_it.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (navigatorKey.currentState != null &&
        navigatorKey.currentContext != null &&
        navigatorKey.currentContext!.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null &&
            navigatorKey.currentContext!.mounted) {
          bool isDialogOpen = false;
          navigatorKey.currentState!.popUntil((route) {
            if (route is PopupRoute && route.isActive) {
              isDialogOpen = true;
              return false;
            }
            return true;
          });
          if (isDialogOpen) return;

          showDialog(
            context: navigatorKey.currentContext!,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text(
                  'Application Error',
                  style: TextStyle(color: Colors.red),
                ),
                content: Text(
                  'Oops! Something critical went wrong:\n\n${details.exception}\n\n'
                  'Please send a screenshot of this error to the developer.\n',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => _launchUrl(
                      Uri.parse(
                        'https://github.com/GeorgeYT9769/cardabase-app/issues',
                      ),
                    ),
                    child: const Text('GitHub Issue'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      });
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Center(
      child: Text(
        'Oops! Something went wrong:\n${details.exception}\nPlease send a screenshot of this error to the developer.',
        style: const TextStyle(color: Colors.red, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  };

  GetIt.I
    ..registerPackageInfo()
    ..registerHaptics()
    ..registerHive()
    ..registerSettings()
    ..registerCards();

  final packageInfo = await GetIt.I.getAsync<PackageInfo>();
  final settingsBox = await GetIt.I.getAsync<SettingsBox>();
  final cardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
  await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
  final currentAppVersion = packageInfo.version;

  Widget initialScreen;

  if (settingsBox.value.lastSeenAppVersion != currentAppVersion) {
    initialScreen = WelcomeScreen(currentAppVersion: currentAppVersion);
  } else {
    initialScreen = const Homepage();
  }

  runApp(Main(initialScreen: initialScreen));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      autoUpdateAfterInterval(context, settingsBox, cardsBox);
    }
  });
}

class Main extends StatefulWidget {
  final Widget initialScreen;

  const Main({super.key, required this.initialScreen});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  static const QuickActions quickActions = QuickActions();
  String shortcut = 'nothing set';

  @override
  void initState() {
    super.initState();

    quickActions.initialize((shortcutType) {
      if (navigatorKey.currentState != null &&
          navigatorKey.currentContext != null) {
        if (shortcutType == 'add_card') {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => EditCardPage(cardId: generateUniqueId()),
            ),
          );
        }
        if (shortcutType == 'info') {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'add_card',
        localizedTitle: 'Add card',
        icon: 'ic_add_card',
      ), // Added icon
      const ShortcutItem(
        type: 'info',
        localizedTitle: 'Info',
        localizedSubtitle: 'See info',
        icon: 'ic_info',
      ), // Added icon
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ValueListenableBuilder(
      valueListenable: GetIt.I.get<SettingsBox>().listenable(),
      builder: (context, settingsBox, child) {
        final settings = settingsBox.value;
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode:
              settings.theme.useDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: lightTheme(settings.theme),
          darkTheme: darkTheme(settings.theme),
          home: widget.initialScreen,
        );
      },
    );
  }
}
