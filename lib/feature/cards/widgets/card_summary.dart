import 'dart:io';

import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_details_page.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/glitter.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/grain.dart';
import 'package:cardabase/feature/cards/widgets/card_effects/snow.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';

class CardSummary extends StatefulWidget {
  const CardSummary({
    super.key,
    required this.loyaltyCard,
    required this.cornerRadius,
    required this.fontSize,
  });

  final LoyaltyCard loyaltyCard;
  final double cornerRadius;
  final double fontSize;

  @override
  State<CardSummary> createState() => _CardSummaryState();
}

class _CardSummaryState extends State<CardSummary> {
  File? frontImageFile;

  @override
  void initState() {
    super.initState();
    setFrontImage();
  }

  @override
  void didUpdateWidget(covariant CardSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loyaltyCard != oldWidget.loyaltyCard) {
      setFrontImage();
    }
  }

  Future<void> setFrontImage() async {
    if (widget.loyaltyCard.useFrontImageOverlay) {
      return;
    }

    final path = widget.loyaltyCard.frontImagePath;
    if (path == null) {
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => frontImageFile = file);
  }

  Future<void> openCard() async {
    if (widget.loyaltyCard.requiresAuth) {
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
        builder: (context) => CardDetailsPage(
          loyaltyCard: widget.loyaltyCard,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frontImageFile = this.frontImageFile;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.loyaltyCard.color,
        foregroundColor: widget.loyaltyCard.color?.contrastingTextColor,
        elevation: 0.0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
      ),
      onPressed: openCard,
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(widget.cornerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (frontImageFile != null)
              Image.file(
                frontImageFile,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            _effect(),
            if (!widget.loyaltyCard.hideName)
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Center(
                  child: Text(
                    widget.loyaltyCard.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.loyaltyCard.color?.contrastingTextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
          ],
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
