import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/pages/card_details/card_details_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class CardTile extends StatefulWidget {
  final String shopName;
  final Function(BuildContext) deleteFunction;
  final String cardData;
  final Color cardTileColor;
  final BarcodeType barcodeType;
  final bool hasPassword;
  final Function(BuildContext) editFunction;
  final Function(BuildContext) moveUpFunction;
  final Function(BuildContext) moveDownFunction;
  final Function(BuildContext) duplicateFunction;
  final double labelSize;
  final double borderSize;
  final double marginSize;
  final Widget? dragHandle;
  final List<dynamic> tags;
  final bool reorderMode;
  final String note;
  final String uniqueId;
  final String frontImagePath;
  final String backImagePath;
  final bool useFrontFaceOverlay;
  final bool hideTitle;
  final int pointsAmount;

  const CardTile({
    super.key,
    required this.shopName,
    required this.deleteFunction,
    required this.cardData,
    required this.cardTileColor,
    required this.barcodeType,
    required this.hasPassword,
    required this.editFunction,
    required this.moveUpFunction,
    required this.moveDownFunction,
    required this.labelSize,
    required this.borderSize,
    required this.marginSize,
    this.dragHandle,
    required this.tags,
    required this.reorderMode,
    required this.note,
    required this.uniqueId,
    required this.duplicateFunction,
    required this.frontImagePath,
    required this.backImagePath,
    required this.useFrontFaceOverlay,
    required this.hideTitle,
    required this.pointsAmount,
  });

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  final passwordbox = Hive.box('password');

  ImageProvider? frontImage;
  ImageProvider? backImage;

  @override
  void initState() {
    super.initState();
    frontImage = widget.frontImagePath.isNotEmpty
        ? FileImage(File(widget.frontImagePath))
        : null;
    backImage = widget.backImagePath.isNotEmpty
        ? FileImage(File(widget.backImagePath))
        : null;
  }

  @override
  void didUpdateWidget(covariant CardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frontImagePath != widget.frontImagePath) {
      frontImage = widget.frontImagePath.isNotEmpty
          ? FileImage(File(widget.frontImagePath))
          : null;
    }
    if (oldWidget.backImagePath != widget.backImagePath) {
      backImage = widget.backImagePath.isNotEmpty
          ? FileImage(File(widget.backImagePath))
          : null;
    }
  }

  Color getContrastingTextColor(Color bg) {
    return bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;
  }

  Barcode getBarcodeType(String cardType) {
    switch (cardType) {
      case 'CardType.code39':
        return Barcode.code39();
      case 'CardType.code93':
        return Barcode.code93();
      case 'CardType.code128':
        return Barcode.code128();
      case 'CardType.ean13':
        return Barcode.ean13(drawEndChar: true);
      case 'CardType.ean8':
        return Barcode.ean8();
      case 'CardType.ean5':
        return Barcode.ean5();
      case 'CardType.ean2':
        return Barcode.ean2();
      case 'CardType.itf':
        return Barcode.itf();
      case 'CardType.itf14':
        return Barcode.itf14();
      case 'CardType.itf16':
        return Barcode.itf16();
      case 'CardType.upca':
        return Barcode.upcA();
      case 'CardType.upce':
        return Barcode.upcE();
      case 'CardType.codabar':
        return Barcode.codabar();
      case 'CardType.qrcode':
        return Barcode.qrCode();
      case 'CardType.datamatrix':
        return Barcode.dataMatrix();
      case 'CardType.aztec':
        return Barcode.aztec();
      default:
        return Barcode.ean13(drawEndChar: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color contentTextColor =
        getContrastingTextColor(widget.cardTileColor);

    void showUnlockDialog(BuildContext context) {
      final TextEditingController controller = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Enter Password',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.inverseSurface,
              fontSize: 30,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(width: 2.0),
                  ),
                  focusColor: theme.colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: theme.colorScheme.secondary,
                  ),
                  labelText: 'Password',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    if (controller.text == passwordbox.get('PW')) {
                      FocusScope.of(context).unfocus();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardDetailsPage(
                              cardData: widget.cardData,
                              title: widget.shopName,
                              borderColor: widget.cardTileColor,
                              barcodeType: widget.barcodeType,
                              hasPassword: widget.hasPassword,
                              tags: const [],
                              note: widget.note,
                              frontImage: frontImage,
                              backImage: backImage,
                              pointsAmount: widget.pointsAmount,
                            ),
                          ),
                        );
                      });
                    } else {
                      GetIt.I<VibrationProvider>().vibrateError();
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Incorrect password!', false),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    elevation: 0.0,
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    'Unlock',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void askForPassword() {
      if (passwordbox.isNotEmpty && widget.hasPassword) {
        showUnlockDialog(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailsPage(
              cardData: widget.cardData,
              title: widget.shopName,
              borderColor: widget.cardTileColor,
              barcodeType: widget.barcodeType,
              hasPassword: widget.hasPassword,
              tags: const [],
              note: widget.note,
              frontImage: frontImage,
              backImage: backImage,
              pointsAmount: widget.pointsAmount,
            ),
          ),
        );
      }
    }

    return Bounceable(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.all(widget.marginSize),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onLongPress: widget.reorderMode
                    ? null
                    : () => _showBottomSheet(context, theme),
                child: SizedBox(
                  height: (MediaQuery.of(context).size.width - 40) / 1.586,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.cardTileColor,
                      foregroundColor: contentTextColor,
                      elevation: 0.0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(widget.borderSize),
                      ),
                    ),
                    onPressed: askForPassword,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.useFrontFaceOverlay &&
                            widget.frontImagePath.isNotEmpty)
                          FutureBuilder<bool>(
                            future: File(widget.frontImagePath).exists(),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<bool> snapshot,
                            ) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data == true) {
                                return ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(widget.borderSize),
                                  child: Image.file(
                                    File(widget.frontImagePath),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ValueListenableBuilder(
                          valueListenable: GetIt.I<SettingsBox>().listenable(),
                          builder: (context, settingsBox, _) {
                            final settings = settingsBox.value;
                            if (!settings.theme.loyaltyCardEffect.isEnabled) {
                              return const SizedBox.shrink();
                            }
                            return _buildEffectOverlay(
                                settings.theme.loyaltyCardEffect.effect,
                                widget.borderSize);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Center(
                            child: Text(
                              widget.hideTitle ? '' : widget.shopName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: widget.labelSize,
                                fontWeight: FontWeight.bold,
                                color: contentTextColor,
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
            ),
            if (widget.dragHandle != null) widget.dragHandle!,
          ],
        ),
      ),
    );
  }

  Future<void> _setWidgetCard(BuildContext context, ThemeData theme) async {
    const channel = MethodChannel('cardabase_widget');
    final success = await channel.invokeMethod<bool>('setWidgetCard', {
      'data': widget.cardData,
      'type': widget.barcodeType.toString(),
      'r': (widget.cardTileColor.r * 255).toInt(),
      'g': (widget.cardTileColor.g * 255).toInt(),
      'b': (widget.cardTileColor.b * 255).toInt(),
    });
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Widget updated!', true),
      );
    }
  }

  void _showUnlockDialogForWidget(BuildContext context, ThemeData theme) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Password',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
            fontSize: 30,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(width: 2.0),
                ),
                focusColor: theme.colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: theme.colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);
                      _setWidgetCard(context, theme);
                    });
                  } else {
                    GetIt.I<VibrationProvider>().vibrateError();
                    ScaffoldMessenger.of(context).showSnackBar(
                      buildCustomSnackBar('Incorrect password!', false),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  elevation: 0.0,
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  'Unlock',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, ThemeData theme) {
    GetIt.I<VibrationProvider>().vibrateSelection();
    showModalBottomSheet(
      context: context,
      elevation: 0.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
                onTap: () {
                  Navigator.pop(context);
                  if (passwordbox.isNotEmpty && widget.hasPassword) {
                    _showUnlockDialogForWidget(context, theme);
                  } else {
                    _setWidgetCard(context, theme);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.tertiary),
                title:
                    Text('Edit', style: theme.textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.editFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: theme.colorScheme.tertiary),
                title: Text(
                  'Duplicate',
                  style: theme.textTheme.bodyLarge?.copyWith(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.duplicateFunction(context);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.arrow_upward, color: theme.colorScheme.tertiary),
                title: Text(
                  'Move UP',
                  style: theme.textTheme.bodyLarge?.copyWith(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.moveUpFunction(context);
                },
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
                onTap: () {
                  Navigator.pop(context);
                  widget.moveDownFunction(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'DELETE',
                  style: theme.textTheme.bodyLarge?.copyWith(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.deleteFunction(context);
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEffectOverlay(LoyaltyCardEffect effect, double borderRadius) {
    switch (effect) {
      case LoyaltyCardEffect.grain:
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.asset(
            'assets/noise.png', // Place a seamless noise image in your assets
            fit: BoxFit.cover,
            color: Colors.white.withAlpha(20),
            colorBlendMode: BlendMode.srcOver,
          ),
        );
      case LoyaltyCardEffect.snowy:
        return _SnowyOverlay(borderRadius: borderRadius);
      case LoyaltyCardEffect.glitter:
        return _GlitterOverlay(borderRadius: borderRadius);
    }
  }
}

class _SnowyOverlay extends StatefulWidget {
  final double borderRadius;
  const _SnowyOverlay({super.key, required this.borderRadius});

  @override
  State<_SnowyOverlay> createState() => _SnowyOverlayState();
}

class _SnowyOverlayState extends State<_SnowyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SnowyPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SnowyPainter extends CustomPainter {
  final double progress;
  _SnowyPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final sparkleCount = 18;
    for (int i = 0; i < sparkleCount; i++) {
      final t = (progress + i / sparkleCount) % 1.0;
      final x = size.width * (0.1 + 0.8 * (i % 3) / 2 + 0.2 * t);
      final y = size.height * ((i / sparkleCount + t) % 1.0);
      final radius = 1.5 + 2.5 * (1 - (t - 0.5).abs() * 2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlitterOverlay extends StatefulWidget {
  final double borderRadius;
  const _GlitterOverlay({super.key, required this.borderRadius});

  @override
  State<_GlitterOverlay> createState() => _GlitterOverlayState();
}

class _GlitterOverlayState extends State<_GlitterOverlay> {
  late List<_GlitterStar> _stars;
  final int _starCount = 5; // Fewer stars for performance

  @override
  void initState() {
    super.initState();
    _stars = List.generate(_starCount, (i) => _GlitterStar.random());
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: CustomPaint(
        painter: _GlitterPainter(_stars),
        size: Size.infinite,
      ),
    );
  }
}

class _GlitterStar {
  final double x;
  final double y;
  final double size;
  final Color color;
  final String symbol;

  _GlitterStar(this.x, this.y, this.size, this.color, this.symbol);

  static final List<String> symbols = [
    '*',
    '✦',
    '✬',
    '✯',
    '˚',
    '｡',
    '❀',
    '+',
    '-',
    '/',
    '♪',
    '♫',
  ];

  static _GlitterStar random() {
    final rnd = UniqueKey().hashCode;
    final x = (rnd % 1000) / 1000.0;
    final y = ((rnd ~/ 1000) % 1000) / 1000.0;
    final size = 18.0 + (rnd % 8); // Large for visibility
    final color = Colors.white.withValues(alpha: 0.5); // More transparent
    final symbol = symbols[rnd % symbols.length];
    return _GlitterStar(x, y, size, color, symbol);
  }
}

class _GlitterPainter extends CustomPainter {
  final List<_GlitterStar> stars;
  _GlitterPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final px = star.x * size.width;
      final py = star.y * size.height;
      final textPainter = TextPainter(
        text: TextSpan(
          text: star.symbol,
          style: TextStyle(
            fontSize: star.size,
            color: star.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(px - textPainter.width / 2, py - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter oldDelegate) => false;
}
