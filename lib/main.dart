import 'dart:async';
import 'dart:io';

import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/auto_update.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/get_it.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/pages/info.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';

import 'feature/cards/get_it.dart';
import 'feature/cards/import_export/import_cards.dart';
import 'util/widgets/custom_snack_bar.dart';

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
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid || Platform.isIOS) {
      // For sharing images coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        _handleSharedMedia(value);
      }, onError: (err) {
        print("getIntentDataStream error: $err");
      });

      // For sharing images coming from outside the app while the app is closed
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        _handleSharedMedia(value);
        ReceiveSharingIntent.instance.reset(); // reset intent
      });

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
              MaterialPageRoute(builder: (context) => const InfoScreen()),
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
  }

  void _handleSharedMedia(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    final file = media.first;
    if (file.path.toLowerCase().endsWith('.cdb')) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final loadBoxResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import CDB File?'),
          content: const Text('This will overwrite your current cards and settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (loadBoxResult == true) {
        try {
          final importResult = await importDataFromFilePath(file.path);
          final cardsBox = GetIt.I<LoyaltyCardsBox>();
          final settingsBox = GetIt.I<SettingsBox>();

          if (importResult.cards.isNotEmpty) {
            await cardsBox.clear();
            await cardsBox.putAll(
              importResult.cards.asMap().map((_, value) => MapEntry(value.id, value)),
            );
          }

          final settings = importResult.settings;
          if (settingsBox.isEmpty) {
            await settingsBox.add(settings);
          } else {
            await settingsBox.putAt(0, settings);
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              buildCustomSnackBar('Imported all data from CDB!', true),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              buildCustomSnackBar('Failed to import CDB: $e', false),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      _intentDataStreamSubscription.cancel();
    }
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
