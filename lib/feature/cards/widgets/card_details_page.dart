import 'dart:io';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_face.dart';
import 'package:cardabase/feature/cards/widgets/share_card_dialog.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:screen_brightness/screen_brightness.dart';

class CardDetailsPage extends StatefulWidget {
  const CardDetailsPage({
    super.key,
    required this.loyaltyCard,
  });

  final LoyaltyCard loyaltyCard;

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  double? _previousBrightness;
  final settingsBox = GetIt.I.get<SettingsBox>();

  @override
  void initState() {
    super.initState();
    if (settingsBox.value.useAutoBrightness == false) {
      _increaseBrightness();
    }
  }

  Future<void> _increaseBrightness() async {
    _previousBrightness = await ScreenBrightness().system;
    await ScreenBrightness().setApplicationScreenBrightness(1.0);
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  Future<void> _resetBrightness() async {
    if (_previousBrightness != null) {
      await ScreenBrightness()
          .setApplicationScreenBrightness(_previousBrightness!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.loyaltyCard.color?.contrastingTextColor;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _appBar(theme),
      body: ListView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: widget.loyaltyCard.color,
            ),
            child: Column(
              children: [
                Text(
                  widget.loyaltyCard.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontSize: 50,
                  ),
                ),
                Text(
                  '${widget.loyaltyCard.points} points',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: constraints.maxWidth / 1.586,
                width: constraints.maxWidth,
                child: _card(theme),
              ),
            ),
          ),
          if (widget.loyaltyCard.notes != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 20,
                right: 20,
                bottom: 120,
              ),
              child: _note(theme),
            ),
        ],
      ),
      floatingActionButton: _saveButton(theme),
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
        onPressed: () => showDialog(
          context: context,
          builder: (context) => ShareCardDialog(
            data: widget.loyaltyCard.serializeForSharing(),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      title: Text('Details', style: theme.textTheme.titleLarge?.copyWith()),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
    );
  }

  Widget _card(ThemeData theme) {
    final frontImagePath = widget.loyaltyCard.frontImagePath;
    final backImagePath = widget.loyaltyCard.backImagePath;
    return PageView(
      controller: PageController(
        initialPage: frontImagePath == null ? 0 : 1,
      ),
      children: [
        if (frontImagePath != null)
          CardFace.image(
            cardTileColor: widget.loyaltyCard.color,
            image: FileImage(File(frontImagePath)),
            showWhiteOutline: false,
          ),
        CardFace.barcode(
          cardTileColor: widget.loyaltyCard.color,
          cardData: widget.loyaltyCard.barcode.data,
          barcodeType: widget.loyaltyCard.barcode.type,
          showWhiteOutline: true,
        ),
        if (backImagePath != null)
          CardFace.image(
            cardTileColor: widget.loyaltyCard.color,
            image: FileImage(File(backImagePath)),
            showWhiteOutline: false,
          ),
      ],
    );
  }

  Widget _note(ThemeData theme) {
    return TextField(
      enabled: false,
      maxLines: 10,
      decoration: InputDecoration(
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 15,
        ),
        hintText: widget.loyaltyCard.notes,
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(width: 2.0),
        ),
        focusColor: theme.colorScheme.primary,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _saveButton(ThemeData theme) {
    return Bounceable(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: FloatingActionButton.extended(
            elevation: 0.0,
            heroTag: 'saveFAB',
            onPressed: () => Navigator.pop(context),
            tooltip: 'SAVE',
            backgroundColor: Colors.green.shade700,
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            label: Text(
              'SAVE',
              style: theme.textTheme.bodyLarge?.copyWith(
                //cardTypeText
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
