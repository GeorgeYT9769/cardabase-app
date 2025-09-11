import 'dart:developer';
import 'dart:io';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class QRBarReader extends StatefulWidget {
  const QRBarReader({super.key});

  @override
  State<StatefulWidget> createState() => _QRBarReaderState();
}

class _QRBarReaderState extends State<QRBarReader> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool _permissionDeniedShown = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    _permissionDeniedShown = false;
    log('QRBarReader initState called.');
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
                      style: ButtonStyle(iconSize: WidgetStatePropertyAll(30), iconColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.inverseSurface)),
                      icon: const Icon(Icons.cameraswitch),
                      onPressed: () async {
                        await controller?.flipCamera();
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: ButtonStyle(iconSize: WidgetStatePropertyAll(30), iconColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.inverseSurface)),
                      icon: const Icon(Icons.flash_on),
                      onPressed: () async {
                        await controller?.toggleFlash();
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: ButtonStyle(iconSize: WidgetStatePropertyAll(30), iconColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.inverseSurface)),
                      icon: const Icon(Icons.photo),
                      onPressed: _pickImage,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: IconButton(
                      style: ButtonStyle(iconSize: WidgetStatePropertyAll(30), iconColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.inverseSurface)),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () {
                        controller?.pauseCamera();
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
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 400.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFF1960A5),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    if (!mounted) {
      log('QRView created, but widget not mounted. Skipping controller assignment.');
      return;
    }
    setState(() {
      this.controller = controller;
    });
    log('QRView controller assigned.');

    controller.scannedDataStream.listen((scanData) async {
      if (!mounted) {
        log('Scanned data received, but widget not mounted. Skipping.');
        return;
      }

      setState(() {
        result = scanData;
      });
      log('QR code scanned: ${scanData.code}');

      await this.controller?.pauseCamera();

      if (mounted) {
        Navigator.pop(context, {
          "code": result?.code,
          "format": result?.format.toString(),
        });
      }
    });
  }

  Future<String?> decodeImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(bytes));
      if (image != null) {
        LuminanceSource source = RGBLuminanceSource(
          image.width,
          image.height,
          image
              .convert(numChannels: 4)
              .getBytes(
              order: img.ChannelOrder.abgr)
              .buffer
              .asInt32List(),
        );

        var bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        var reader = QRCodeReader();
        var result = reader.decode(bitmap);
        return result.text;
      } else {
        return null;
      }
    } catch (e) {
      log('Error decoding image from gallery: $e');
      return null;
    }
  }

  void _pickImage () async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    final bytes = await imageFile.readAsBytes();
    final decodedResult = await decodeImage(bytes);

    if (!mounted) {
      log('Image picked and decoded, but widget not mounted. Skipping navigation/snackbar.');
      return;
    }

    if (decodedResult != null) {
      log('Image decoded successfully: $decodedResult');
      Navigator.pop(context, {
        "code": decodedResult,
        "format": "QR_CODE",
      });
    } else {
      VibrationProvider.vibrateError();
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
                  'Error!',
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

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('onPermissionSet called: permission = $p, _permissionDeniedShown = $_permissionDeniedShown, mounted = $mounted');

    if (!p) {
      if (!_permissionDeniedShown) {
        VibrationProvider.vibrateError();
        if (mounted) {
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
                      'No camera permission!',
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
          setState(() {
            _permissionDeniedShown = true;
          });
          log('Permission denied message shown. _permissionDeniedShown set to true.');

          if (mounted) {
            log('Permission denied, closing scanner.');
          }
        } else {
          log('Widget not mounted, skipping snackbar for permission denial.');
        }
      } else {
        log('Permission denied, but message already shown. Skipping duplicate snackbar.');
      }
    } else {
      if (_permissionDeniedShown) {
        if (mounted) {
          setState(() {
            _permissionDeniedShown = false;
          });
          log('Permission granted. _permissionDeniedShown reset to false.');
        } else {
          log('Widget not mounted, skipping _permissionDeniedShown reset.');
        }
      } else {
        log('Permission granted, and message was not previously shown. No action needed.');
      }
    }
  }

  @override
  void dispose() {
    log('QRBarReader dispose called. Disposing controller.');
    controller?.dispose();
    super.dispose();
  }
}