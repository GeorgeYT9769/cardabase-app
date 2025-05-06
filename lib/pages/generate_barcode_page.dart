import 'package:cardabase/pages/settings.dart';
import 'package:cardabase/util/button_tile.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GenerateBarcode extends StatefulWidget {

  final settingsbox = Hive.box('settingsBox');

  String cardid;
  String cardtext;
  Color cardTileColor;
  String cardType;
  bool hasPassword;
  int red;
  int green;
  int blue;

  GenerateBarcode({super.key, required this.cardid, required this.cardtext, required this.cardTileColor, required this.cardType, required this.hasPassword, required this.red, required this.green, required this.blue});

  @override
  State<GenerateBarcode> createState() => _GenerateBarcodeState();
}

class _GenerateBarcodeState extends State<GenerateBarcode> {

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
    try {
      // Get current brightness
      _previousBrightness = await ScreenBrightness().system;
      // Set brightness to max (1.0)
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      print("Error getting or setting brightness: $e");
    }
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  Future<void> _resetBrightness() async {
    try {
      if (_previousBrightness != null) {
        // Restore the original brightness
        await ScreenBrightness().setApplicationScreenBrightness(_previousBrightness!);
      }
    } catch (e) {
      print("Error resetting brightness: $e");
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
        return Barcode.ean13(drawEndChar: true); // Fallback barcode
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: () => Navigator.of(context).pop(),),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_2,
              color: Theme.of(context).colorScheme.secondary,),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Share'),
                      content: Container(
                        height: 200,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: BarcodeWidget(
                          padding: const EdgeInsets.all(10),
                          data: '[${widget.cardtext}, ${widget.cardid}, ${widget.red}, ${widget.green}, ${widget.blue}, ${widget.cardType}, ${widget.hasPassword}]',
                          barcode: Barcode.qrCode(), //Barcode.ean13(drawEndChar: true)
                          drawText: true,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      actions: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('DONE', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto-Regular.ttf',
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
        ],
        title: Text(
            'Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'xirod',
              letterSpacing: 8,
              color: Theme.of(context).colorScheme.tertiary,
            )
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //FRONT FACE
            SizedBox(
              height: MediaQuery.of(context).size.width / 1.50, //height of button
              width: MediaQuery.of(context).size.width,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: widget.cardTileColor, borderRadius: BorderRadius.circular(15)),
                child: Center(
                  child: Wrap(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 00),
                          child: Text(
                            widget.cardtext,
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto-Regular.ttf',
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                ),
              )
            ),
            const SizedBox(height: 10,),
            //BACK FACE
            SizedBox(
                height: MediaQuery.of(context).size.width / 1.50, //height of button
                width: MediaQuery.of(context).size.width,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: widget.cardTileColor, borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white),
                    child: BarcodeWidget(
                      padding: const EdgeInsets.all(10),
                      data: widget.cardid,
                      barcode: getBarcodeType(widget.cardType), //Barcode.ean13(drawEndChar: true)
                      drawText: true,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                )
            ),
            const SizedBox(height: 30,),
            ButtonTile(buttonText: 'DONE', buttonAction: () => Navigator.pop(context)),
            const SizedBox(height: 30,),
            ]
      ),
    );
  }
}
