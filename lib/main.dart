import 'dart:async';
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/auto_update.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/get_it.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/pages/info.dart';
import 'package:cardabase/pages/lock_screen.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
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

  try {
    GetIt.I
      ..registerPackageInfo()
      ..registerHaptics()
      ..registerHive()
      ..registerSettings()
      ..registerCards();

    // ignore: avoid_print
    print('main: awaiting packageInfo');
    final packageInfo = await GetIt.I.getAsync<PackageInfo>();
    // ignore: avoid_print
    print('main: got packageInfo ${packageInfo.version}');

    // ignore: avoid_print
    print('main: awaiting settingsBox');
    final settingsBox = await GetIt.I
        .getAsync<SettingsBox>()
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () async {
            // ignore: avoid_print
            print('main: settingsBox timeout, opening settings202603 directly');
            final hive = await GetIt.I.getAsync<HiveInterface>();
            return hive.openBox<Settings>('settings202603');
          },
        );
    // ignore: avoid_print
    print('main: got settingsBox');

    // ignore: avoid_print
    print('main: awaiting cardsBox');
    final cardsBox = await GetIt.I
        .getAsync<LoyaltyCardsBox>()
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () async {
            // ignore: avoid_print
            print('main: cardsBox timeout, opening cards202603 directly');
            return Hive.openBox<LoyaltyCard>('cards202603');
          },
        );
    // ignore: avoid_print
    print('main: got cardsBox (length=${cardsBox.length})');

    // ignore: avoid_print
    print('main: awaiting passwordBox');
    final passwordBox = await GetIt.I
        .getAsync<Box>(instanceName: 'passwordBox')
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () async {
            // ignore: avoid_print
            print('main: passwordBox timeout, opening password directly');
            final hive = await GetIt.I.getAsync<HiveInterface>();
            return hive.openBox('password');
          },
        );
    // ignore: avoid_print
    print('main: got passwordBox');

    final currentAppVersion = packageInfo.version;

    Widget initialScreen;
    final storedPassword = passwordBox.get('PW');
    final hasPassword = storedPassword is String && storedPassword.isNotEmpty;
    final lockApp = passwordBox.get('lock_app', defaultValue: false);

    String? lastSeenVersion;
    try {
      lastSeenVersion = settingsBox.value.lastSeenAppVersion;
    } catch (e, s) {
      // ignore: avoid_print
      print('main: failed reading settings value: $e\n$s');
      lastSeenVersion = null;
    }

    if (lastSeenVersion != currentAppVersion) {
      initialScreen = WelcomeScreen(currentAppVersion: currentAppVersion);
    } else if (hasPassword && lockApp) {
      initialScreen = const LockScreen();
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
  } catch (e, s) {
    // As a last resort, show a visible startup error instead of a black screen.
    // ignore: avoid_print
    print('main: fatal startup error: $e\n$s');
    runApp(StartupErrorApp(errorMessage: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String errorMessage;

  const StartupErrorApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cardabase failed to initialize local data.\n\nError:\n$errorMessage\n\nPlease restart the app. If this keeps happening, export your data from the old version and reinstall.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class Main extends StatefulWidget {
  final Widget initialScreen;

  const Main({super.key, required this.initialScreen});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  static const QuickActions quickActions = QuickActions();

  /// Sharing intents and home screen quick actions only have an implementation
  /// on Android and iOS. Calling them elsewhere (e.g. the desktop builds) only
  /// throws [MissingPluginException]s.
  static bool get _supportsMobileIntegrations =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String shortcut = 'nothing set';
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    if (!_supportsMobileIntegrations) return;

    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedMedia(value);
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedMedia(value);
      ReceiveSharingIntent.instance.reset();
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

  Widget _dialogButton(BuildContext context, String label, bool result) {
    return Bounceable(
      onTap: () {},
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, result),
        child: Text(label),
      ),
    );
  }

  void _handleSharedMedia(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    final file = media.first;
    if (file.path.toLowerCase().endsWith('.cdb')) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final loadBoxResult = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import CDB File?'),
          content: const Text('This will overwrite your current cards and settings.'),
          actions: [
            _dialogButton(dialogContext, 'Cancel', false),
            _dialogButton(dialogContext, 'Import', true),
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
            showCustomSnackBar(context, 'Imported all data from CDB!', true);
          }
        } catch (e) {
          if (context.mounted) {
            showCustomSnackBar(context, 'Failed to import CDB: $e', false);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
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
