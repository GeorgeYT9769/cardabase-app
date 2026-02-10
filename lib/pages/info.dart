import 'dart:convert';

import 'package:cardabase/pages/news.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String _appVersion = 'Loading...';
  String? _latestGitHubVersion;
  bool _isLoading = true;
  bool _hasError = false;
  bool? _isUpdateAvailable;

  final String _githubApiUrl =
      'https://api.github.com/repos/GeorgeYT9769/cardabase-app/releases/latest';
  final String _githubReleasesUrl =
      'https://github.com/GeorgeYT9769/cardabase-app/releases/latest';

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
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version; //"1.1.0" packageInfo.version

      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String githubTag = data['tag_name'] ?? '';

        _latestGitHubVersion =
            githubTag.startsWith('v') ? githubTag.substring(1) : githubTag;

        final List<int> localParts =
            _appVersion.split('.').map(int.parse).toList();
        final List<int> githubParts =
            _latestGitHubVersion!.split('.').map(int.parse).toList();

        _isUpdateAvailable = false;

        for (int i = 0; i < localParts.length && i < githubParts.length; i++) {
          if (githubParts[i] > localParts[i]) {
            _isUpdateAvailable = true;
            break;
          } else if (localParts[i] > githubParts[i]) {
            _isUpdateAvailable = false;
            break;
          }
        }

        if (!(_isUpdateAvailable ?? false) &&
            githubParts.length > localParts.length) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Info',
          style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.tertiary,
              ) ??
              const TextStyle(
                color: Colors.black,
              ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/ic_launcher_foreground.png',
                height: MediaQuery.of(context).size.width / 2,
                width: MediaQuery.of(context).size.width / 2,
              ),
              const SizedBox(height: 30),
              Text(
                'Cardabase App',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Version: $_appVersion',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'Developed by Juraj Ondovčík',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewsPage(),
                    ),
                  );
                },
                child: Text(
                  'See Changelog',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                _hasError
                    ? Column(
                        children: [
                          Text(
                            'Failed to check for updates. Please check your internet connection and try again.',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _fetchAppAndLatestVersion,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              backgroundColor: Colors.transparent,
                              elevation: 0.0,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
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
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _isUpdateAvailable!
                                  ? Colors.green
                                  : theme.colorScheme.onSurface,
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
                                  onPressed: () =>
                                      _launchUrl(_githubReleasesUrl),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    elevation: 0.0,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'GitHub',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 18,
                                      color: theme.colorScheme.primary,
                                    ),
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
                                  onPressed: () => _launchUrl(
                                    'https://f-droid.org/en/packages/com.georgeyt9769.cardabase/',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    elevation: 0.0,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'F-Droid',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 18,
                                      color: theme.colorScheme.primary,
                                    ),
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
