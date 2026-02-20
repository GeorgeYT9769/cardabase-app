import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/pages/card_details/card_details_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
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
  });

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  final passwordbox = Hive.box('password');
  final settingsbox = Hive.box('settingsBox');

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
                            ),
                          ),
                        );
                      });
                    } else {
                      VibrationProvider.vibrateSuccess();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Incorrect password!',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 3000),
                          padding: const EdgeInsets.all(5.0),
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          behavior: SnackBarBehavior.floating,
                          dismissDirection: DismissDirection.vertical,
                          backgroundColor:
                              const Color.fromARGB(255, 237, 67, 55),
                          elevation: 0.0,
                        ),
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

  void _showBottomSheet(BuildContext context, ThemeData theme) {
    VibrationProvider.vibrateSuccess();
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
              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }
}
