import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_face.dart';
import 'package:cardabase/feature/cards/widgets/share_card_dialog.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/color_extensions.dart';
import 'package:cardabase/util/widgets/cdb_app_bar_sliver.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:screen_brightness/screen_brightness.dart';

class CardDetailsPage extends StatefulWidget {
  const CardDetailsPage({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();

  StreamSubscription? _cardSubscription;

  LoyaltyCard? card;
  double? _previousBrightness;
  final settingsBox = GetIt.I.get<SettingsBox>();
  final _notesController = TextEditingController();
  final _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    card = cardsBox.get(widget.cardId);
    _notesController.text = card?.notes ?? '';

    _cardSubscription = cardsBox
        .watch(key: widget.cardId)
        .map((event) => event.value as LoyaltyCard?)
        .listen(onCardChanged);

    if (settingsBox.value.useAutoBrightness == false) {
      _increaseBrightness();
    }
  }

  @override
  void didUpdateWidget(covariant CardDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardId != oldWidget.cardId) {
      _cardSubscription?.cancel();
      _cardSubscription = cardsBox
          .watch(key: widget.cardId)
          .map((event) => event.value as LoyaltyCard?)
          .listen(onCardChanged);
      card = cardsBox.get(widget.cardId);
      _notesController.text = card?.notes ?? '';
    }
  }

  Future<void> onCardChanged(LoyaltyCard? card) async {
    setState(() => this.card = card);
    if (card != null &&
        !_notesFocusNode.hasFocus &&
        _notesController.text != (card.notes ?? '')) {
      _notesController.text = card.notes ?? '';
    }
  }

  void _saveNotes(String value) {
    if (card == null) return;
    final updatedCard = card!.copyWith(notes: value.isEmpty ? null : value);
    cardsBox.put(updatedCard.id, updatedCard);
  }

  Future<void> _increaseBrightness() async {
    _previousBrightness = await ScreenBrightness().system;
    await ScreenBrightness().setApplicationScreenBrightness(1.0);
  }

  @override
  void dispose() {
    _resetBrightness();
    _cardSubscription?.cancel();
    _notesController.dispose();
    _notesFocusNode.dispose();
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
    final textColor = card?.color?.contrastingTextColor;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          _appBar(theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: card?.color,
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          card?.name ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (card?.usePoints == true)
                        Text(
                          '${card?.points} points',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor,
                            fontSize: 20,
                          ),
                        ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
                _cardPreview(theme),
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
          ),
        ],
      ),
      floatingActionButton: _saveButton(theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _appBar(ThemeData theme) {
    return CdbAppBarSliver(
      title: 'Details',
      onBackPressed: () => Navigator.pop(context),
      leading: IconButton(
        icon: Icon(
          Icons.qr_code_2,
          color: theme.colorScheme.secondary,
        ),
        onPressed: card == null
            ? null
            : () => showDialog(
          context: context,
          builder: (context) => ShareCardDialog(
            data: card?.toJson() ?? '',
          ),
        ),
      ),
      actions: [
        if (settingsBox.value.developerOptions.isEnabled)
          IconButton(
            icon: Icon(
              Icons.data_object,
              color: theme.colorScheme.secondary,
            ),
            onPressed: card == null
                ? null
                : () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Data'),
                        content: SingleChildScrollView(
                          child: SelectableText(
                            const JsonEncoder.withIndent('  ')
                                .convert(card!.toJsonMap()),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: card!.toJson()),
                              );
                              Navigator.pop(context);
                              showCustomSnackBar(
                                context,
                                'Copied card data!',
                                true,
                              );
                            },
                            child: const Text('Copy'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
          ),
      ],
    );
  }

  Widget _cardPreview(ThemeData theme) {
    final frontImagePath = card?.frontImagePath;
    final backImagePath = card?.backImagePath;
    final hasFront =
        frontImagePath != null && File(frontImagePath).existsSync() == true;
    final hasBarcode = card != null && card!.barcode.type != null;
    final hasBack =
        backImagePath != null && File(backImagePath).existsSync() == true;

    if (!hasFront && !hasBarcode && !hasBack) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxWidth / 1.586,
        width: constraints.maxWidth,
        child: _card(theme, hasFront, hasBarcode, hasBack),
      ),
    );
  }

  Widget _card(ThemeData theme, bool hasFront, bool hasBarcode, bool hasBack) {
    final frontImagePath = card?.frontImagePath;
    final backImagePath = card?.backImagePath;

    final children = [
      if (hasFront)
        CardFace.image(
          cardTileColor: card?.color,
          image: FileImage(File(frontImagePath!)),
          showWhiteOutline: false,
          showLeftTriangle: false,
          showRightTriangle: hasBarcode || hasBack,
        ),
      if (hasBarcode)
        CardFace.barcode(
          cardTileColor: card!.color,
          cardData: card!.barcode.data,
          barcodeType: card!.barcode.type!,
          showWhiteOutline: true,
          showLeftTriangle: hasFront,
          showRightTriangle: hasBack,
        ),
      if (hasBack)
        CardFace.image(
          cardTileColor: card?.color,
          image: FileImage(File(backImagePath!)),
          showWhiteOutline: false,
          showLeftTriangle: hasFront || hasBarcode,
          showRightTriangle: false,
        ),
    ];

    int initialPage = 0;
    if (hasFront && hasBarcode) {
      initialPage = 1;
    }

    return PageView(
      controller: PageController(
        initialPage: initialPage,
      ),
      children: children,
    );
  }

  Widget _note(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          maxLines: null,
          onChanged: _saveNotes,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 16,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _saveButton(ThemeData theme) {
    return ListenableBuilder(
      listenable: _notesFocusNode,
      builder: (context, child) {
        final isFocused = _notesFocusNode.hasFocus;
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
                onPressed: () {
                  if (isFocused) {
                    _saveNotes(_notesController.text);
                    _notesFocusNode.unfocus();
                  } else {
                    Navigator.pop(context);
                  }
                },
                tooltip: isFocused ? 'SAVE' : 'DONE',
                backgroundColor: isFocused ? theme.colorScheme.primary : Colors.green.shade700,
                icon: Icon(
                  isFocused ? Icons.check : Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text(
                  isFocused ? 'SAVE' : 'DONE',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
