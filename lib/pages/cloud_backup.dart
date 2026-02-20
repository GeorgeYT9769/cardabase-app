import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class CloudBackup extends StatefulWidget {
  const CloudBackup({super.key});

  @override
  State<CloudBackup> createState() => _CloudBackupState();
}

class _CloudBackupState extends State<CloudBackup> {

  bool hideCloudPassword = true;
  bool hideStoragePassword = true;

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
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
        theme.colorScheme.surface, // - BACKGROUND COLOR (DEFAULT)
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
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              'SET UP CLOUD BACKUP',
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
                //cardTypeText
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
                  onPressed: () {},
                  child: Text(
                    'SAVE',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
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
