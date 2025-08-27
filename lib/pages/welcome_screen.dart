import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/pages/homepage.dart';

class WelcomeScreen extends StatefulWidget {
  final String currentAppVersion;

  const WelcomeScreen({Key? key, required this.currentAppVersion}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Cardabase!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 25,),),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 30),
              Text(
                'New in Version ${widget.currentAppVersion}!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '🚀 Exciting new features are here!\n\n'
                    '- Reworked storage system\n'
                    '- Reorder mode\n'
                    '- Sorting system\n'
                    '- Tags to categorize cards\n'
                    '- Welcome back and info screen\n'
                    '- Check news page for more!\n',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              Text('Important: New storage system means you will get errors on home page. To fix this, export and import all your cards to convert them to the new system.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 40),
              Bounceable(
                onTap: () {},
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 4,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Hive.box('settingsBox').put('lastSeenAppVersion', widget.currentAppVersion);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Homepage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 22, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Bounceable(
                onTap: () {},
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 7,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Hive.box('settingsBox').put('lastSeenAppVersion', widget.currentAppVersion);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Homepage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.inverseSurface, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                      ),
                      minimumSize: const Size.square(40)
                    ),
                    child: Text('Skip for now', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface),),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}