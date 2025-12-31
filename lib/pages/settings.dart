import 'package:cardabase/pages/tags_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/cardabase_db.dart';
import '../util/devoptions.dart';
import '../util/systemfont_provider.dart';
import 'info.dart';
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
bool devOptions = DeveloperOptionsProvider.developerOptions;
bool useSystemFontEverywhere = SystemFontProvider.useSystemFont;
bool autoUpdates = settingsbox.get('autoBackups') ?? false;
int autoUpdateInterval = settingsbox.get('autoBackupInterval') ?? 7;
bool useExtraDark = settingsbox.get('useExtraDark') ?? false;

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

  void toggleDeveloperOptions() {
    DeveloperOptionsProvider.toggleDeveloperOptions();
    setState(() {
      devOptions = !devOptions;
    });
  }

  void toggleSystemFontEverywhere() {
    SystemFontProvider.toggleSystemFont();
    setState(() {
      useSystemFontEverywhere = !useSystemFontEverywhere;
    });
  }

  void toggleExtraDarkMode() {
    setState(() {
      useExtraDark = !useExtraDark;
      settingsbox.put('useExtraDark', useExtraDark);
    });
  }

  void setAutoBackupsState(bool newValue, int interval) {
    setState(() {
      autoUpdates = newValue;
      autoUpdateInterval = interval;
      settingsbox.put('autoBackups', autoUpdates);
      settingsbox.put('autoBackupInterval', autoUpdateInterval);
      if (autoUpdates) {
        settingsbox.put('lastAutoUpdate', DateTime.now().toString());
      }
    });
  }

  void showAutoUpdateDialog() {
    bool _tempAutoUpdates = autoUpdates;
    int _tempAutoUpdateInterval = autoUpdateInterval;
    final TextEditingController _passwordVerifyControllerDialog = TextEditingController();
    bool _isPasswordCorrectDialog = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState2) {
          return AlertDialog(
            title: Text('Auto Backups', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Enable Auto Backups', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontWeight: FontWeight.bold)),
                  value: _tempAutoUpdates,
                  onChanged: (value) {
                    setState2(() {
                      _tempAutoUpdates = value;
                      if (!value) {
                        _isPasswordCorrectDialog = true;
                        _passwordVerifyControllerDialog.clear();
                      }
                    });
                  },
                ),
                SizedBox(height: 10,),
                Slider(
                  year2023: false,
                  value: _tempAutoUpdateInterval.toDouble(),
                  min: 1,
                  max: 365,
                  divisions: 364,
                  label: '$_tempAutoUpdateInterval days',
                  onChanged: _tempAutoUpdateInterval.toDouble() > 0 ? (double value) {
                    setState2(() {
                      _tempAutoUpdateInterval = value.toInt();
                    });
                  } : null,
                ),
                // Password verification field (only if password exists and _tempAutoUpdates is true)
                if (_tempAutoUpdates && passwordbox.isNotEmpty && (passwordbox.get('PW') != null && passwordbox.get('PW').toString().isNotEmpty)) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordVerifyControllerDialog,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                      focusColor: Theme.of(context).colorScheme.primary,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                      labelText: 'Password',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                      prefixIcon: Icon(Icons.password, color: Theme.of(context).colorScheme.secondary),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.visiblePassword,
                    // onChanged: (value) removed this line
                  ),
                  if (!_isPasswordCorrectDialog && _passwordVerifyControllerDialog.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Incorrect password!',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ],
            ),
            actions: [
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  onPressed: () {
                    if (_tempAutoUpdates == true) {
                      // User wants to ENABLE auto-backups
                      if (passwordbox.isNotEmpty && (passwordbox.get('PW') != null && passwordbox.get('PW').toString().isNotEmpty)) {
                        // Password is set, check if entered password is correct
                        if (_passwordVerifyControllerDialog.text == passwordbox.get('PW')) {
                          // Password correct, commit changes to actual state
                          setAutoBackupsState(true, _tempAutoUpdateInterval);
                          Navigator.of(context).pop();
                        } else {
                          // Password incorrect, update dialog state to show error
                          setState2(() {
                            _isPasswordCorrectDialog = false;
                          });
                          VibrationProvider.vibrateSuccess(); // Provide feedback for incorrect password
                        }
                      } else {
                        // No password set, enable directly
                        setAutoBackupsState(true, _tempAutoUpdateInterval);
                        Navigator.of(context).pop();
                      }
                    } else {
                      // User wants to DISABLE auto-backups (no password needed)
                      setAutoBackupsState(false, _tempAutoUpdateInterval);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('DONE', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),),
                ),
              ),
            ],
          );
        },
      ),
    );
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
          content: Row(
            children: [
              Icon(Icons.check, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Cardabase was reset!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 92, 184, 92),
        ));
    Navigator.of(context).pop(true);
  }

  void showUnlockDialogExport(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30) ),
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
                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);
                      showExportTypeDialog(context);
                    });
                  } else {
                    VibrationProvider.vibrateSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Row(
                          children: [
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),                           child: Text(
                  'EXPORT',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
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
      VibrationProvider.vibrateSuccess();
      showExportTypeDialog(context);
    }
  }

  void showDialogDelete(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This action cannot be undone!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, )),
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
                  labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  labelText: 'Password',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
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
                          content: Row(
                            children: [
                              Icon(Icons.error, size: 15, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Incorrect password!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    Navigator.pop(context);
                    resetCardabase();
                  }
                },
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),                           child: Text(
                  'DELETE',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
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
        body: CustomScrollView(
          physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
          slivers: [
            SliverAppBar(
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  )
              ),
              centerTitle: true,
              elevation: 0.0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              floating: true,
              snap: true,
              // Removed: pinned: true,
              // Removed: expandedHeight: kToolbarHeight * 2,
              // Removed: flexibleSpace: FlexibleSpaceBar( ... ),
              toolbarHeight: kToolbarHeight, // Default height when collapsed
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Settings',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                    'Switch theme between blue and white',
                    settingAction: ThemeProvider.toggleTheme,
                    settingHeader: 'Switch Themes',
                    settingIcon: Icons.palette,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Use true black color for dark mode background',
                    settingAction: toggleExtraDarkMode,
                    settingHeader: 'Extra Dark Mode',
                    iconColor: useExtraDark ? Colors.green : Colors.red, // Indicate active state
                    settingIcon: Icons.brightness_2, // Moon icon for dark mode
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  //MySetting(
                  //  aboutSettingHeader:
                  //  'Create custom themes',
                  //  settingAction: () {},
                  //  settingHeader: 'Custom themes',
                  //  settingIcon: Icons.create,
                  //  iconColor: Theme.of(context).colorScheme.tertiary,
                  //  borderColor: Theme.of(context).colorScheme.primary,
                  //),
                  MySetting(
                    aboutSettingHeader:
                    'Automatic brightness in card details',
                    settingAction: changeBrightness,
                    settingHeader: 'AUTO Brightness',
                    iconColor: bulb ? Colors.red : Colors.green,
                    settingIcon: bulb ? Icons.lightbulb_outline : Icons.lightbulb,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Vibrate on different actions',
                    settingAction: changeVibration,
                    settingHeader: 'Vibrate',
                    iconColor: vibrate ? Colors.green : Colors.red,
                    settingIcon: vibrate ? Icons.vibration : Icons.phone_android_sharp,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:"Use System font everywhere",
                    settingAction: toggleSystemFontEverywhere,
                    settingHeader: 'Use System Font',
                    iconColor: useSystemFontEverywhere ? Colors.green : Colors.red,
                    settingIcon: useSystemFontEverywhere ? Icons.font_download: Icons.font_download_outlined ,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Protect your cards by using password',
                    settingAction: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordScreen()));
                    },
                    settingHeader: 'Password',
                    settingIcon: Icons.password,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Categorize your cards by using tags',
                    settingAction: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TagsPage()));
                    },
                    settingHeader: 'Tags',
                    settingIcon: Icons.label,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Load all your cards from the export',
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
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Backup all your cards into one file',
                    settingAction: askForPasswordExport,
                    settingHeader: 'Export Cardabase',
                    settingIcon: Icons.upload,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Do backups automatically on app start',
                    settingAction: showAutoUpdateDialog,
                    settingHeader: 'AUTO Backups',
                    iconColor: autoUpdates ? Colors.green : Colors.red,
                    settingIcon: Icons.upload,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader: 'Remove all cards from the app',
                    settingAction: () => showDialogDelete(context),
                    settingHeader: 'Delete Cardabase',
                    settingIcon: Icons.delete_outline,
                    iconColor: Colors.red,
                    borderColor: Colors.red,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 20,),                            child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Social Networks',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 23,
                              color: Theme.of(context).colorScheme.inverseSurface
                          ),
                        ),
                      ],
                    ),
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'About Cardabase',
                    settingAction: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen()));
                    },
                    settingHeader: 'App INFO',
                    settingIcon: Icons.info,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Join Cardabase Discord community',
                    settingAction: () => _launchUrl(Uri.parse('https://discord.com/invite/fZNDfG2xv3')),
                    settingHeader: 'Discord',
                    settingIcon: Icons.discord,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Visit source code of this project',
                    settingAction: () => _launchUrl(Uri.parse('https://github.com/GeorgeYT9769/cardabase-app')),
                    settingHeader: 'GitHub',
                    settingIcon: Icons.code,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Visit F-Droid page of this project',
                    settingAction: () => _launchUrl(Uri.parse('https://f-droid.org/en/packages/com.georgeyt9769.cardabase/')),
                    settingHeader: 'F-Droid',
                    settingIcon: Icons.store,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  MySetting(
                    aboutSettingHeader:
                    'Check out the website for this project',
                    settingAction: () => _launchUrl(Uri.parse('https://georgeyt9769.github.io/cardabase/')),                           settingHeader: 'Website',
                    settingIcon: Icons.web,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  //uncomment this to enable dev options in the settings
                  //Container(
                  //  margin: const EdgeInsets.only(top: 20, left: 20,),                            //  child: Column(
                  //    mainAxisAlignment: MainAxisAlignment.center,
                  //    crossAxisAlignment: CrossAxisAlignment.start,
                  //    children: [
                  //      Text(
                  //        'Other',
                  //        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //            fontWeight: FontWeight.bold,
                  //            fontSize: 23,
                  //            color: Theme.of(context).colorScheme.inverseSurface
                  //        ),
                  //      ),
                  //    ],
                  //  ),
                  //),
                  //MySetting(
                  //  aboutSettingHeader:
                  //  'Toggle developer options',
                  //  settingAction: toggleDeveloperOptions,
                  //  settingHeader: 'DEV Options',
                  //  settingIcon:Icons.developer_mode,
                  //  iconColor: devOptions ? Colors.green : Colors.red,
                  //  borderColor: Theme.of(context).colorScheme.primary,
                  //),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
