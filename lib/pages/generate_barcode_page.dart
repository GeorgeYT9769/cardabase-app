import 'package:cardabase/util/button_tile.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class GenerateBarcode extends StatelessWidget {

  String cardid;
  String cardtext;
  Color iconcolor;
  String cardType;

  GenerateBarcode({super.key, required this.cardid, required this.cardtext, required this.iconcolor, required this.cardType});

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
                decoration: BoxDecoration(color: iconcolor, borderRadius: BorderRadius.circular(15)),
                child: Center(
                  child: Wrap(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 00),
                          child: Text(
                            cardtext,
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
                  decoration: BoxDecoration(color: iconcolor, borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white),
                    child: BarcodeWidget(
                      padding: const EdgeInsets.all(10),
                      data: cardid,
                      barcode: getBarcodeType(cardType), //Barcode.ean13(drawEndChar: true)
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
