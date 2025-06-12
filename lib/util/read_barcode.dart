import 'dart:developer';
import 'dart:io';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRBarReader extends StatefulWidget {
  const QRBarReader({super.key});

  @override
  State<StatefulWidget> createState() => _QRBarReaderState();
}

class _QRBarReaderState extends State<QRBarReader> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
            children: <Widget>[
              Expanded(flex: 4, child: _buildQrView(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: const ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
                      icon: const Icon(Icons.cameraswitch),
                      onPressed: () async {
                        await controller?.flipCamera();
                        setState(() {});
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: const ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
                      icon: const Icon(Icons.flash_on),
                      onPressed: () async {
                        await controller?.toggleFlash();
                        setState(() {});
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: const ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              )
            ]
        )
    );

  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 400.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Color(0xFF1960A5),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }


  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      await controller.pauseCamera();
      Navigator.pop(context, {
        "code": result!.code,
        "format": result!.format.toString(), // Convert format to string if needed
      });
    });
  }


  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      VibrationProvider.vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: const Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'No permission!',
                  style: TextStyle(
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
          )
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}