import 'package:cardabase/pages/homepage.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/theme/color_schemes.g.dart';
import 'package:flutter/services.dart';

void main() async {
  await Hive.initFlutter();
  var box = await Hive.openBox('mybox');
  var themebox = await Hive.openBox('mytheme');
  var firstcard = await Hive.openBox('firstcardd');

  runApp(
    Main(),
  );
}


class Main extends StatelessWidget {
  Main({super.key});

  var themeData = ThemeData(useMaterial3: true, colorScheme: lightColorScheme);


  @override
  Widget build(BuildContext context) {

    if (themebox.get('apptheme') == false) {
        themeData = ThemeData(useMaterial3: true, colorScheme: lightColorScheme);
    } else if (themebox.get('apptheme') == true) {
        themeData = ThemeData(useMaterial3: true, colorScheme: darkColorScheme);
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
      theme: themeData,
    );
  }
}

