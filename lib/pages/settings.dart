import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
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
  //String fileContent = "";
//
//
  //Future<void> pickFile() async {
  //  FilePickerResult? result = await FilePicker.platform.pickFiles();
//
  //  if (result != null) {
  //    File datFile = File(result.files.single.path!);
  //    Directory directory = await getTemporaryDirectory();
  //    File txtFile = File('${directory.path}/converted_file.txt');
//
  //    try {
  //      // Convert .dat to .txt using UTF-8 encoding
  //      await txtFile.writeAsString(
  //          await datFile.readAsString());
//
  //      final content = await txtFile.readAsString();
  //      setState(() {
  //        fileContent = content;
  //      });
  //    } catch (e) {
  //      setState(() {
  //        fileContent = 'Error reading file: $e';
  //      });
  //    }
  //  }
  //}

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
    };
  }

  Future<void> _launchUrl(url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
        backgroundColor: Theme.of(context).colorScheme.background,
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
              'Export cards to another device',
              settingAction: () => showToast(
                  "Not implemented yet",
                  context:context,
                  duration: const Duration(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0, microseconds: 0),
                  animation: StyledToastAnimation.fade,
                  reverseAnimation: StyledToastAnimation.fade,
                  position: const StyledToastPosition(align: Alignment.topCenter)
              ),
              settingHeader: 'Export cards',
              settingIcon: Icons.ios_share
          ),
          MySetting(
              aboutSettingHeader:
              'Import cards to this device',
              settingAction: () => showToast(
                  "Not implemented yet",
                  context:context,
                  duration: const Duration(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0, microseconds: 0),
                  animation: StyledToastAnimation.fade,
                  reverseAnimation: StyledToastAnimation.fade,
                  position: const StyledToastPosition(align: Alignment.topCenter)
              ),
              settingHeader: 'Import cards',
              settingIcon: Icons.save_alt
          ),
          MySetting(
              aboutSettingHeader:
              'Visit website for this project',
              settingAction: () => _launchUrl(Uri.parse('https://georgeyt9769.github.io/cardabase/')),
              settingHeader: 'Website',
              settingIcon: Icons.info
          )
        ],
      ),
    );
  }
}
