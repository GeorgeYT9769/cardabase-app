import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'news.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String _appVersion = 'Loading...';
  String? _latestGitHubVersion;
  bool _isLoading = true;
  bool _hasError = false;
  bool? _isUpdateAvailable;
  String? _latestReleaseHtmlUrl;

  final String _githubApiUrl = 'https://api.github.com/repos/GeorgeYT9769/cardabase-app/releases/latest';
  final String _githubReleasesUrl = 'https://github.com/GeorgeYT9769/cardabase-app/releases/latest';

  @override
  void initState() {
    super.initState();
    _fetchAppAndLatestVersion();
  }

  Future<void> _fetchAppAndLatestVersion() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isUpdateAvailable = null;
    });

    try {
      // 1. Get local app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version; //"1.1.0" packageInfo.version

      // 2. Fetch latest version from GitHub API
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String githubTag = data['tag_name'] ?? ''; // e.g., "v1.0.0"
        _latestReleaseHtmlUrl = data['html_url']; // e.g., "https://github.com/.../releases/tag/v1.0.0"

        // Remove 'v' prefix if present for clean comparison (e.g., v1.2.3 -> 1.2.3)
        _latestGitHubVersion = githubTag.startsWith('v') ? githubTag.substring(1) : githubTag;

        // 3. Compare versions (robust for MAJOR.MINOR.PATCH)
        List<int> localParts = _appVersion.split('.').map(int.parse).toList();
        List<int> githubParts = _latestGitHubVersion!.split('.').map(int.parse).toList();

        _isUpdateAvailable = false; // Assume up to date initially

        // Compare parts numerically
        for (int i = 0; i < localParts.length && i < githubParts.length; i++) {
          if (githubParts[i] > localParts[i]) {
            _isUpdateAvailable = true; // GitHub version is newer
            break;
          } else if (localParts[i] > githubParts[i]) {
            _isUpdateAvailable = false; // Local version is newer or equal, no update needed
            break;
          }
        }

        // Handle cases where GitHub version has more parts and is newer (e.g., local 1.0, github 1.0.1)
        if (!(_isUpdateAvailable ?? false) && githubParts.length > localParts.length) {
          _isUpdateAvailable = true;
        }

      } else {
        _hasError = true;
      }
    } catch (e) {
      _hasError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      // Handle error if URL can't be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Info',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ) ?? const TextStyle(
            color: Colors.black,
          ),
        ),
        // Add a back button
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/icons/ic_launcher_foreground.png', height:MediaQuery.of(context).size.width / 2, width: MediaQuery.of(context).size.width / 2),
              const SizedBox(height: 30),
              Text(
                'Cardabase App',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Version: $_appVersion',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'Developed by Juraj Ondovčík',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed:  () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsPage()));
                },
                child: Text(
                  'See Changelog',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator() // Show loading spinner
                  : _hasError
                  ? Column(
                children: [
                  Text(
                    'Failed to check for updates. Please check your internet connection and try again.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _fetchAppAndLatestVersion, // Retry button
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                  ),
                ],
              )
                  : Column(
                children: [
                  Text(
                    _isUpdateAvailable!
                        ? '🚀 New update available! (v$_latestGitHubVersion)'
                        : '🎉 App is up to date!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _isUpdateAvailable! ? Colors.green : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isUpdateAvailable!) ...[
                    const SizedBox(height: 30),
                    Bounceable(
                      onTap: () {},
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width / 5,
                        child: OutlinedButton(
                          onPressed: () => _launchUrl(_githubReleasesUrl),
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
                            'GitHub',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Bounceable(
                      onTap: () {},
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width / 5,
                        child: OutlinedButton(
                          onPressed: () => _launchUrl('https://f-droid.org/en/packages/com.georgeyt9769.cardabase/'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            backgroundColor: Colors.transparent,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                            ),
                          ),
                          child: Text(
                            'F-Droid',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}