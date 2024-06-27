import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';

final themebox = Hive.box('mytheme');
final box = Hive.box('mybox');
int count = 0;

class Settings extends StatefulWidget {
  const Settings({super.key,});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  @override
  void initState() {

    super.initState();
  }

  void switchTheme() {
    if (themebox.get('apptheme') == false) {
      setState(() {
        themebox.put('apptheme', true);
        Restart.restartApp();
      });
    } else if (themebox.get('apptheme') == true) {
      setState(() {
        themebox.put('apptheme', false);
        Restart.restartApp();
      });
    } else {
      setState(() {
        themebox.put('apptheme', true);
        Restart.restartApp();
      });
    }
  }

  Future<void> _launchUrl(url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: () {
          Navigator.pop(context);
        },),
        title: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'xirod',
              letterSpacing: 8,
              color: Theme.of(context).colorScheme.tertiary,
            )
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),

      body: ListView(
        children: [
          MySetting(
              aboutSettingHeader:
              'Switches theme between dark blue and white',
              settingAction: switchTheme, //() => Provider.of<ThemeProvider>(context, listen: false).toggleTheme()
              settingHeader: 'Switch theme',
              settingIcon: Icons.palette
          ),
          MySetting(
              aboutSettingHeader:
              'Visit website for this project',
              settingAction: () => _launchUrl(Uri.parse('https://georgeyt9769.github.io/cardabase/')),
              settingHeader: 'Website',
              settingIcon: Icons.info
          ),
          MySetting(
              aboutSettingHeader:
              'Visit source code of this project',
              settingAction: () => _launchUrl(Uri.parse('https://github.com/GeorgeYT9769/cardabase-app')),
              settingHeader: 'GitHub',
              settingIcon: Icons.code
          )
        ],
      ),
    );
  }
}
