import 'dart:io';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_summary.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../test_helpers/get_it.dart';
import '../test_helpers/mocks/plugins/clipboard.dart';
import '../test_helpers/mocks/plugins/haptic_feedback.dart';
import '../test_helpers/mocks/plugins/path_provider.dart';
import '../test_helpers/mocks/plugins/permissions.dart';
import '../test_helpers/mocks/plugins/quick_actions.dart';
import '../test_helpers/mocks/plugins/receive_sharing_intent.dart';
import '../test_helpers/mocks/plugins/screen_brightness.dart';

const String testAppVersion = '1.8.0';

/// Whether the dependencies were registered already.
///
/// There is one get_it for the whole test process, so a suite which pulls
/// several test files into a single `main` (see `integration_test.dart`) asks
/// for this once per file. The first registration is the one which counts.
bool _dependenciesRegistered = false;

void registerTestDependencies() {
  if (_dependenciesRegistered) {
    return;
  }
  _dependenciesRegistered = true;

  PackageInfo.setMockInitialValues(
    appName: 'Cardabase',
    packageName: 'com.georgeyt9769.cardabase',
    version: testAppVersion,
    buildNumber: '1',
    buildSignature: '',
  );

  registerDependencies();
  GetIt.I.registerSingleton(
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
  );

  GetIt.I.registerLazySingletonAsync(
    () => Directory.systemTemp.createTemp('cardabase-test-storage-'),
    instanceName: TestGetItInstanceNames.storageDirectory.value,
  );
  GetIt.I
    ..registerMockHapticFeedback()
    ..registerMockQuickActions()
    ..registerMockScreenBrightness()
    ..registerMockSharingIntent()
    ..registerMockPermissions()
    ..registerMockClipboard()
    ..registerMockPathProvider();
}

const String _testScopeName = 'test-scope';

/// Registers what every integration test file needs: the dependencies, the
/// mocked plugins, the boxes, and a get_it scope per test.
///
/// A file which is run on its own registers these once. A suite which pulls
/// several files into a single `main` registers them once per file and runs all
/// of them for every test, so each of them has to be able to run again without
/// undoing what the one before it did.
void useApp() {
  setUpAll(registerTestDependencies);

  setUp(() async {
    pushTestScope();
    await initializePlugins();
    await initializeHiveBoxes();
  });

  tearDown(() async {
    await clearHiveBoxes();
    popTestScope();
  });
}

/// Pushes the scope a test runs in, so whatever the app registers while it runs
/// is gone again afterwards. Does nothing when the scope is already there.
void pushTestScope() {
  if (GetIt.I.currentScopeName == _testScopeName) {
    return;
  }
  GetIt.I.pushNewScope(scopeName: _testScopeName);
}

/// Drops the scope [pushTestScope] pushed, if it is still the one on top.
void popTestScope() {
  if (GetIt.I.currentScopeName != _testScopeName) {
    return;
  }
  GetIt.I.popScope();
}

// initializePlugins gets all mocked plugins from GetIt so that they are
// initialized and wired up.
Future<void> initializePlugins() {
  GetIt.I<MockHapticFeedbackPlatform>();
  GetIt.I<MockQuickActionsPlatform>();
  GetIt.I<MockScreenBrightnessPlatform>();
  GetIt.I<MockSharingIntentPlatform>();
  GetIt.I<MockPermissionsPlatform>();
  GetIt.I<MockClipboardPlatform>();
  return GetIt.I.getAsync<MockPathProviderPlatform>();
}

Future<void> initializeHiveBoxes() async {
  await Future.wait([
    GetIt.I.getAsync<LoyaltyCardsBox>(),
    GetIt.I.getAsync<SettingsBox>(),
    GetIt.I.getAsync<Box>(instanceName: 'passwordBox'),
  ]);
}

// clearHiveBoxes empties the boxes again, so a test starts from the database it
// arranges itself rather than from what the test before it left behind.
Future<void> clearHiveBoxes() async {
  await Future.wait([
    GetIt.I.getAsync<LoyaltyCardsBox>().then((box) => box.clear()),
    GetIt.I.getAsync<SettingsBox>().then((box) => box.clear()),
    GetIt.I
        .getAsync<Box>(instanceName: 'passwordBox')
        .then((box) => box.clear()),
  ]);
}

/// Sizes the surface like a phone, so the tests see what a user sees: on the
/// default 800x600 test surface the cards are wider and fewer of them fit, and
/// what a test reaches for can sit off screen.
void usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Builds the app again over the database it left behind, the way a user comes
/// back to it later.
///
/// The tree is emptied first: pumping another [Main] over the one which is
/// there hands the state it already has to the new widget, which is not what a
/// user coming back to the app gets.
Future<void> restart(WidgetTester tester, Widget initialScreen) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(Main(initialScreen: initialScreen));
  await tester.pumpAndSettle();
}

/// Opens the menu of a card, the one a long press brings up.
Future<void> openCardMenu(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
}

/// The field which carries [label], whether that is its label or its hint.
///
/// The label sits next to the text being edited rather than around it, so the
/// field is found through the [TextField] which holds both.
Finder fieldWithLabel(String label) {
  return find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(TextField)),
    matching: find.byType(EditableText),
  );
}

/// What is in the field which carries [label].
String fieldText(WidgetTester tester, String label) {
  return tester.widget<EditableText>(fieldWithLabel(label)).controller.text;
}

/// The ids of the cards on screen, in the order they are shown in.
///
/// The order of the cards is a view concern: the box hands them out in the
/// order they were written, and the view options decide how they are shown.
List<String> shownCardIds(WidgetTester tester) {
  return tester
      .widgetList<CardSummary>(find.byType(CardSummary))
      .map((summary) => summary.cardId)
      .toList(growable: false);
}

/// The text of the snack bar which is on screen, if there is one.
String? snackBarText(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data)
      .whereType<String>();
  return texts.isEmpty ? null : texts.join();
}

extension WidgetTesterExtensions on WidgetTester {
  Future<void> scrollTo(
    Finder finder, {
    Finder? scrollable,
  }) async {
    final list = scrollable ?? find.byType(Scrollable).first;

    // back to the top first: `scrollUntilVisible` only ever scrolls one way, and
    // a list which is already past what the test is looking for would scroll
    // away from it forever.
    final position = state<ScrollableState>(list).position;
    if (position.pixels != position.minScrollExtent) {
      position.jumpTo(position.minScrollExtent);
      await pumpAndSettle();
    }

    try {
      await scrollUntilVisible(finder, 200, scrollable: list);
    } on StateError {
      // `scrollUntilVisible` gives up with a bare "Bad state: No element", which
      // says nothing about what was being looked for.
      fail('scrolled the whole list without finding $finder');
    }
    await ensureVisible(finder);
    await pumpAndSettle();
  }

  Future<void> scrollToAndTap(Finder finder) async {
    await scrollTo(finder);
    await tap(finder);
  }
}
