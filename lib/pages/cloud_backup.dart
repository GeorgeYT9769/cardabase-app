import 'dart:convert';
import 'dart:io';

import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../util/widgets/custom_snack_bar.dart';

class CloudBackup extends StatefulWidget {
  const CloudBackup({super.key});

  @override
  State<CloudBackup> createState() => _CloudBackupState();
}

class _CloudBackupState extends State<CloudBackup> {
  bool hideCloudPassword = true;
  bool hideStoragePassword = true;
  bool hasCloudSetUp = false;

  TextEditingController ipAddress = TextEditingController();
  TextEditingController cloudPassword = TextEditingController();
  TextEditingController storagePassword = TextEditingController();

  void changeCloudPasswordVisibilityFunc() {
    setState(() {
      hideCloudPassword = !hideCloudPassword;
    });
  }

  void changeStoragePasswordVisibilityFunc() {
    setState(() {
      hideStoragePassword = !hideStoragePassword;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  void _checkLoginState() {
    final passwordBox = Hive.box('password');
    final Map<dynamic, dynamic>? cloudData = passwordBox.get('CLOUD');
    if (cloudData != null) {
      ipAddress.text = cloudData['ip'] ?? '';
      cloudPassword.text = cloudData['cloudPassword'] ?? '';
      storagePassword.text = cloudData['storagePassword'] ?? '';
      setState(() {
        hasCloudSetUp = true;
      });
    }
  }

  Future<void> uploadCardabase() async {
    final Box myBox = Hive.box('mybox');
    final List cards = myBox.get('CARDLIST', defaultValue: []);
    if (cards.isEmpty) {
      showCustomSnackBar(context, 'No cards to upload', false);
      return;
    }

    final String ip = ipAddress.text.trim();
    if (ip.isEmpty) return;

    //port 5054
    final host = ip.contains(':') ? ip : '$ip:5054';

    int successCount = 0;
    int failCount = 0;

    for (var card in cards) {
      if (card is! Map) continue;

      final String uniqueId = card['uniqueId'] ?? '';
      if (uniqueId.isEmpty) {
        failCount++;
        continue;
      }

      try {
        final uri = Uri.parse('http://$host/cards/$uniqueId');
        final httpClient = HttpClient();
        final request = await httpClient.putUrl(uri);
        request.headers.set('Content-Type', 'application/json');

        final jsonData = jsonEncode(card);
        request.write(jsonData);

        final response = await request.close();
        if (response.statusCode == 200) {
          successCount++;
        } else {
          failCount++;
        }
        httpClient.close();
      } catch (e) {
        debugPrint('Failed to upload card $uniqueId: $e');
        failCount++;
      }
    }

    if (failCount == 0) {
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(context, 'Successfully uploaded $successCount cards', true);
    } else {
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(
        context,
        'Uploaded $successCount cards. Failed on $failCount.',
        failCount < 0,
      );
    }
  }

  Future<void> downloadCardabase() async {
    final String ip = ipAddress.text.trim();
    if (ip.isEmpty) return;

    final host = ip.contains(':') ? ip : '$ip:5054';

    try {
      final uri = Uri.parse('http://$host/cards');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> downloadedCards = jsonDecode(responseBody);

        final Box myBox = Hive.box('mybox');
        myBox.put('CARDLIST', downloadedCards);

        GetIt.I<VibrationProvider>().vibrateSuccess();
        showCustomSnackBar(
          context,
          'Successfully downloaded ${downloadedCards.length} cards',
          true,
        );
      } else {
        GetIt.I<VibrationProvider>().vibrateSuccess();
        showCustomSnackBar(context, 'Failed to download from server', false);
      }
      httpClient.close();
    } catch (e) {
      debugPrint('Failed to download cards: $e');
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(
        context,
        'Error downloading cards: check connection',
        false,
      );
    }
  }

  Future<void> deleteCardabase() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Deletion',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontSize: 25,
              ),
        ),
        content: Text(
          'Are you sure you want to permanently delete ALL cards from the cloud server?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
          OutlinedButton(
            style: Theme.of(context).destructiveButtonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final String ip = ipAddress.text.trim();
    if (ip.isEmpty) return;

    final host = ip.contains(':') ? ip : '$ip:5054';

    try {
      //fetch all cards to know their IDs
      final uri = Uri.parse('http://$host/cards');
      final httpClient = HttpClient();
      final getReq = await httpClient.getUrl(uri);
      final getRes = await getReq.close();

      if (getRes.statusCode != 200) {
        throw Exception('Failed to fetch cards for deletion');
      }

      final responseBody = await getRes.transform(utf8.decoder).join();
      final List<dynamic> cards = jsonDecode(responseBody);

      //delete each card
      int deletedCount = 0;
      for (var card in cards) {
        final String cardId = card['id'] ?? card['uniqueId'] ?? '';
        if (cardId.isEmpty) continue;

        final deleteUri = Uri.parse('http://$host/cards/$cardId');
        final deleteReq = await httpClient.deleteUrl(deleteUri);
        final deleteRes = await deleteReq.close();

        if (deleteRes.statusCode == 200) {
          deletedCount++;
        }
      }

      httpClient.close();
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(
        context,
        'Permanently deleted $deletedCount cards from cloud',
        true,
      );
    } catch (e) {
      debugPrint('Failed to delete cards: $e');
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(
        context,
        'Failed to delete cards from cloud',
        false,
      );
    }
  }

  Future<void> logIn() async {
    final String ip = ipAddress.text.trim();
    if (ip.isEmpty) {
      showCustomSnackBar(context, 'IP Address is required', false);
      return;
    }

    final host = ip.contains(':') ? ip : '$ip:5054';

    //verify server is reachable
    try {
      final uri = Uri.parse('http://$host/healthz');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final passwordBox = Hive.box('password');
        passwordBox.put('CLOUD', {
          'ip': ip,
          'cloudPassword': cloudPassword.text,
          'storagePassword': storagePassword.text,
        });

        setState(() {
          hasCloudSetUp = true;
        });
        GetIt.I<VibrationProvider>().vibrateSuccess();
        showCustomSnackBar(context, 'Successfully connected to server', true);
      } else {
        GetIt.I<VibrationProvider>().vibrateSuccess();
        showCustomSnackBar(
          context,
          'Server returned status ${response.statusCode}',
          false,
        );
      }
      httpClient.close();
    } catch (e) {
      debugPrint('Login failed: $e');
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(context, 'Could not connect to server', false);
    }
  }

