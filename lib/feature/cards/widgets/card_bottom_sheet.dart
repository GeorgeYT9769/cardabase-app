import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/platform/set_widget_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../util/vibration_provider.dart';

Future<void> showLoyaltyCardBottomSheets(
  BuildContext context,
  LoyaltyCard loyaltyCard,
) {
  GetIt.I<VibrationProvider>().vibrateSelection();
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
    if (!canCreateCardWidget) {
      return;
    }
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
      showCustomSnackBar(context, 'Widget updated!', true);
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
    final newCard = widget.loyaltyCard.clone();
    final customOrder = settings.cardListViewOptions.customOrder;

    final orderIndex = customOrder.indexOf(widget.loyaltyCard.id);
    if (orderIndex >= 0) {
      customOrder.insert(orderIndex + 1, newCard.id);
    }

    settings.cardListViewOptions.customOrder.value = customOrder;

    // Order of saving matters. Since the custom order is checked for new/old
    // cards after the cardsBox changed, we need to update the settings first.
    await settingsBox.save(settings.seal());
    await cardsBox.put(newCard.id, newCard);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete ${widget.loyaltyCard.name}?'),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            style: OutlinedButton.styleFrom(
              elevation: 0.0,
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: OutlinedButton.styleFrom(
              elevation: 0.0,
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              'DELETE',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(context).pop();

    final settings = settingsBox.value.editable();
    settings.cardListViewOptions.customOrder.value = settings
        .cardListViewOptions.customOrder.value
        .where((id) => id != widget.loyaltyCard.id)
        .toList();
    await settingsBox.save(settings.seal());

    await cardsBox.delete(widget.loyaltyCard.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortingStyle = settingsBox.value.cardListViewOptions.sortingStyle;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        children: [
          if (canCreateCardWidget)
            ListTile(
              leading: Icon(Icons.widgets, color: theme.colorScheme.tertiary),
              title: Text(
                'Set as Widget',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight(700),
                ),
              ),
              onTap: _createCardWidget,
            ),
          ListTile(
            leading: Icon(Icons.edit, color: theme.colorScheme.tertiary),
            title: Text('Edit', style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight(700),
            ),),
            onTap: _editCard,
          ),
          ListTile(
            leading: Icon(Icons.copy, color: theme.colorScheme.tertiary),
            title: Text(
              'Duplicate',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight(700),
              ),
            ),
            onTap: _duplicateCard,
          ),
          if (sortingStyle == SortingStyle.custom)
            ...[
              ListTile(
                leading:
                    Icon(Icons.arrow_upward, color: theme.colorScheme.tertiary),
                title: Text(
                  'Move UP',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight(700),
                  ),
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight(700),
                  ),
                ),
                onTap: _moveCardDown,
              ),
            ],
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'DELETE',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight(700),
              ),
            ),
            onTap: _deleteCard,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
