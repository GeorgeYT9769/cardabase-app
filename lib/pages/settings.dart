import 'package:cardabase/pages/tags_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/cardabase_db.dart';
import '../util/camera.dart';
import 'password.dart';
import '../theme/theme_provider.dart';
import '../util/brightness_provider.dart';
import '../util/export_data.dart';
import '../util/import_data.dart';

final settingsbox = Hive.box('settingsBox');
final passwordbox = Hive.box('password');
final isDarkMode = ThemeProvider.isDarkMode;
final brightness = BrightnessProvider.brightness;
bool bulb = BrightnessProvider.brightness;
bool vibrate = VibrationProvider.vibrate;
cardabase_db cdb = cardabase_db();

class Settings extends StatefulWidget {
  const Settings({super.key,});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool didImport = false;
  bool didReset = false;
  double columnAmountDouble = 1;
  int columnAmount = 1;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void changeBrightness() {
    BrightnessProvider.toggleBrightness();
    setState(() {
      bulb = !bulb;
    });
  }

  void changeVibration() {
    VibrationProvider.toggleVibration();
    setState(() {
      vibrate = !vibrate;
    });
  }

  void resetCardabase() {
    setState(() {
      cdb.myShops.removeRange(0, cdb.myShops.length);
      cdb.myShops.clear();
      Hive.box('mybox').clear();
      cdb.updateDataBase();
      didReset = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          )  ,
          content: const Row(
            children: [
              Icon(Icons.check, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Cardabase was reset!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 92, 184, 92),
        ));
    Navigator.of(context).pop(true); // Bubble up to homepage
  }

  showUnlockDialogExport(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',) ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(width: 2.0),
                ),
                focusColor: Theme.of(context).colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();

                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);
                      exportCardList(context);
                    });
                  } else {
                    VibrationProvider.vibrateSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: const Row(
                          children: [
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 3000),
                        padding: const EdgeInsets.all(5.0),
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        behavior: SnackBarBehavior.floating,
                        dismissDirection: DismissDirection.vertical,
                        backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(elevation: 0.0),
                child: Text(
                  'EXPORT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  askForPasswordExport() {
    if (passwordbox.isNotEmpty) {
      showUnlockDialogExport(context);
    } else {
      exportCardList(context);
    }
  }

  void showDialogDelete(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This action cannot be undone!', style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontFamily: 'Roboto-Regular.ttf',)),
            if (passwordbox.isNotEmpty)
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(width: 2.0),
                  ),
                  focusColor: Theme.of(context).colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'Roboto-Regular.ttf',
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  labelText: 'Password',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (passwordbox.isNotEmpty) {
                    if (controller.text == passwordbox.get('PW')) {
                      FocusScope.of(context).unfocus();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.pop(context);
                        resetCardabase();
                      });
                    } else {
                      VibrationProvider.vibrateSuccess();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: const Row(
                            children: [
                              Icon(Icons.error, size: 15, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Incorrect password!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 3000),
                          padding: const EdgeInsets.all(5.0),
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          behavior: SnackBarBehavior.floating,
                          dismissDirection: DismissDirection.vertical,
                          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                        ),
                      );
                    }
                  } else {
                    // No password set, just reset
                    Navigator.pop(context);
                    resetCardabase();
                  }
                },
                style: ElevatedButton.styleFrom(elevation: 0.0),
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    @override
    Widget build(BuildContext context) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop(didImport || didReset);
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,),
                onPressed: () {
                  Navigator.of(context).pop(didImport || didReset);
                },
              ),
            ],
            title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'xirod',
                  letterSpacing: 5,
                  color: Theme.of(context).colorScheme.tertiary,
                )
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: ListView(
            physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular.ttf',
                          fontSize: 23,
                          color: Theme.of(context).colorScheme.inverseSurface
                      ),
                    ),
                  ],
                ),
              ),
              //MySetting(
              //  aboutSettingHeader:
              //  'Camera',
              //  settingAction: () {
              //    Navigator.push(
              //      context,
              //      MaterialPageRoute(builder: (context) => IDCameraScreen()),
              //    );
              //  },
              //  settingHeader: 'Camera',
              //  settingIcon: Icons.camera_alt,
              //  iconColor: Theme.of(context).colorScheme.tertiary,
              //),
              MySetting(
                aboutSettingHeader:
                'Switches theme between blue and white',
                settingAction: ThemeProvider.toggleTheme,
                settingHeader: 'Switch theme',
                settingIcon: Icons.palette,
                iconColor: Theme.of(context).colorScheme.tertiary,
              ),
              MySetting(
                aboutSettingHeader:
                'Automatic brightness in card details',
                settingAction: changeBrightness,
                settingHeader: 'AUTO Brightness',
                settingIcon: bulb ? Icons.lightbulb_outline : Icons.lightbulb,
                iconColor: bulb ? Colors.red : Colors.green,
              ),
              MySetting(
                aboutSettingHeader:
                'Vibrate on actions',
                settingAction: changeVibration,
                settingHeader: 'Vibrate',
                settingIcon: vibrate ? Icons.vibration : Icons.phone_android_sharp,
                iconColor: vibrate ? Colors.green : Colors.red,
              ),
              MySetting(
                aboutSettingHeader:
                'Protect your cards',
                settingAction: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordScreen()));
                },
                settingHeader: 'Password',
                settingIcon: Icons.password,
                iconColor: Theme.of(context).colorScheme.tertiary,
              ),
              MySetting(
                aboutSettingHeader:
                'Categorize your cards',
                settingAction: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TagsPage()));
                },
                settingHeader: 'Tags',
                settingIcon: Icons.label,
                iconColor: Theme.of(context).colorScheme.tertiary,
              ),
              MySetting(
                aboutSettingHeader:
                'Load all your cards',
                settingAction: () async {
                  final imported = await showImportDialog(context);
                  if (imported == true) {
                    setState(() {
                      didImport = true;
                    });
                    Navigator.of(context).pop(true);
                  }
                },
                settingHeader: 'Import Cardabase',
                settingIcon: Icons.save_alt,
                iconColor: Theme.of(context).colorScheme.tertiary,
              ),
              MySetting(
                aboutSettingHeader:
                'Backup all your cards into one file',
                settingAction: askForPasswordExport,
                settingHeader: 'Export Cardabase',
                settingIcon: Icons.upload,
                iconColor: Theme.of(context).colorScheme.tertiary,
              ),
              MySetting(
                  aboutSettingHeader: 'Remove all cards',
                  settingAction: () => showDialogDelete(context),
                  settingHeader: 'Delete Cardabase',
                  settingIcon: Icons.delete_outline,
                  iconColor: Colors.red
              ),
              Container(
                margin: const EdgeInsets.only(top: 20, left: 20,),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Social Networks',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular.ttf',
                          fontSize: 23,
                          color: Theme.of(context).colorScheme.inverseSurface
                      ),
                    ),
                  ],
                ),
              ),
              MySetting(
                aboutSettingHeader:
                'Join Cardabase Discord community',
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
        ),
      );
    }
} 