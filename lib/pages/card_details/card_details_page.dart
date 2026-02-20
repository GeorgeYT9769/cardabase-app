import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/pages/card_details/card_face.dart';
import 'package:cardabase/pages/card_details/share_card_dialog.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:screen_brightness/screen_brightness.dart';

class CardDetailsPage extends StatefulWidget {
  const CardDetailsPage({
    super.key,
    required this.cardData,
    required this.title,
    required this.borderColor,
    required this.barcodeType,
    required this.hasPassword,
    required this.tags,
    required this.note,
    required this.frontImage,
    required this.backImage,
  });

  final String cardData;
  final String title;
  final Color borderColor;
  final BarcodeType barcodeType;
  final bool hasPassword;
  final List tags;
  final String note;
  final ImageProvider? frontImage;
  final ImageProvider? backImage;

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  double? _previousBrightness;
  final setBrightness =
      settingsbox.get('setBrightness', defaultValue: true) as bool;

  @override
  void initState() {
    super.initState();
    if (setBrightness == false) {
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
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _appBar(theme),
      body: ListView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.inverseSurface,
                fontSize: 50,
              ),
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
          if (widget.note.isNotEmpty)
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
            // TODO(wim): extract this logic somewhere central
            data:
                '[${widget.title}, ${widget.cardData}, ${widget.borderColor.r.toInt()}, ${widget.borderColor.g.toInt()}, ${widget.borderColor.b.toInt()}, ${widget.barcodeType}, ${widget.hasPassword}, ${widget.tags}]',
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
    final frontImage = widget.frontImage;
    final backImage = widget.backImage;
    return PageView(
      controller: PageController(
        initialPage: widget.frontImage == null ? 0 : 1,
      ),
      children: [
        if (frontImage != null)
          CardFace.image(
            cardTileColor: widget.borderColor,
            image: frontImage,
          ),
        CardFace.barcode(
          cardTileColor: widget.borderColor,
          cardData: widget.cardData,
          barcodeType: widget.barcodeType,
        ),
        if (backImage != null)
          CardFace.image(
            cardTileColor: widget.borderColor,
            image: backImage,
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
        hintText: widget.note,
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
