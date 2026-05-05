import 'dart:async';
import 'dart:io';

import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/cards/card_face_error_widget.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_details_page.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/glitter.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/grain.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/snow.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';

class CardSummary extends StatefulWidget {
  const CardSummary({
    super.key,
    required this.cardId,
    required this.cornerRadius,
    required this.fontSize,
    required this.marginSize,
  });

  final String cardId;
  final double cornerRadius;
  final double fontSize;
  final double marginSize;

  @override
  State<CardSummary> createState() => _CardSummaryState();
}

class _CardSummaryState extends State<CardSummary> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();

  StreamSubscription? _cardSubscription;

  LoyaltyCard? card;

  @override
  void initState() {
    super.initState();
    _cardSubscription = cardsBox
        .watch(key: widget.cardId)
        .map((event) => event.value as LoyaltyCard?)
        .listen(onCardChanged);
    card = cardsBox.get(widget.cardId);
  }

  @override
  void didUpdateWidget(covariant CardSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardId != oldWidget.cardId) {
      _cardSubscription?.cancel();
      _cardSubscription = cardsBox
          .watch(key: widget.cardId)
          .map((event) => event.value as LoyaltyCard?)
          .listen(onCardChanged);
    }
  }

  Future<void> onCardChanged(LoyaltyCard? card) async {
    setState(() => this.card = card);
  }

  Future<void> openCard() async {
    final card = this.card;
    if (card == null) {
      return;
    }
    if (card.requiresAuth) {
      if (!await requirePassword(context)) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsPage(cardId: card.id),
      ),
    );
  }

  @override
  void dispose() {
    _cardSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frontImageFilePath = card?.frontImagePath;
    final backgroundColor = card?.nonNullColor;
    final foregroundColor = backgroundColor?.contrastingTextColor;
    return Bounceable(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.all(widget.marginSize),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0.0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.cornerRadius),
            ),
          ),
          onPressed: card == null ? null : openCard,
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(widget.cornerRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (frontImageFilePath != null && card?.useFrontImageOverlay == true)
                  Image.file(
                    File(frontImageFilePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, error, trace) => CardFaceErrorWidget(
                      error: error,
                      stackTrace: trace,
                    ),
                  ),
                _effect(),
                if (card?.hideName == false)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: Text(
                        card?.name ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _effect() {
    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, settingsBox, _) {
        final settings = settingsBox.value;
        if (!settings.theme.loyaltyCardEffect.isEnabled) {
          return const SizedBox.shrink();
        }
        return switch (settings.theme.loyaltyCardEffect.effect) {
          LoyaltyCardEffect.grain => const Grain(),
          LoyaltyCardEffect.snowy => const SnowyOverlay(),
          LoyaltyCardEffect.glitter => const GlitterOverlay()
        };
      },
    );
  }
}