  void logOut() {
    final passwordBox = Hive.box('password');
    passwordBox.delete('CLOUD');

    setState(() {
      ipAddress.clear();
      cloudPassword.clear();
      storagePassword.clear();
      hasCloudSetUp = false;
    });

    GetIt.I<VibrationProvider>().vibrateSuccess();
    showCustomSnackBar(
      context,
      'Logged out and cleared cloud configuration',
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        title: Text(
          'Cloud backup',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: 'xirod',
            letterSpacing: 5,
            color: theme.colorScheme.tertiary,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: hasCloudSetUp
          ? Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Text(
                    'MANAGE YOUR CLOUD SERVER',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You are set up. You can enjoy features of your own self-hosted cloud.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Save your cards to cloud:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => uploadCardabase(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload),
                            const SizedBox(width: 10),
                            const Text('Upload Cardabase'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Get your cards from cloud:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => downloadCardabase(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download),
                            const SizedBox(width: 10),
                            const Text('Download Cardabase'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),
                  Text(
                    'Remove server configuration:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => logOut(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout),
                            const SizedBox(width: 10),
                            const Text('Log Out'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Delete your cards from cloud (forever!):',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(
                          borderColor: Colors.red,
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => deleteCardabase(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_forever),
                            const SizedBox(width: 10),
                            const Text('DELETE CARDABASE'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Text(
                    'SET UP CLOUD SERVER',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Backup your cards into your own self-hosted cloud storage. No personal information will be stored. Just you, your cards and the self-hosted cloud storage.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: ipAddress,
                    decoration: InputDecoration(
                      labelText: 'IP Address of the server',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    style: theme.inputTextStyle,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: false,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: cloudPassword,
                    decoration: InputDecoration(
                      labelText: 'Cloud password',
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideCloudPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: changeCloudPasswordVisibilityFunc,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: hideCloudPassword,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: storagePassword,
                    decoration: InputDecoration(
                      labelText: 'Storage password',
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideStoragePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: changeStoragePasswordVisibilityFunc,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: hideStoragePassword,
                  ),
                  const SizedBox(height: 20),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => logIn(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login),
                            const SizedBox(width: 10),
                            const Text('Log In'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
