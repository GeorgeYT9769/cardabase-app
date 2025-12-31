import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/pages/card_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'vibration_provider.dart';


class CardTile extends StatefulWidget {
  final String shopName;
  final Function(BuildContext) deleteFunction;
  final String cardnumber;
  final Color cardTileColor;
  final String cardType;
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
  final String imagePathFront;
  final String imagePathBack;
  final bool useFrontFaceOverlay;
  final bool hideTitle;

  final int red;
  final int green;
  final int blue;

  CardTile({
    super.key,
    required this.shopName,
    required this.deleteFunction,
    required this.cardnumber,
    required this.cardTileColor,
    required this.cardType,
    required this.hasPassword,
    required this.red,
    required this.green,
    required this.blue,
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
    required this.imagePathFront,
    required this.imagePathBack,
    required this.useFrontFaceOverlay,
    required this.hideTitle
  });

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  final passwordbox = Hive.box('password');
  final settingsbox = Hive.box('settingsBox');

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
    final Color contentTextColor = getContrastingTextColor(widget.cardTileColor);
    void showUnlockDialog(BuildContext context) {
      final TextEditingController controller = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Password', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30) ),
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
                  focusColor: Theme.of(context).colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  labelText: 'Password',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
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
                            builder: (context) => CardDetails(
                              cardid: widget.cardnumber,
                              cardtext: widget.shopName,
                              cardTileColor: widget.cardTileColor,
                              cardType: widget.cardType,
                              hasPassword: widget.hasPassword,
                              red: widget.red,
                              green: widget.green,
                              blue: widget.blue,
                              tags: [],
                              note: widget.note,
                              imagePathFront: widget.imagePathFront,
                              imagePathBack: widget.imagePathBack,
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
                              Icon(Icons.error, size: 15, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Incorrect password!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                          elevation: 0.0,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  child: Text(
                    'Unlock',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.tertiary,
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
            builder: (context) => CardDetails(
              cardid: widget.cardnumber,
              cardtext: widget.shopName,
              cardTileColor: widget.cardTileColor,
              cardType: widget.cardType,
              hasPassword: widget.hasPassword,
              red: widget.red,
              green: widget.green,
              blue: widget.blue,
              tags: [],
              note: widget.note,
              imagePathFront: widget.imagePathFront,
              imagePathBack: widget.imagePathBack,
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
                onLongPress: widget.reorderMode ? null : () => _showBottomSheet(context),
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
                        if (widget.useFrontFaceOverlay && widget.imagePathFront.isNotEmpty)
                          FutureBuilder<bool>(
                            future: File(widget.imagePathFront).exists(),
                            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(widget.borderSize),
                                  child: Image.file(
                                    File(widget.imagePathFront),
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
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  void _showBottomSheet(BuildContext context) {
    VibrationProvider.vibrateSuccess();
    showModalBottomSheet(
      context: context,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Edit', style: Theme.of(context).textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.editFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Duplicate', style: Theme.of(context).textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.duplicateFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Move UP', style: Theme.of(context).textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.moveUpFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Move DOWN', style: Theme.of(context).textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.moveDownFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('DELETE', style: Theme.of(context).textTheme.bodyLarge?.copyWith()),
                onTap: () {
                  Navigator.pop(context);
                  widget.deleteFunction(context);
                },
              ),
              SizedBox(
                height: 70,
              )
            ],
          ),
        );
      },
    );
  }
}