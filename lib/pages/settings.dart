import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'password.dart';
import '../theme/theme_provider.dart';
import '../theme/brightness_provider.dart';

final settingsbox = Hive.box('settingsBox');
final isDarkMode = ThemeProvider.isDarkMode;
final brightness = BrightnessProvider.brightness;
bool bulb = BrightnessProvider.brightness;

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

  Future<void> _launchUrl(url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }}

  void changeBrightness() {
    BrightnessProvider.toggleBrightness();
    setState(() {
      bulb = !bulb;
    });
  }

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
              fontSize: 18,
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
          Container(
            margin: const EdgeInsets.only(top: 10, left: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 23,
                  ),
                ),
              ],
            ),
          ),
          MySetting(
              aboutSettingHeader:
              'Switches theme between blue and white',
              settingAction: ThemeProvider.toggleTheme, //() => Provider.of<ThemeProvider>(context, listen: false).toggleTheme()
              settingHeader: 'Switch theme',
              settingIcon: Icons.palette,
              iconColor: Theme.of(context).colorScheme.tertiary,
          ),
          MySetting(
            aboutSettingHeader:
            'Manage the password for the cards',
            settingAction: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordScreen()));
            },
            settingHeader: 'Password',
            settingIcon: Icons.password,
            iconColor: Theme.of(context).colorScheme.tertiary,
          ),
          MySetting(
              aboutSettingHeader:
              'Automatic brightness in card details',
              settingAction: changeBrightness, //BrightnessProvider.toggleBrightness
              settingHeader: 'AUTO Brightness',
              settingIcon: bulb ? Icons.lightbulb_outline : Icons.lightbulb,
              iconColor: bulb ? Colors.red : Colors.green,
          ),
          Container(
            margin: const EdgeInsets.only(top: 20, left: 20,),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Networks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 23,
                  ),
                ),
              ],
            ),
          ),
          MySetting(
            aboutSettingHeader:
            'Join Cardabase Discord commmunity',
            settingAction: () => _launchUrl(Uri.parse('https://discord.com/invite/fZNDfG2xv3')),
            settingHeader: 'Discord',
            settingIcon: Icons.discord,
            iconColor: Theme.of(context).colorScheme.tertiary,
          ),
          MySetting(
              aboutSettingHeader:
              'Visit source code of this project',
              settingAction: () => _launchUrl(Uri.parse('https://github.com/GeorgeYT9769/cardabase-app')),
              settingHeader: 'GitHub',
              settingIcon: Icons.code,
              iconColor: Theme.of(context).colorScheme.tertiary,
          ),
          MySetting(
              aboutSettingHeader:
              'Visit F-Droid page of this project',
              settingAction: () => _launchUrl(Uri.parse('https://f-droid.org/en/packages/com.georgeyt9769.cardabase/')),
              settingHeader: 'F-Droid',
              settingIcon: Icons.store,
              iconColor: Theme.of(context).colorScheme.tertiary,
          ),
          MySetting(
            aboutSettingHeader:
            'Check out the website for this project',
            settingAction: () => _launchUrl(Uri.parse('https://georgeyt9769.github.io/cardabase/')),
            settingHeader: 'Website',
            settingIcon: Icons.info,
            iconColor: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}
