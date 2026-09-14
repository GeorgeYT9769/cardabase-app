import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/main.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../../test_helpers/fakers/settings.dart';
import '../../../test_helpers/mocks/plugins/clipboard.dart';
import '../../app_harness.dart';

/// What the app last copied to the clipboard, as the fake platform saw it.
String? get clipboardText => GetIt.I<MockClipboardPlatform>().clipboardText;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final validEan13 = faker.loyaltyCards.codeEAN13();
  final otherValidEan13 = faker.loyaltyCards.codeEAN13();

  useApp();

  group('the settings', () {
    Future<void> tapSetting(WidgetTester tester, String setting) async {
      await tester.scrollUntilVisible(find.text(setting), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text(setting));
      await tester.pumpAndSettle();
    }

    Future<void> openSetting(WidgetTester tester, String setting) async {
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tapSetting(tester, setting);
    }

    /// Opens the backup half of the import/export page, which is the tab it
    /// opens on.
    Future<void> openExport(WidgetTester tester) async {
      await openSetting(tester, 'Backup/Restore');
    }

    /// Opens the restore half of the same page.
    Future<void> openImport(WidgetTester tester) async {
      await openSetting(tester, 'Backup/Restore');
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();
    }

    /// Leaves a settings page which is a screen of its own, back to the list
    /// of settings.
    Future<void> goBack(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();
    }

    testWidgets('open from the cards and close again', (tester) async {
      // ARRANGE
      usePhoneView(tester);

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();
      expect(find.text('Cardabase'), findsOneWidget);
    });

    testWidgets('exporting copies the cards to the clipboard', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await openExport(tester);
      await tester.tap(find.text('CLIPBOARD'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(clipboardText, contains('"name":"Delhaize"'));
      expect(clipboardText, contains(validEan13));
    });

    testWidgets('importing adds the cards of a backup', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final backup = [
        faker.loyaltyCards.simpleCard().copyWith(
              name: 'Delhaize',
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
      ].serializeToJson();

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await openImport(tester);
      await tester.enterText(find.byType(TextField).last, backup);
      await tester.pumpAndSettle();
      await tester.tap(find.text('IMPORT FROM TEXT'));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(loyaltyCardsBox.values.map((card) => card.name), ['Delhaize']);
      expect(
        find.text('Delhaize'),
        findsOneWidget,
        reason: 'the cards should be shown after the import',
      );
    });

    testWidgets('an export can be imported again', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({
        'delhaize': faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
        'colruyt': faker.loyaltyCards.simpleCard().copyWith(
              id: 'colruyt',
              name: 'Colruyt',
              barcode:
                  Barcode(data: otherValidEan13, type: BarcodeType.CodeEAN13),
            ),
      });
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT back it up,
      await openExport(tester);
      await tester.tap(find.text('CLIPBOARD'));
      await tester.pumpAndSettle();
      final backup = clipboardText!;
      await goBack(tester);

      // lose the cards -- clearing them closes the settings again,
      await tapSetting(tester, 'Delete Cardabase');
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();
      expect(loyaltyCardsBox.values, isEmpty);
      expect(find.text('There is nothing to see...'), findsOneWidget);

      // and put them back.
      await openImport(tester);
      await tester.enterText(find.byType(TextField).last, backup);
      await tester.pumpAndSettle();
      await tester.tap(find.text('IMPORT FROM TEXT'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        loyaltyCardsBox.values.map((card) => card.name),
        containsAll(['Delhaize', 'Colruyt']),
      );
    });

    testWidgets('adding a tag makes it available on a card', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await openSetting(tester, 'Tags');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'groceries');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // ASSERT
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      expect(settingsBox.value.tags, contains('groceries'));
    });

    testWidgets('switching the theme is remembered', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(faker.settings.settings());
      expect(settingsBox.value.theme.useDarkMode, isFalse);

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tapSetting(tester, 'Switch Themes');

      // ASSERT
      expect(settingsBox.value.theme.useDarkMode, isTrue);
    });
  });

  group('the tags', () {
    testWidgets('a tag added in the settings can be put on a card',
        (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              tags: const {},
            ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT the tag is made in the settings,
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Tags'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'groceries');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // ASSERT the tag is kept,
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      expect(settingsBox.value.tags, contains('groceries'));

      // and is offered on the form of a card the next time the app opens.
      await restart(tester, Homepage());
      await tester.longPress(find.text('Delhaize'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      // the tags of a card live on the second tab of the form.
      await tester.tap(find.text('Others'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'groceries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(loyaltyCardsBox.get('delhaize')?.tags, contains('groceries'));
    });

    testWidgets('the card list can be filtered down to one tag',
        (tester) async {
      // ARRANGE a tagged card and an untagged one, with the tag known to the
      // settings so the filter offers it.
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({
        'delhaize': faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              tags: const {'groceries'},
            ),
        'mediamarkt': faker.loyaltyCards.simpleCard().copyWith(
              id: 'mediamarkt',
              name: 'MediaMarkt',
              tags: const {},
            ),
      });
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(faker.settings.settings(tags: ['groceries']));
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      expect(find.text('MediaMarkt'), findsOneWidget);

      // ACT the tag filter lives in the sort dialog, which the search row
      // opens.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tags:'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'groceries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SELECT'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delhaize'), findsOneWidget);
      expect(find.text('MediaMarkt'), findsNothing);
    });
  });

  group('the password gate', () {
    /// The field of the password dialog, which is the only one it shows.
    final passwordField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(EditableText),
    );

    /// Starts the app of a user who has a password, on the settings.
    Future<void> openSettingsWithPassword(WidgetTester tester) async {
      usePhoneView(tester);
      final passwordBox =
          await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
      await passwordBox.put('PW', 'letmein');
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
    }

    testWidgets('a backup is only made after the password is given',
        (tester) async {
      // ARRANGE
      await openSettingsWithPassword(tester);

      // ACT
      await tester.scrollUntilVisible(find.text('Backup/Restore'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup/Restore'));
      await tester.pumpAndSettle();

      // ASSERT the page stays behind the dialog until the password is in.
      expect(find.text('Enter Password'), findsOneWidget);
      expect(find.text('CLIPBOARD'), findsNothing);

      await tester.enterText(passwordField, 'letmein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('AUTHORIZE'));
      await tester.pumpAndSettle();

      expect(find.text('CLIPBOARD'), findsOneWidget);
    });

    testWidgets('a wrong password does not open the backup', (tester) async {
      // ARRANGE
      await openSettingsWithPassword(tester);
      await tester.scrollUntilVisible(find.text('Backup/Restore'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup/Restore'));
      await tester.pumpAndSettle();

      // ACT
      await tester.enterText(passwordField, 'not the password');
      await tester.pumpAndSettle();
      await tester.tap(find.text('AUTHORIZE'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(snackBarText(tester), 'Incorrect password!');
      expect(find.text('Enter Password'), findsOneWidget);
      expect(find.text('CLIPBOARD'), findsNothing);
    });

    testWidgets('the cards are only cleared after the password is given',
        (tester) async {
      // ARRANGE
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );
      await openSettingsWithPassword(tester);

      // ACT
      await tester.scrollUntilVisible(find.text('Delete Cardabase'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Cardabase'));
      await tester.pumpAndSettle();

      // ASSERT the dialog which asks to delete is not even reached.
      expect(find.text('Enter Password'), findsOneWidget);
      expect(loyaltyCardsBox.values, hasLength(1));

      await tester.enterText(passwordField, 'letmein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('AUTHORIZE'));
      await tester.pumpAndSettle();

      expect(find.text('DELETE'), findsWidgets);
    });
  });

  group('the password itself', () {
    /// Opens Settings -> Password, which is where a password is made.
    Future<void> openPasswordScreen(WidgetTester tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Password'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Password'));
      await tester.pumpAndSettle();
    }

    testWidgets('a password set here is the one the app asks for',
        (tester) async {
      // ARRANGE
      await openPasswordScreen(tester);
      expect(find.text('CREATE A PASSWORD'), findsOneWidget);

      // ACT the password and its confirmation are the only two fields.
      await tester.enterText(find.byType(TextFormField).first, 'letmein');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'letmein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SET'));
      await tester.pumpAndSettle();

      // ASSERT it is stored,
      final passwordBox =
          await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
      expect(passwordBox.get('PW'), 'letmein');

      // and the settings which are behind it now ask for it.
      await tester.scrollUntilVisible(find.text('Delete Cardabase'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Cardabase'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Password'), findsOneWidget);
    });

    testWidgets('a password is not set when the two do not match',
        (tester) async {
      // ARRANGE
      await openPasswordScreen(tester);

      // ACT
      await tester.enterText(find.byType(TextFormField).first, 'letmein');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'let me in');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SET'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(snackBarText(tester), 'Passwords do not match!');
      final passwordBox =
          await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
      expect(passwordBox.get('PW'), isNull);
    });

    testWidgets('a password which is set can be taken away again',
        (tester) async {
      // ARRANGE a user who already has one: the screen offers a reset instead.
      final passwordBox =
          await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
      await passwordBox.put('PW', 'letmein');
      await openPasswordScreen(tester);
      expect(find.text('RESET PASSWORD'), findsOneWidget);

      // ACT
      await tester.enterText(find.byType(TextFormField).first, 'letmein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(passwordBox.get('PW'), isNull);
    });
  });
}
