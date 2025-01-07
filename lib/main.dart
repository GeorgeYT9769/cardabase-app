import 'package:cardabase/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/theme/color_schemes.g.dart';
import 'package:flutter/services.dart';

void main() async {
  await Hive.initFlutter();
  var allcards = await Hive.openBox('mybox'); //storage for cards
  await Hive.openBox('settingsBox'); // storage for settings
  var password = await Hive.openBox('password'); // storage for password

  runApp(
    Main(),
  );
}


class Main extends StatelessWidget {
  Main({super.key});

  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(),
      builder: (context, box, widget) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(colorScheme: lightColorScheme),
          darkTheme: ThemeData(colorScheme: darkColorScheme),
          home: Homepage(),
        );
      },
    );
  }
}

