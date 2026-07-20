import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/pages/lock_screen.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  final _cardsBox = GetIt.I<LoyaltyCardsBox>();
  //final _settingsBox = GetIt.I<SettingsBox>();

  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _seedDatabase() async {
    await _cardsBox.clear();

    final now = DateTime.now().toUtc();
    final dummyCards = [
      LoyaltyCard(
        id: 'dummy-1',
        name: 'Supermarket',
        barcode: const Barcode(data: '978020137962', type: BarcodeType.CodeEAN13),
        color: Colors.blue,
        tags: {'Groceries'},
        notes: 'Main supermarket card',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 150,
        requiresAuth: false,
        hideName: false,
        createdAt: now,
        lastModifiedAt: now,
        usePoints: true,
      ),
      LoyaltyCard(
        id: 'dummy-2',
        name: 'Coffee Co.',
        barcode: const Barcode(data: 'COFFEE-99', type: BarcodeType.QrCode),
        color: Colors.brown,
        tags: {'Cafe', 'Daily'},
        notes: 'Free coffee every 10 visits',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 8,
        requiresAuth: false,
        hideName: false,
        createdAt: now,
        lastModifiedAt: now,
        usePoints: true,
      ),
      LoyaltyCard(
        id: 'dummy-3',
        name: 'Gym',
        barcode: const Barcode(data: 'GYM-101-202', type: BarcodeType.Code128),
        color: Colors.orange,
        tags: {'Fitness'},
        notes: 'Access card for the city gym',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 0,
        requiresAuth: true,
        hideName: false,
        createdAt: now,
        lastModifiedAt: now,
        usePoints: false,
      ),
      LoyaltyCard(
        id: 'dummy-4',
        name: 'Cinema Plus',
        barcode: const Barcode(data: 'CINEMA-123', type: BarcodeType.Code39),
        color: Colors.purple,
        tags: {'Entertainment'},
        notes: 'Discount on popcorn',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 50,
        requiresAuth: false,
        hideName: false,
        createdAt: now,
        lastModifiedAt: now,
        usePoints: true,
      ),
      LoyaltyCard(
        id: 'dummy-5',
        name: 'Pharmacy',
        barcode: const Barcode(data: 'PHARMA-987', type: BarcodeType.Itf),
        color: Colors.green,
        tags: {'Health'},
        notes: 'Prescription pickup card',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 200,
        requiresAuth: false,
        hideName: false,
        createdAt: now,
        lastModifiedAt: now,
        usePoints: true,
      ),
    ];

    for (final card in dummyCards) {
      await _cardsBox.put(card.id, card);
    }

    if (mounted) {
      setState(() {});
      showCustomSnackBar(context, 'Database wiped & seeded!', true);
    }
  }

  Future<void> _clearDatabase() async {
    await _cardsBox.clear();
    if (mounted) {
      setState(() {});
      showCustomSnackBar(context, 'Database cleared!', true);
    }
  }

  Future<void> _copyToClipboard() async {
    Clipboard.setData(
      ClipboardData(
        text: '[{"id":"202606191546400","barcode":{"data":"978020137964","type":"CodeEAN13"},"name":"CopyCard","createdAt":"2026-06-21T08:42:17.429Z","lastModifiedAt":"2026-06-21T08:42:17.429Z","color":"FFD5DA27","notes":"", "points": 10}]',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          _appBar(theme),
          SliverList(
            delegate: SliverChildListDelegate([
              _subtitle(theme, 'Insights'),
              _infoTile(
                theme,
                'Card Count',
                _cardsBox.length.toString(),
                Icons.analytics,
              ),
              _infoTile(
                theme,
                'App Version',
                _packageInfo?.version ?? 'Loading...',
                Icons.history,
              ),
              _infoTile(
                theme,
                'Build Number',
                _packageInfo?.buildNumber ?? 'Loading...',
                Icons.build,
              ),
              const SizedBox(height: 20),
              _subtitle(theme, 'Navigation'),
              SettingTile(
                settingHeader: 'Welcome Screen',
                aboutSettingHeader: 'Navigate to the app welcome screen',
                settingIcon: Icons.web_stories,
                settingAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(
                        currentAppVersion: 'DevMode',
                      ),
                    ),
                  );
                },
                iconColor: theme.colorScheme.tertiary,
                borderColor: theme.colorScheme.primary,
                showMore: true,
              ),
              SettingTile(
                settingHeader: 'Lock Screen',
                aboutSettingHeader: 'Open the password lock screen',
                settingIcon: Icons.lock,
                settingAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LockScreen(),
                    ),
                  );
                },
                iconColor: theme.colorScheme.tertiary,
                borderColor: theme.colorScheme.primary,
                showMore: true,
              ),
              const SizedBox(height: 20),
              _subtitle(theme, 'Database Tools'),
              SettingTile(
                settingHeader: 'Seed Database',
                aboutSettingHeader: 'Populate the app with preset dummy cards',
                settingIcon: Icons.library_add,
                settingAction: _seedDatabase,
                iconColor: Colors.green,
                borderColor: theme.colorScheme.primary,
              ),
              SettingTile(
                settingHeader: 'Clear Database',
                aboutSettingHeader: 'Remove all cards from storage',
                settingIcon: Icons.delete_sweep,
                settingAction: _clearDatabase,
                iconColor: Colors.red,
                borderColor: Colors.red,
                textColor: Colors.red,
              ),
              SettingTile(
                settingHeader: 'Copy fake card',
                aboutSettingHeader: 'Copy fake card to clipboard',
                settingIcon: Icons.copy,
                settingAction: _copyToClipboard,
                iconColor: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _appBar(ThemeData theme) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      title: Text(
        'Dev Tools',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
      floating: true,
      snap: true,
    );
  }

  Widget _subtitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, bottom: 5),
      child: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 23,
          color: theme.colorScheme.inverseSurface,
        ),
      ),
    );
  }

  Widget _infoTile(ThemeData theme, String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.tertiary),
            const SizedBox(width: 15),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
