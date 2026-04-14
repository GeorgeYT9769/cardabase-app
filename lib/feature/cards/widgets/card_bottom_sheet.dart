import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/platform/set_widget_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> showLoyaltyCardBottomSheets(
  BuildContext context,
  LoyaltyCard loyaltyCard,
) {
  return showModalBottomSheet(
    context: context,
    elevation: 0.0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) => _CardBottomSheetContent(
      loyaltyCard: loyaltyCard,
    ),
  );
}

class _CardBottomSheetContent extends StatefulWidget {
  const _CardBottomSheetContent({
    required this.loyaltyCard,
  });

  final LoyaltyCard loyaltyCard;

  @override
  State<_CardBottomSheetContent> createState() =>
      _CardBottomSheetContentState();
}

class _CardBottomSheetContentState extends State<_CardBottomSheetContent> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final settingsBox = GetIt.I<SettingsBox>();

  Future<void> _createCardWidget() async {
    if (widget.loyaltyCard.requiresAuth) {
      if (!await requirePassword(context)) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    final success = await createCardWidget(widget.loyaltyCard);
    if (!mounted) {
      return;
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Widget updated!', true),
      );
    }
  }

  Future<void> _editCard() async {
    if (widget.loyaltyCard.requiresAuth) {
      if (!await requirePassword(context)) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => EditCardPage(
          cardId: widget.loyaltyCard.id,
        ),
      ),
    );
  }

  Future<void> _duplicateCard() async {
    Navigator.of(context).pop();
    final settings = settingsBox.value.editable();
    final order = settings.cardListViewOptions.customOrder;
    final newCard = widget.loyaltyCard.clone();
    final customOrder = settings.cardListViewOptions.customOrder;

    final orderIndex = customOrder.indexOf(widget.loyaltyCard.id);
    if (orderIndex >= 0) {
      customOrder.insert(orderIndex + 1, newCard.id);
    }

    settings.cardListViewOptions.customOrder.value = order;

    await cardsBox.add(newCard);
    await settingsBox.save(settings.seal());
  }

  Future<void> _moveCardUp() async {
    Navigator.of(context).pop();
    final settings = settingsBox.value.editable();
    settings.cardListViewOptions.customOrder.moveUp(widget.loyaltyCard.id);
    await settingsBox.save(settings.seal());
  }

  Future<void> _moveCardDown() async {
    Navigator.of(context).pop();
    final settings = settingsBox.value.editable();
    settings.cardListViewOptions.customOrder.moveDown(widget.loyaltyCard.id);
    await settingsBox.save(settings.seal());
  }

  Future<void> _deleteCard() async {
    Navigator.of(context).pop();
    cardsBox.delete(widget.loyaltyCard.id);
    final settings = settingsBox.value.editable();
    settings.cardListViewOptions.customOrder.remove(widget.loyaltyCard.id);
    await settingsBox.save(settings.seal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.widgets, color: theme.colorScheme.tertiary),
            title: Text(
              'Set as Widget',
              style: theme.textTheme.bodyLarge?.copyWith(),
            ),
            onTap: _createCardWidget,
          ),
          ListTile(
            leading: Icon(Icons.edit, color: theme.colorScheme.tertiary),
            title: Text('Edit', style: theme.textTheme.bodyLarge?.copyWith()),
            onTap: _editCard,
          ),
          ListTile(
            leading: Icon(Icons.copy, color: theme.colorScheme.tertiary),
            title: Text(
              'Duplicate',
              style: theme.textTheme.bodyLarge?.copyWith(),
            ),
            onTap: _duplicateCard,
          ),
          ListTile(
            leading:
                Icon(Icons.arrow_upward, color: theme.colorScheme.tertiary),
            title: Text(
              'Move UP',
              style: theme.textTheme.bodyLarge?.copyWith(),
            ),
            onTap: _moveCardUp,
          ),
          ListTile(
            leading: Icon(
              Icons.arrow_downward,
              color: theme.colorScheme.tertiary,
            ),
            title: Text(
              'Move DOWN',
              style: theme.textTheme.bodyLarge?.copyWith(),
            ),
            onTap: _moveCardDown,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'DELETE',
              style: theme.textTheme.bodyLarge?.copyWith(),
            ),
            onTap: _deleteCard,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
