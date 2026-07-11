import 'dart:math';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_bottom_sheet.dart';
import 'package:cardabase/feature/cards/widgets/card_summary.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CardList extends StatefulWidget {
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
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  final GlobalKey<SliverAnimatedGridState> _gridKey =
      GlobalKey<SliverAnimatedGridState>();
  List<LoyaltyCard> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cards);
  }

  @override
  void didUpdateWidget(CardList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldList = _items;
    final newList = widget.cards;

    if (widget.isInReorderingMode) {
      _items = List.from(newList);
      return;
    }

    // Detect single removal
    if (oldList.length == newList.length + 1) {
      int? removedIndex;
      for (int i = 0; i < newList.length; i++) {
        if (oldList[i].id != newList[i].id) {
          removedIndex = i;
          break;
        }
      }
      removedIndex ??= oldList.length - 1;

      final removedItem = oldList[removedIndex];
      _items.removeAt(removedIndex);
      _gridKey.currentState?.removeItem(
        removedIndex,
        (context, animation) => _buildItem(removedItem, animation, isRemoving: true),
        duration: const Duration(milliseconds: 400),
      );
    } 
    // Detect single addition
    else if (oldList.length == newList.length - 1) {
      int? insertedIndex;
      for (int i = 0; i < oldList.length; i++) {
        if (oldList[i].id != newList[i].id) {
          insertedIndex = i;
          break;
        }
      }
      insertedIndex ??= newList.length - 1;

      _items.insert(insertedIndex, newList[insertedIndex]);
      _gridKey.currentState?.insertItem(
        insertedIndex,
        duration: const Duration(milliseconds: 400),
      );
    }
    // Fallback for complex changes (sorting, filters, multiple changes)
    else {
      _items = List.from(newList);
    }
  }

  Widget _buildItem(LoyaltyCard card, Animation<double> animation, {bool isRemoving = false}) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: isRemoving ? Curves.easeInBack : Curves.easeOutBack,
      ),
      child: FadeTransition(
        opacity: animation,
        child: _card(context, Theme.of(context), card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.cards.isEmpty) {
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

    const childAspectRatio = 1.57;
    const crossAxisPadding = 10.0;
    const mainAxisPadding = 10.0;

    if (widget.isInReorderingMode) {
      return ReorderableSliverGridView.count(
        crossAxisSpacing: crossAxisPadding,
        mainAxisSpacing: mainAxisPadding,
        crossAxisCount: widget.numberOfColumns,
        childAspectRatio: childAspectRatio,
        onReorder: widget.moveCard,
        children: widget.cards.map((card) => _card(context, theme, card)).toList(),
      );
    } else {
      return SliverAnimatedGrid(
        key: _gridKey,
        initialItemCount: _items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: mainAxisPadding,
          crossAxisSpacing: crossAxisPadding,
          crossAxisCount: widget.numberOfColumns,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index, animation) {
          // Safety check for async sync
          if (index >= _items.length) return const SizedBox.shrink();
          return _buildItem(_items[index], animation);
        },
      );
    }
  }

  Widget _card(BuildContext context, ThemeData theme, LoyaltyCard card) {
    return GestureDetector(
      key: ValueKey(card.id),
      onLongPress: widget.isInReorderingMode
          ? null
          : () => showLoyaltyCardBottomSheets(context, card),
      child: Padding(
        padding: widget.numberOfColumns == 1
            ? const EdgeInsets.all(10)
            : EdgeInsets.all(5 / widget.numberOfColumns),
        child: CardSummary(
          cardId: card.id,
          cornerRadius: widget.numberOfColumns == 1 ? 15 : 20 / widget.numberOfColumns,
        ),
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
