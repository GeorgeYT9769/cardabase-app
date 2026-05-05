import 'dart:math';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_bottom_sheet.dart';
import 'package:cardabase/feature/cards/widgets/card_summary.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CardList extends StatelessWidget {
  const CardList({
    super.key,
    required this.isInReorderingMode,
    required this.numberOfColumns,
    required this.cards,
    required this.moveCard,
  });

  final bool isInReorderingMode;
  final int numberOfColumns;
  final List<LoyaltyCard> cards;
  final void Function(int oldIndex, int newIndex) moveCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (cards.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'There is nothing to see...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 60,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _CurvedArrowPainter(
                  theme.colorScheme.primary,
                  'Tap here!',
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    const childAspectRatio = 1.4;
    const gridPadding = 8.0;

    final sliverChildren =
        cards.map((card) => _card(context, theme, card)).toList();

    if (isInReorderingMode) {
      return SliverPadding(
        padding: const EdgeInsets.all(gridPadding),
        sliver: ReorderableSliverGridView.count(
          crossAxisCount: numberOfColumns,
          childAspectRatio: childAspectRatio,
          onReorder: moveCard,
          children: sliverChildren,
        ),
      );
    } else {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsetsGeometry.all(gridPadding),
            child: sliverChildren[index],
          ),
          childCount: sliverChildren.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: numberOfColumns,
          childAspectRatio: childAspectRatio,
        ),
      );
    }
  }

  Widget _card(BuildContext context, ThemeData theme, LoyaltyCard card) {
    return GestureDetector(
      key: ValueKey(card.id),
      onLongPress: isInReorderingMode
          ? null
          : () => showLoyaltyCardBottomSheets(context, card),
      child: CardSummary(
        cardId: card.id,
        cornerRadius: numberOfColumns == 1 ? 15 : 20 / numberOfColumns,
        fontSize: numberOfColumns == 1 ? 50 : 50 / numberOfColumns,
        marginSize: numberOfColumns == 1 ? 10 : 5 / numberOfColumns,
      ),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  _CurvedArrowPainter(
    this.color,
    this.text,
    this.textStyle,
  );

  final Color color;
  final String text;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);

    // Tweak these points to move the arrow easily
    final startPoint = Offset(textPainter.width / 2, textPainter.height + 10);
    final endPoint = Offset(size.width / 1.4, size.height * 1.1);
    final controlPoint = Offset(size.width * 0.1, size.height * 0.7);

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);

    final dx = endPoint.dx - controlPoint.dx;
    final dy = endPoint.dy - controlPoint.dy;
    final angle = atan2(dy, dx);
    const arrowSize = 25.0;
    const arrowAngle = pi / 8; // Adjust for wider/narrower head

    final headPath = Path();
    headPath.moveTo(
      endPoint.dx - arrowSize * cos(angle - arrowAngle),
      endPoint.dy - arrowSize * sin(angle - arrowAngle),
    );
    headPath.lineTo(endPoint.dx, endPoint.dy);
    headPath.lineTo(
      endPoint.dx - arrowSize * cos(angle + arrowAngle),
      endPoint.dy - arrowSize * sin(angle + arrowAngle),
    );

    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.text != text;
}
