import 'dart:convert';

import 'package:cardabase/pages/news.dart';
import 'package:cardabase/util/expressive_loading_indicator.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:http/http.dart' as http;
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}
class _InfoScreenState extends State<InfoScreen> {
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  String _buildSignature = '';
  String _installerStore = '';
  String? _installTime = '';
  String? _lastUpdate = '';
  String _packageName = '';
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
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _buildSignature = packageInfo.buildSignature;
      _installTime = _formatDate(packageInfo.installTime);
      _lastUpdate = _formatDate(packageInfo.updateTime);
      _packageName = packageInfo.packageName;

      try {
        _installerStore = packageInfo.installerStore ?? 'Unknown';
      } catch (_) {}

      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>? ?? {};
        final String githubTag = data['tag_name'] as String? ?? '';

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

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String h = date.hour.toString().padLeft(2, '0');
    final String m = date.minute.toString().padLeft(2, '0');
    final String s = date.second.toString().padLeft(2, '0');
    final String ms = date.millisecond.toString().padLeft(3, '0');
    return '$day.$month.$year $h:$m:$s:$ms';
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Could not launch $url', false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
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
            floating: true,
            pinned: false,
          ),
          SliverToBoxAdapter(
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
                ExpressiveLoadingIndicator(
                  color: Theme.of(context).colorScheme.tertiary,
                  constraints: const BoxConstraints(
                    minWidth: 64.0,
                    minHeight: 64.0,
                    maxWidth: 64.0,
                    maxHeight: 64.0,
                  ),
                  polygons: [
                    MaterialShapes.softBurst,
                    MaterialShapes.pentagon,
                    MaterialShapes.pill,
                  ],
                  semanticsLabel: 'Loading',
                  semanticsValue: 'In progress',
                )
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
                          Bounceable(
                            onTap: () {},
                            child: OutlinedButton.icon(
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
              _buildAppInfoArea(theme),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoArea(ThemeData theme) {
    if (_appVersion.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'App Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _infoRow(theme, 'Version', _appVersion),
          _infoRow(theme, 'Build Number', _buildNumber),
          _infoRow(
            theme,
            'Package Name',
            _buildSignature.isEmpty ? 'Unknown' : _packageName,
            displayValue: _buildSignature.isEmpty ? 'Unknown' : 'TAP TO SHOW',
          ),
          _infoRow(
            theme,
            'Build Signature',
            _buildSignature.isEmpty ? 'Unknown' : _buildSignature,
            displayValue: _buildSignature.isEmpty ? 'Unknown' : 'TAP TO SHOW',
          ),
          _infoRow(theme, 'Installer Store', _installerStore.isEmpty ? 'Unknown' : _installerStore),
          _infoRow(theme, 'Install Time', _installTime ?? 'Unknown'),
          _infoRow(theme, 'Last Update', _lastUpdate ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value, {String? displayValue}) {
    if (value.isEmpty || value == 'Unknown') {
      if (displayValue == null || displayValue.isEmpty || displayValue == 'Unknown') {
          // just let it show 'Unknown' or hide it, actually wait, the original code doesn't hide "Unknown"
      }
    }
    if (value.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label),
            content: SingleChildScrollView(
              child: SelectableText(value),
            ),
            actions: <Widget>[
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    elevation: 0.0,
                    side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                displayValue ?? value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
