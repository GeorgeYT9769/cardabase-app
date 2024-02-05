import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GenerateQR extends StatelessWidget {

  String cardid;
  String sn;
  Color iconcolor;

  GenerateQR({super.key, required this.cardid, required this.sn, required this.iconcolor});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, color: iconcolor),
            Text(
              sn,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
                fontFamily: 'Roboto-Regular.ttf',
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 120, padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white),child: BarcodeWidget(data: cardid, barcode: Barcode.ean13(drawEndChar: true), drawText: true, style: const TextStyle(color: Colors.black),),),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('DONE', style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Roboto-Regular.ttf',),))
          ],
        ),
      ),
    );
  }
}

