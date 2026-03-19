import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/data/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/pages/edit_card/edit_card_form.dart';
import 'package:cardabase/pages/edit_card/form_fields/save_button.dart';
import 'package:cardabase/pages/edit_card/verify_code.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class EditCard extends StatefulWidget {
  const EditCard({
    super.key,
    required this.card,
  });

  final LoyaltyCard card;

  @override
  State<EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<EditCard> {
  final _formKey = GlobalKey<FormState>();

  final CardabaseDb cdb = CardabaseDb();

  final card = LoyaltyCard.empty().editable();

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      showValidationError();
      return;
    }

    cdb.upsert(card.seal());
    Navigator.pop(context);
  }

  void showValidationError() {
    GetIt.I<VibrationProvider>().vibrateError();

    if (card.name.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Card Name cannot be empty!', false),
      );
    } else if (card.data.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Card ID cannot be empty!', false),
      );
    } else if (validBarcode(card.barcodeType.value)(card.data.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Invalid Card ID!', false),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Something went wrong!', false),
      );
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
          valueListenable: GetIt.I<SettingsBox>().listenable(),
          builder: (context, settingsBox, _) =>
              settingsBox.value.developerOptions.isEnabled
                  ? IconButton(
                      icon: Icon(
                        Icons.credit_card_off,
                        color: theme.colorScheme.secondary,
                      ),
                      onPressed: _addLegacyCard,
                    )
                  : const SizedBox.shrink(),
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
        cdb.exists(widget.card.uniqueId) ? 'Edit card' : 'New card',
        style: theme.textTheme.titleLarge?.copyWith(),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
