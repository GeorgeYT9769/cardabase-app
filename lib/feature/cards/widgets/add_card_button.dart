import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/widgets/blur_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class AddCardButton extends StatelessWidget {
  const AddCardButton({
    super.key,
  });

  Future<void> addCard(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => EditCardPage(
          cardId: generateUniqueId(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // the button follows the textures setting, which is watched here rather
    // than by the page so the button can be a const widget of its own.
    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, settingsBox, _) {
        final advancedTextures = settingsBox.value.theme.advancedTextures;
        return Bounceable(
          onTap: () {},
          child: SizedBox(
            height: 70,
            width: 70,
            child: BlurWrapper(
              useBlur: advancedTextures,
              isCircle: false,
              borderRadius: BorderRadius.circular(20),
              blurSigma: 10,
              child: FittedBox(
                child: FloatingActionButton(
                  elevation: 0.0,
                  enableFeedback: true,
                  tooltip: 'Add a card',
                  onPressed: () => addCard(context),
                  backgroundColor: advancedTextures
                      ? theme.colorScheme.primaryContainer.withValues(alpha: .9)
                      : null,
                  child: const Icon(Icons.add_card),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
