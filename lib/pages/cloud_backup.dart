import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/util/vibration_provider.dart';

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

  void _showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 3000),
        padding: const EdgeInsets.all(5.0),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.vertical,
        backgroundColor: isError
            ? const Color.fromARGB(255, 237, 67, 55)
            : const Color.fromARGB(255, 92, 184, 92),
      ),
    );
  }

  Future<void> uploadCardabase() async {
    final Box myBox = Hive.box('mybox');
    final List cards = myBox.get('CARDLIST', defaultValue: []);
    if (cards.isEmpty) {
      _showSnackbar('No cards to upload', true);
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
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Successfully uploaded $successCount cards', false);
    } else {
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Uploaded $successCount cards. Failed on $failCount.', failCount > 0);
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
        
        final CardabaseDb cdb = CardabaseDb();
        cdb.loadData();
        
        VibrationProvider.vibrateSuccess();
        _showSnackbar('Successfully downloaded ${downloadedCards.length} cards', false);
      } else {
        VibrationProvider.vibrateSuccess();
        _showSnackbar('Failed to download from server', true);
      }
      httpClient.close();
    } catch (e) {
      debugPrint('Failed to download cards: $e');
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Error downloading cards: check connection', true);
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
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
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
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Permanently deleted $deletedCount cards from cloud', false);

    } catch (e) {
      debugPrint('Failed to delete cards: $e');
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Failed to delete cards from cloud', true);
    }
  }

  Future<void> logIn() async {
    final String ip = ipAddress.text.trim();
    if (ip.isEmpty) {
      _showSnackbar('IP Address is required', true);
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
        VibrationProvider.vibrateSuccess();
        _showSnackbar('Successfully connected to server', false);
      } else {
        VibrationProvider.vibrateSuccess();
        _showSnackbar('Server returned status ${response.statusCode}', true);
      }
      httpClient.close();
    } catch (e) {
      debugPrint('Login failed: $e');
      VibrationProvider.vibrateSuccess();
      _showSnackbar('Could not connect to server', true);
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
    
    VibrationProvider.vibrateSuccess();
    _showSnackbar('Logged out and cleared cloud configuration', false);
  }


  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
        theme.colorScheme.surface,
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(100),
                  ),
                  onPressed: () => uploadCardabase(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload,
                        color: theme.colorScheme.inverseSurface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Upload Cardabase',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.inverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(100),
                  ),
                  onPressed: () => downloadCardabase(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        color: theme.colorScheme.inverseSurface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Download Cardabase',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.inverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Divider(
              color: theme.colorScheme.primary,
              thickness: 1.0,
            ),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(100),
                  ),
                  onPressed: () => logOut(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: theme.colorScheme.inverseSurface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.inverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(
                      color: Colors.red,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(100),
                  ),
                  onPressed: () => deleteCardabase(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'DELETE CARDABASE',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(width: 2.0),
                ),
                focusColor: theme.colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'IP Address of the server',
                labelStyle: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.secondary),
                prefixIcon: Icon(
                  Icons.numbers,
                  color: theme.colorScheme.secondary,
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: TextInputType.visiblePassword,
              obscureText: false,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: cloudPassword,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(width: 2.0),
                ),
                focusColor: theme.colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Cloud password',
                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: theme.colorScheme.secondary,
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(width: 2.0),
                ),
                focusColor: theme.colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Storage password',
                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: theme.colorScheme.secondary,
                ),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(100),
                  ),
                  onPressed: () => logIn(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login,
                        color: theme.colorScheme.inverseSurface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Log In',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.inverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
