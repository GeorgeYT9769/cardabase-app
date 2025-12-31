import 'package:cardabase/pages/createcardnew.dart';
import 'package:cardabase/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/theme/color_schemes.g.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cardabase/util/export_data.dart';
import 'dart:async';
import 'package:cardabase/pages/settings.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  FlutterError.onError = (FlutterErrorDetails details) {

   FlutterError.presentError(details);
    if (navigatorKey.currentState != null && navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
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
                title: const Text('Application Error', style: TextStyle(color: Colors.red)),
                content: Text(
                  'Oops! Something critical went wrong:\n\n${details.exception}\n\n'
                      'Please send a screenshot of this error to the developer.\n',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => _launchUrl(Uri.parse('https://github.com/GeorgeYT9769/cardabase-app/issues')),
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
        style: const TextStyle(color: Colors.red, fontSize: 18,),
        textAlign: TextAlign.center,
      ),
    );
  };

  await Hive.initFlutter();
  await Hive.openBox('mybox'); //storage for cards
  await Hive.openBox('settingsBox'); // storage for settings
  await Hive.openBox('password'); // storage for password

  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String currentAppVersion = packageInfo.version;
  String? lastSeenAppVersion = Hive.box('settingsBox').get('lastSeenAppVersion');
  // Read auto-backup settings safely
  bool autoBackups = Hive.box('settingsBox').get('autoBackups') ?? false;
  String? lastAutoUpdate = Hive.box('settingsBox').get('lastAutoUpdate');
  int autoBackupInterval = Hive.box('settingsBox').get('autoBackupInterval') ?? 7;

  Widget initialScreen;

  if (lastSeenAppVersion == null || lastSeenAppVersion != currentAppVersion) {
    initialScreen = WelcomeScreen(currentAppVersion: currentAppVersion);
  } else {
    initialScreen = Homepage();
  }


  runApp(
    Main(initialScreen: initialScreen),
  );

  if (autoBackups && lastAutoUpdate != null) {
    try {
      final DateTime lastDt = DateTime.parse(lastAutoUpdate);
      final int daysSince = DateTime.now().difference(lastDt).inDays;
      if (daysSince >= autoBackupInterval) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
            exportCardList(navigatorKey.currentContext!, toFile: true);
            Hive.box('settingsBox').put('lastAutoUpdate', DateTime.now().toString());
          }
        });
      }
    } catch (e) {
      // If parsing fails, ignore and do not attempt export
    }
  }
}


class Main extends StatefulWidget {
  final Widget initialScreen;

  const Main({super.key, required this.initialScreen});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {

  final QuickActions quickActions = QuickActions();
  String shortcut = 'nothing set';

  @override
  void initState() {
    super.initState();

    quickActions.initialize((shortcutType) {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        if (shortcutType == 'add_card') {
          navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => const CreateCard()));
        }
        if (shortcutType == 'info') {
          navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => const Settings()));
        }
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'add_card', localizedTitle: 'Add card', icon: 'ic_add_card'), // Added icon
      const ShortcutItem(type: 'info', localizedTitle: 'Info', localizedSubtitle: 'See info', icon: 'ic_info') // Added icon
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
      valueListenable: Hive.box('settingsBox').listenable(),
      builder: (context, box, child) {

        bool isDarkMode = box.get('isDarkMode', defaultValue: false);
        bool useSystemFont = box.get('useSystemFont', defaultValue: false);
        bool useExtraDark = box.get('useExtraDark', defaultValue: false); // Retrieve new setting

        ColorScheme extraDarkColorScheme = darkColorScheme.copyWith(
          surface: Colors.black,
        );

        final String? textFont = useSystemFont ? null : 'Roboto';

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
                  }
              ),
              fontFamily: textFont,
            textTheme: TextTheme(
              titleLarge: TextStyle(
                fontFamily: useSystemFont ? null : 'xirod',
                letterSpacing: useSystemFont ? 3 : 5,
                fontSize: useSystemFont ? 25 : 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0062A1), //tertiary
              ),
              bodyLarge: TextStyle(
                  fontFamily: textFont,
                  color: Color(0xFF003062)
              ),
            ),
          ),
          darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: useExtraDark ? extraDarkColorScheme : darkColorScheme,
              pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
                  }
              ),
              fontFamily: textFont,
              textTheme: TextTheme(
                titleLarge: TextStyle(
                    fontFamily: useSystemFont ? null : 'xirod',
                    letterSpacing: useSystemFont ? 3 : 5,
                    fontSize: useSystemFont ? 25 : 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9CCAFF), //tertiary
                ),
                bodyLarge: TextStyle(
                    fontFamily: textFont,
                    color: Color(0xFFD6E3FF) //inverseSurface
                ),
              ),
          ),
          home: widget.initialScreen,
        );
      },
    );
  }
}
