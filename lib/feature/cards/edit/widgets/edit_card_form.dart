import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/cards/card_face_error_widget.dart';
import 'package:cardabase/feature/cards/edit/editable_loyalty_card.dart';
import 'package:cardabase/feature/cards/edit/widgets/barcode_type_selector_dialog.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/barcode_type_selector_button.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/card_data_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/card_name_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/color_picker_button.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/notes_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/points_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/take_picture_button.dart'
    show TakePictureButton;
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:cardabase/util/widgets/color_picker_dialog.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:cardabase/util/widgets/multi_listenable_builder.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';

class EditCardForm extends StatefulWidget {
  const EditCardForm({
    super.key,
    required this.formKey,
    required this.card,
  });

  final Key formKey;
  final EditableLoyaltyCard card;

  @override
  State<EditCardForm> createState() => _EditCardFormState();
}

class _EditCardFormState extends State<EditCardForm> {
  final passwordBox = Hive.box('password');

  Color get textColor {
    final bg = widget.card.color.value;
    if (bg == null) {
      return Colors.white;
    }
    return bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;
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
      widget.card.barcode.data.text = '';
      return;
    }

    widget.card.barcode.data.text = code;

    widget.card.barcode.type.value = switch (format) {
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

    late final LoyaltyCard? sharedCard;
    if (code.startsWith('[') && code.endsWith(']')) {
      try {
        sharedCard = LoyaltyCard.fromLegacySharing(code);
      } on FormatException {
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar(
            'Scanned code is not a valid Cardabase share code.',
            false,
          ),
        );
      }
    } else if (code.startsWith('{')) {
      try {
        sharedCard = LoyaltyCard.fromLegacySharing(code);
      } on FormatException {
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar(
            'Scanned code is not a valid Cardabase share code.',
            false,
          ),
        );
      }
    } else {
      sharedCard = null;
    }

    if (sharedCard != null) {
      widget.card.name.text = sharedCard.name;
      widget.card.color.value = sharedCard.color;
      widget.card.barcode.data.text = sharedCard.barcode.data;
      widget.card.barcode.type.value = sharedCard.barcode.type;
      widget.card.requiresAuth.value = sharedCard.requiresAuth;
    }
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

    widget.card.barcode.type.value = result;
  }

  Future<void> _showColorPickerDialog() async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        cardColor: widget.card.color.value ?? Colors.grey,
      ),
    );
    if (selectedColor is Color) {
      widget.card.color.value = selectedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: widget.formKey,
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
    );
  }

  Widget _card(ThemeData theme) {
    return MultiListenableBuilder(
      listenables: [
        widget.card.useFrontImageOverlay,
        widget.card.frontImagePath,
        widget.card.name,
        widget.card.color,
        widget.card.hideName,
      ],
      builder: (context) {
        final path = widget.card.frontImagePath.value;
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.card.color.value ?? Colors.grey,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              if (widget.card.useFrontImageOverlay.value && path != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, error, trace) => CardFaceErrorWidget(
                      error: error,
                      stackTrace: trace,
                    ),
                  ),
                ),
              if (!widget.card.hideName.value)
                Center(
                  child: Wrap(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          widget.card.name.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: textColor,
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
          CardNameFormField(controller: widget.card.name),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: widget.card.barcode.type,
            builder: (context, barcodeType, _) => CardDataFormField(
              controller: widget.card.barcode.data,
              barcodeType: barcodeType,
              onScanButtonPressed: _scanCard,
            ),
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: widget.card.barcode.type,
            builder: (context, barcodeType, _) => BarcodeTypeSelectorButton(
              barcodeType: barcodeType,
              onPressed: _showBarcodeSelectorDialog,
            ),
          ),
          const SizedBox(height: 15),
          ColorPickerButton(onPressed: _showColorPickerDialog),
          const SizedBox(height: 15),
          PointsFormField(controller: widget.card.points),
          const SizedBox(height: 15),
          NotesFormField(controller: widget.card.notes),
        ],
      ),
    );
  }

  Widget _other(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _tagsEditor(theme),
          const SizedBox(height: 15),
          TakePictureButton(
            picturePath: widget.card.frontImagePath,
            label: Text(
              'Front face picture\nHold to delete',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.inverseSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          TakePictureButton(
            picturePath: widget.card.backImagePath,
            label: Text(
              'Back face picture\nHold to delete',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.inverseSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder(
            valueListenable: widget.card.useFrontImageOverlay,
            builder: (context, value, _) => CheckboxListTile(
              value: value,
              title: Text(
                'Use front face picture as a card thumbnail',
                style: theme.textTheme.bodyLarge?.copyWith(
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
              onChanged: (checked) {
                widget.card.useFrontImageOverlay.value = checked ?? false;
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: widget.card.hideName,
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
              onChanged: (checked) {
                widget.card.hideName.value = checked ?? false;
              },
            ),
          ),
          if (passwordBox.isNotEmpty)
            ValueListenableBuilder(
              valueListenable: widget.card.requiresAuth,
              builder: (context, value, _) => CheckboxListTile(
                value: value,
                title: Text(
                  'Use the password for this card',
                  style: theme.textTheme.bodyLarge?.copyWith(
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
                onChanged: (checked) {
                  widget.card.requiresAuth.value = checked ?? false;
                },
              ),
            )
          else
            const SizedBox(height: 10),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _tagsEditor(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, settingsBox, _) {
        final allTags = settingsBox.value.tags;
        if (allTags.isEmpty) {
          return const SizedBox.shrink();
        }
        return Row(
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
                    final tag = allTags[chipIndex];
                    final isSelected = widget.card.tags.value.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              widget.card.tags.value = widget.card.tags.value
                                  .where((t) => t != tag)
                                  .toList(growable: false);
                            } else {
                              widget.card.tags.value = [
                                ...widget.card.tags.value,
                                tag,
                              ];
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
        );
      },
    );
  }
}
