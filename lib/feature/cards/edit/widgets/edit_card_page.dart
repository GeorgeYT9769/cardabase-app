import 'package:cardabase/feature/cards/edit/editable_loyalty_card.dart';
import 'package:cardabase/feature/cards/edit/verify_code.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_form.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/save_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class EditCardPage extends StatefulWidget {
  const EditCardPage({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  final _formKey = GlobalKey<FormState>();
  final cardsBox = GetIt.I<LoyaltyCardsBox>();

  EditableLoyaltyCard card = EditableLoyaltyCard.createNew();

  @override
  void initState() {
    super.initState();
    loadCard();
  }

  void loadCard() {
    card.dispose();
    final cardFromWidget = cardsBox.get(widget.cardId);
    if (cardFromWidget == null) {
      card = EditableLoyaltyCard.createNew()..id.value = widget.cardId;
    } else {
      card = cardFromWidget.editable();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant EditCardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId != widget.cardId) {
      loadCard();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      showValidationError();
      return;
    }

    cardsBox.put(card.id.value, card.seal());
    Navigator.pop(context);
  }

  void showValidationError() {
    GetIt.I<VibrationProvider>().vibrateError();

    if (card.name.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Card Name cannot be empty!', false),
      );
    } else if (card.barcode.data.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Card ID cannot be empty!', false),
      );
    } else if (validBarcode(card.barcode.type.value)(card.barcode.data.text) !=
        null) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Invalid Card ID!', false),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Something went wrong!', false),
      );
    }
  }

  Future<void> _scanSharedCode() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const QRBarReader()),
    );

    if (result == null || !mounted) {
      return;
    }

    final serialized = result['code'] as String;
    if (serialized == '-1') {
      return;
    }

    if (serialized.startsWith('[')) {
      card.loadValue(LoyaltyCard.fromLegacySharing(serialized));
    } else {
      card.loadValue(LoyaltyCard.fromJson(serialized));
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
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      title: Text(
        cardsBox.containsKey(widget.cardId) ? 'Edit card' : 'New card',
        style: theme.textTheme.titleLarge?.copyWith(),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
