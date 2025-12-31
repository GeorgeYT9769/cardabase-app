import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'image_preview_screen.dart';

class CardDetails extends StatefulWidget {

  final settingsbox = Hive.box('settingsBox');

  final String cardid;
  final String cardtext;
  final Color cardTileColor;
  final String cardType;
  final bool hasPassword;
  final int red;
  final int green;
  final int blue;
  final List tags;
  final String note;
  final String imagePathFront;
  final String imagePathBack;

  CardDetails({super.key, required this.cardid, required this.cardtext, required this.cardTileColor, required this.cardType, required this.hasPassword, required this.red, required this.green, required this.blue, required this.tags, required this.note, required this.imagePathFront,required this.imagePathBack});

  @override
  State<CardDetails> createState() => _CardDetailsState();
}

class _CardDetailsState extends State<CardDetails> {

  double? _previousBrightness;
  bool setBrightness = settingsbox.get('setBrightness', defaultValue: true);

  @override
  void initState() {
    super.initState();
    if (setBrightness == false) {
      _increaseBrightness();
    }
  }

  Future<void> _increaseBrightness() async {
    _previousBrightness = await ScreenBrightness().system;
    await ScreenBrightness().setApplicationScreenBrightness(1.0);
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  Future<void> _resetBrightness() async {
    if (_previousBrightness != null) {
      await ScreenBrightness().setApplicationScreenBrightness(_previousBrightness!);
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.qr_code_2,
              color: Theme.of(context).colorScheme.secondary,),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Share', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30),),
                      content: Container(
                        height: 200,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: BarcodeWidget(
                          padding: const EdgeInsets.all(10),
                          data: '[${widget.cardtext}, ${widget.cardid}, ${widget.red}, ${widget.green}, ${widget.blue}, ${widget.cardType}, ${widget.hasPassword},${widget.tags}]',
                          barcode: Barcode.qrCode(),
                          drawText: true,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      actions: [
                        Center(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('DONE', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),),
                          ),
                        ),
                      ],
                    );
                  }
              );
            }
        ),
        actions: [
          IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: () => Navigator.of(context).pop(),),
        ],
        title: Text(
            'Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith()
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
          physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
          children: [
            Container(padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 0), child: Text(widget.cardtext, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 50))),
            SizedBox(
              height: MediaQuery.of(context).size.width / 1.586,
              width: MediaQuery.of(context).size.width,
              child: Builder(
                builder: (context) {
                  final hasFront = widget.imagePathFront != '';
                  final hasBack = widget.imagePathBack != '';
                  final pages = <Widget>[];
                  if (hasFront) {
                    pages.add(
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePreviewScreen(imagePath: widget.imagePathFront,)));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          decoration: BoxDecoration(
                            color: widget.cardTileColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(widget.imagePathFront),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  pages.add(
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePreviewScreen(barcodeData: widget.cardid, barcodeType: widget.cardType,)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        decoration: BoxDecoration(color: widget.cardTileColor, borderRadius: BorderRadius.circular(15)),
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                          ),
                          child: BarcodeWidget(
                            padding: const EdgeInsets.all(10),
                            data: widget.cardid,
                            barcode: getBarcodeType(widget.cardType),
                            drawText: true,
                            style: const TextStyle(color: Colors.black),
                            errorBuilder: (context, error) => Center(
                              child: Text(
                                'Invalid barcode data',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (hasBack) {
                    pages.add(
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePreviewScreen(imagePath: widget.imagePathBack,)));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          decoration: BoxDecoration(
                            color: widget.cardTileColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(widget.imagePathBack),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final initialPage = hasFront ? 1 : 0;
                  return PageView(
                    controller: PageController(initialPage: initialPage),
                    children: pages,
                  );
                },
              ),
            ),
            widget.note.isEmpty ? Container() : Container(
              padding: const EdgeInsets.all(20),
              child: TextField(
                enabled: false,
                maxLines: 10,
                decoration: InputDecoration(
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 15),
                  hintText: widget.note,
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                  focusColor: Theme.of(context).colorScheme.primary,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 100,)
            ]
      ),
        floatingActionButton: Bounceable(
            onTap: () {},
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: FloatingActionButton.extended(
                    elevation: 0.0,
                    heroTag: 'saveFAB',
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'SAVE',
                    backgroundColor: Colors.green.shade700,
                    icon: Icon(Icons.check, color: Colors.white,),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    label: Text('SAVE', style: Theme.of(context).textTheme.bodyLarge?.copyWith( //cardTypeText
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white
                    ),),
                  ),
                )
            )
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
