import 'dart:io';
import 'dart:typed_data';

import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:zxing2/qrcode.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        actions: [
          Container(
            margin: EdgeInsets.fromLTRB(0,5,15,0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: .4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              style: ButtonStyle(
                iconSize: const WidgetStatePropertyAll(30),
                iconColor: WidgetStatePropertyAll(
                  theme.colorScheme.inverseSurface,
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                controller?.pauseCamera();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface.withValues(alpha: .4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              child: IconButton(
                style: ButtonStyle(
                  iconSize: const WidgetStatePropertyAll(30),
                  iconColor: WidgetStatePropertyAll(
                    theme.colorScheme.inverseSurface,
                  ),
                ),
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
                style: ButtonStyle(
                  iconSize: const WidgetStatePropertyAll(30),
                  iconColor: WidgetStatePropertyAll(
                    theme.colorScheme.inverseSurface,
                  ),
                ),
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
                style: ButtonStyle(
                  iconSize: const WidgetStatePropertyAll(30),
                  iconColor: WidgetStatePropertyAll(
                    theme.colorScheme.inverseSurface,
                  ),
                ),
                icon: const Icon(Icons.photo),
                onPressed: _pickImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    final scanArea = (MediaQuery.of(context).size.width < 400 ||
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
      return;
    }
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (!mounted) {
        return;
      }

      setState(() {
        result = scanData;
      });
      await this.controller?.pauseCamera();

      if (mounted) {
        Navigator.pop(context, {
          'code': result?.code,
          'format': result?.format.toString(),
        });
      }
    });
  }

  Future<String?> decodeImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(bytes));
      if (image != null) {
        final LuminanceSource source = RGBLuminanceSource(
          image.width,
          image.height,
          image
              .convert(numChannels: 4)
              .getBytes(order: img.ChannelOrder.abgr)
              .buffer
              .asInt32List(),
        );

        final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        final reader = QRCodeReader();
        final result = reader.decode(bitmap);
        return result.text;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    final bytes = await imageFile.readAsBytes();
    final decodedResult = await decodeImage(bytes);

    if (!mounted) {
      return;
    }

    if (decodedResult != null) {
      Navigator.pop(context, {
        'code': decodedResult,
        'format': 'QR_CODE',
      });
    } else {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Error', false),
      );
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      if (!_permissionDeniedShown) {
        GetIt.I<VibrationProvider>().vibrateError();
        controller?.pauseCamera();
        Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar('No camera permission!', false),
          );
          setState(() {
            _permissionDeniedShown = true;
          });
        }
      }
    } else if (_permissionDeniedShown && mounted) {
      setState(() {
        _permissionDeniedShown = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
