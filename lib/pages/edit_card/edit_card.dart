import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/data/loyalty_card.dart';
import 'package:cardabase/pages/edit_card/edit_card_form.dart';
import 'package:cardabase/pages/edit_card/error_snack_bar.dart';
import 'package:cardabase/pages/edit_card/form_fields/save_button.dart';
import 'package:cardabase/pages/edit_card/verify_code.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class EditCard extends StatefulWidget {
  const EditCard({
    super.key,
    required this.card,
    this.cardIndexInDb,
  });

  final int? cardIndexInDb;
  final LoyaltyCard card;

  @override
  State<EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<EditCard> {
  final _formKey = GlobalKey<FormState>();

  final settingsBox = Hive.box('settingsBox');
  final CardabaseDb cdb = CardabaseDb();

  final card = LoyaltyCard.empty().editable();

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      showValidationError();
      return;
    }

    final dbCard = card.seal().toDbModel();
    final cardIndexInDb = widget.cardIndexInDb;
    if (cardIndexInDb == null) {
      cdb.myShops.add(dbCard);
    } else {
      cdb.myShops[cardIndexInDb] = dbCard;
    }
    cdb.updateDataBase();
    Navigator.pop(context);
  }

  void showValidationError() {
    // TODO(wim): why do we vibrate success while there is an error?
    VibrationProvider.vibrateSuccess();

    if (card.name.text.isEmpty == true) {
      showErrorSnackBar(context, 'Card Name cannot be empty!');
    } else if (card.data.text.isEmpty == true) {
      showErrorSnackBar(context, 'Card ID cannot be empty!');
    } else if (validBarcode(card.barcodeType.value)(card.data.text) != null) {
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

    card.readFrom(LoyaltyCard.fromShare(code));
  }

  @override
  void initState() {
    card.readFrom(widget.card);
    cdb.loadData();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant EditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card) {
      card.readFrom(widget.card);
    }
  }

  @override
  void dispose() {
    card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _appBar(theme),
      body: EditCardForm(
        formKey: _formKey,
        card: card,
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
        widget.cardIndexInDb == null ? 'New card' : 'Edit card',
        style: theme.textTheme.titleLarge?.copyWith(),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
