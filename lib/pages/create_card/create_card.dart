import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/pages/create_card/barcode_type_selector_dialog.dart';
import 'package:cardabase/pages/create_card/error_snack_bar.dart';
import 'package:cardabase/pages/create_card/form_fields/barcode_type_selector_button.dart';
import 'package:cardabase/pages/create_card/form_fields/card_data_form_field.dart';
import 'package:cardabase/pages/create_card/form_fields/card_name_form_field.dart';
import 'package:cardabase/pages/create_card/form_fields/color_picker_button.dart';
import 'package:cardabase/pages/create_card/form_fields/notes_form_field.dart';
import 'package:cardabase/pages/create_card/form_fields/points_form_field.dart';
import 'package:cardabase/pages/create_card/form_fields/save_button.dart';
import 'package:cardabase/pages/create_card/form_fields/take_picture_button.dart';
import 'package:cardabase/pages/create_card/verify_code.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/color_picker_dialog.dart';
import 'package:cardabase/util/widgets/multi_listenable_builder.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class CreateCard extends StatefulWidget {
  const CreateCard({super.key});

  @override
  State<CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<CreateCard>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final settingsBox = Hive.box('settingsBox');
  final passwordBox = Hive.box('password');
  final CardabaseDb cdb = CardabaseDb();

  final cardName = TextEditingController(text: 'Card');
  final cardData = TextEditingController();
  final notes = TextEditingController();
  final points = ValueNotifier<int>(0);
  final frontImagePath = ValueNotifier<String?>(null);
  final backImagePath = ValueNotifier<String?>(null);
  final cardColor = ValueNotifier<Color>(Colors.grey);
  final barcodeType = ValueNotifier<BarcodeType>(BarcodeType.CodeEAN13);
  final hasPassword = ValueNotifier<bool>(false);
  final useFrontFaceOverlay = ValueNotifier<bool>(false);
  final hideTitle = ValueNotifier<bool>(false);

  final Set<String> selectedTags = {};

  late final allTags =
      settingsBox.get('tags', defaultValue: []) as List<dynamic>;

  Color getContrastingTextColor(Color bg) {
    return bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;
  }

  Future<void> _showColorPickerDialog() async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        cardColor: cardColor.value,
      ),
    );
    if (selectedColor is Color) {
      cardColor.value = selectedColor;
    }
  }

  Future<void> _scanCard() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRBarReader(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final code = result['code'] as String;
    final format = result['format'].toString();
    if (code == '-1') {
      setState(() => cardData.text = '');
      return;
    }

    cardData.text = code;

    barcodeType.value = switch (format) {
      'BarcodeFormat.code39' => BarcodeType.Code39,
      'BarcodeFormat.code93' => BarcodeType.Code93,
      'BarcodeFormat.code128' => BarcodeType.Code128,
      'BarcodeFormat.ean13' => BarcodeType.CodeEAN13,
      'BarcodeFormat.ean8' => BarcodeType.CodeEAN8,
      'BarcodeFormat.upcA' => BarcodeType.CodeUPCA,
      'BarcodeFormat.upcE' => BarcodeType.CodeUPCE,
      'BarcodeFormat.codabar' => BarcodeType.Codabar,
      'BarcodeFormat.qrcode' => BarcodeType.QrCode,
      'BarcodeFormat.dataMatrix' => BarcodeType.DataMatrix,
      'BarcodeFormat.aztec' => BarcodeType.Aztec,
      // for now default to ean13. Once the QRBarReader returns type safe data, remove this
      _ => BarcodeType.CodeEAN13,
    };

    if (code.startsWith('[') && code.endsWith(']')) {
      final List<String> rawList =
          code.replaceAll('[', '').replaceAll(']', '').split(', ');

      final String name = rawList[0];
      final String number = rawList[1];
      final int red = int.parse(rawList[2]);
      final int green = int.parse(rawList[3]);
      final int blue = int.parse(rawList[4]);
      final String cardType = rawList[5];
      final bool hasPwd = rawList[6] == 'true';

      cardName.text = name;
      cardColor.value = Color.fromARGB(255, red, green, blue);
      cardData.text = number;
      barcodeType.value = parseBarcodeTypeStringFromDb(cardType);
      hasPassword.value = hasPwd;
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      showValidationError();
      return;
    }
    final now = DateTime.now();
    final uniqueId =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final cardColor = this.cardColor.value;
    cdb.myShops.add({
      'cardName': cardName.text,
      'cardId': cardData.text,
      'redValue': (cardColor.r * 255).round(),
      'greenValue': (cardColor.g * 255).round(),
      'blueValue': (cardColor.b * 255).round(),
      'cardType': barcodeType.value.getDbStringValue(),
      'hasPassword': hasPassword.value,
      'uniqueId': uniqueId,
      'tags': selectedTags.toList(),
      'note': notes.text,
      'imagePathFront': frontImagePath.value,
      'imagePathBack': backImagePath.value,
      'useFrontFaceOverlay': useFrontFaceOverlay.value,
      'hideTitle': hideTitle.value,
      'pointsAmount': points.value,
    });
    cdb.updateDataBase();
    Navigator.pop(context);
  }

  void showValidationError() {
    // TODO(wim): why do we vibrate success while there is an error?
    VibrationProvider.vibrateSuccess();

    if (cardName.text.isEmpty == true) {
      showErrorSnackBar(context, 'Card Name cannot be empty!');
    } else if (cardData.text.isEmpty == true) {
      showErrorSnackBar(context, 'Card ID cannot be empty!');
    } else if (validBarcode(barcodeType.value)(cardData.text) != null) {
      showErrorSnackBar(context, 'Card ID contains a mistake!');
    } else {
      showErrorSnackBar(context, 'Unknown error');
    }
  }

  void _addLegacyCard() {
    cdb.myShops.add([
      'Legacy Card',
      '9780201379624',
      158,
      158,
      158,
      'CardType.ean13',
      false,
    ]);
    setState(() {});
    cdb.updateDataBase();
    Navigator.pop(context);
  }

  Future<void> _showBarcodeSelectorDialog() async {
    final BarcodeType? result = await showDialog<BarcodeType>(
      context: context,
      builder: (context) => BarcodeTypeSelectorDialog(
        allowedTypes: [
          BarcodeType.Code39,
          BarcodeType.Code93,
          BarcodeType.Code128,
          BarcodeType.CodeEAN13,
          BarcodeType.CodeEAN8,
          BarcodeType.CodeEAN5,
          BarcodeType.CodeEAN2,
          BarcodeType.Itf,
          BarcodeType.CodeITF14,
          BarcodeType.CodeITF16,
          BarcodeType.CodeUPCA,
          BarcodeType.CodeUPCE,
          BarcodeType.Codabar,
          BarcodeType.QrCode,
          BarcodeType.DataMatrix,
          BarcodeType.Aztec,
        ],
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    barcodeType.value = result;
  }

  Future<void> _scanSharedCode() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const QRBarReader()),
    );

    if (result == null || !mounted) {
      return;
    }

    final code = result['code'] as String;
    if (code == '-1') {
      return;
    }

    // TODO(wim): why use custom sharing protocol? Use json instead.
    final List<String> rawList =
        code.replaceAll('[', '').replaceAll(']', '').split(', ');
    // Convert values into correct types
    final String name = rawList[0];
    final String number = rawList[1];
    final int red = int.parse(rawList[2]);
    final int green = int.parse(rawList[3]);
    final int blue = int.parse(rawList[4]);
    final String cardType = rawList[5];
    final bool hasPwd = rawList[6] == 'true';

    cardName.text = name;
    cardColor.value = Color.fromARGB(255, red, green, blue);
    cardData.text = number;
    barcodeType.value = parseBarcodeTypeStringFromDb(cardType);
    hasPassword.value = hasPwd;
  }

  @override
  void initState() {
    cdb.loadData();
    super.initState();
  }

  @override
  void dispose() {
    cardName.dispose();
    cardData.dispose();
    notes.dispose();
    points.dispose();
    frontImagePath.dispose();
    backImagePath.dispose();
    cardColor.dispose();
    barcodeType.dispose();
    hasPassword.dispose();
    useFrontFaceOverlay.dispose();
    hideTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _appBar(theme),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          children: [
            SizedBox(
              // TODO(wim): migrate this to LayoutBuilder
              height: MediaQuery.of(context).size.width / 1.586,
              width: MediaQuery.of(context).size.width,
              child: _card(theme),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Card Details'),
                      Tab(text: 'Others'),
                    ],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  SizedBox(
                    height: 1000,
                    child: TabBarView(
                      children: [
                        _cardDetails(theme),
                        _other(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SaveButton(onPressed: _save),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  AppBar _appBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.qr_code_2,
          color: theme.colorScheme.secondary,
        ),
        onPressed: _scanSharedCode,
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: settingsBox.listenable(),
          builder: (context, settingsBox, _) {
            // TODO(wim): wrap this to make it type-safe
            final showLegacyCardButton = settingsBox.get(
              'developerOptions',
              defaultValue: false,
            ) as bool;
            return showLegacyCardButton
                ? IconButton(
                    icon: Icon(
                      Icons.credit_card_off,
                      color: theme.colorScheme.secondary,
                    ),
                    onPressed: _addLegacyCard,
                  )
                : const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      title: Text(
        'New card',
        style: theme.textTheme.titleLarge?.copyWith(),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
    );
  }

  Widget _card(ThemeData theme) {
    return MultiListenableBuilder(
      listenables: [
        useFrontFaceOverlay,
        frontImagePath,
        cardName,
        cardColor,
        hideTitle,
      ],
      builder: (context) {
        final path = frontImagePath.value;
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor.value,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              if (useFrontFaceOverlay.value && path != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              if (!hideTitle.value)
                Center(
                  child: Wrap(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          cardName.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: getContrastingTextColor(cardColor.value),
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CardNameFormField(controller: cardName),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: barcodeType,
            builder: (context, barcodeType, _) => CardDataFormField(
              controller: cardData,
              barcodeType: barcodeType,
              onScanButtonPressed: _scanCard,
            ),
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: barcodeType,
            builder: (context, barcodeType, _) => BarcodeTypeSelectorButton(
              barcodeType: barcodeType,
              onPressed: _showBarcodeSelectorDialog,
            ),
          ),
          const SizedBox(height: 15),
          ColorPickerButton(onPressed: _showColorPickerDialog),
          const SizedBox(height: 15),
          PointsFormField(controller: points),
          const SizedBox(height: 15),
          NotesFormField(controller: notes),
        ],
      ),
    );
  }

  Widget _other(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (allTags.isEmpty)
            const SizedBox.shrink()
          else
            Row(
              children: [
                Text(
                  'Tags:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.inverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        decelerationRate: ScrollDecelerationRate.fast,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: allTags.length,
                      itemBuilder: (context, chipIndex) {
                        final tag = allTags[chipIndex] as String;
                        final isSelected = selectedTags.contains(tag);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: ActionChip(
                            label: Text(tag),
                            onPressed: () {
                              setState(() {
                                if (isSelected) {
                                  selectedTags.remove(tag);
                                } else {
                                  selectedTags.add(tag);
                                }
                              });
                            },
                            labelStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.inverseSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            avatar: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: theme.colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 15),
          TakePictureButton(
            picturePath: frontImagePath,
            label: Text(
              'Front face picture',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.inverseSurface,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TakePictureButton(
            picturePath: backImagePath,
            label: Text(
              'Back face picture',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.inverseSurface,
              ),
            ),
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: useFrontFaceOverlay,
            builder: (context, value, _) => CheckboxListTile(
              value: value,
              title: Text(
                'Use front face picture as a card thumbnail',
                style: theme.textTheme.bodyLarge?.copyWith(
                  //cardTypeText
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.inverseSurface,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              side: BorderSide(
                color: theme.colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (checked) =>
                  useFrontFaceOverlay.value = checked ?? false,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: hideTitle,
            builder: (context, value, _) => CheckboxListTile(
              value: value,
              title: Text(
                'Hide card title',
                style: theme.textTheme.bodyLarge?.copyWith(
                  //cardTypeText
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.inverseSurface,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              side: BorderSide(
                color: theme.colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (checked) => hideTitle.value = checked ?? false,
            ),
          ),
          if (passwordBox.isNotEmpty)
            ValueListenableBuilder(
              valueListenable: hasPassword,
              builder: (context, value, _) => CheckboxListTile(
                value: value,
                title: Text(
                  'Use the password for this card',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    //cardTypeText
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.inverseSurface,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                side: BorderSide(
                  color: theme.colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (checked) => hasPassword.value = checked ?? false,
              ),
            )
          else
            const SizedBox(height: 10),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
