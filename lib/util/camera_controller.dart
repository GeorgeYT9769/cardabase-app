import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'expressive_loading_indicator.dart';

class CameraControllerScreen extends StatefulWidget {
  final Color cutoutColor;
  final double cutoutWidthPercentage;
  final double cardAspectRatio;

  const CameraControllerScreen({
    super.key,
    this.cutoutColor = const Color(0xFF1960A5),
    this.cutoutWidthPercentage = 0.9,
    this.cardAspectRatio =
        1.586, // Common aspect ratio for credit cards (85.60 mm × 53.98 mm)
  });

  @override
  State<CameraControllerScreen> createState() => _CameraControllerScreenState();
}

class _CameraControllerScreenState extends State<CameraControllerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImageFile;
  double _brightness = 0.0;

  final TransformationController _transformationController =
      TransformationController();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool hideCutoutBorder = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      return;
    }
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _capturedImageFile = file;
        _transformationController.value = Matrix4.identity(); // Start zoomed in, allow zooming out
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _capturedImageFile = image;
        _transformationController.value = Matrix4.identity(); // Start zoomed in, allow zooming out
      });
    }
  }

  Future<String> _cropAndSaveAdjustedImage() async {
    if (_capturedImageFile == null) return _capturedImageFile!.path;
    setState(() {
      hideCutoutBorder = true;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    final typed_data.Uint8List? imageBytes =
        await _screenshotController.capture(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    setState(() {
      hideCutoutBorder = false;
    });
    if (imageBytes == null) return _capturedImageFile!.path;
    final fullImage = img.decodeImage(imageBytes);
    if (fullImage == null) return _capturedImageFile!.path;

    // Derive crop region directly from the captured image's own pixel dimensions.
    // This mirrors the painter's percentage-based logic in pixel space, so X and Y
    // are always aligned with the cutout overlay — no RenderBox/devicePixelRatio drift.
    final int imgW = fullImage.width;
    final int imgH = fullImage.height;
    int cropWidth = (imgW * widget.cutoutWidthPercentage).round();
    int cropHeight = (cropWidth / widget.cardAspectRatio).round();
    // Apply the same clamping as the painter
    if (cropHeight > (imgH * 0.7).round()) {
      cropHeight = (imgH * 0.7).round();
      cropWidth = (cropHeight * widget.cardAspectRatio).round();
    }
    final int cropX = ((imgW - cropWidth) / 2).round();
    final int cropY = ((imgH - cropHeight) / 2).round();

    final img.Image cropped = img.copyCrop(
      fullImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
    // Save to permanent storage
    final String path = join(
      (await getApplicationDocumentsDirectory()).path,
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(path).writeAsBytes(img.encodePng(cropped));
    return path;
  }

  Future<void> _confirmAndSavePicture() async {
    if (_capturedImageFile == null) return;
    setState(() {
      _isSaving = true;
    });
    try {
      final String croppedPath = await _cropAndSaveAdjustedImage();
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Navigator.pop(context);
      }
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImageFile = null;
      _brightness = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            forceMaterialTransparency: true,
            actions: [
              Container(
                margin: EdgeInsets.fromLTRB(0,5,5,0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: .4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  style: ButtonStyle(
                    iconSize: const WidgetStatePropertyAll(24),
                    iconColor: WidgetStatePropertyAll(
                      theme.colorScheme.inverseSurface,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: theme.colorScheme.surface,
          ),
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_capturedImageFile == null) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: AspectRatio(
                          aspectRatio: widget.cardAspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CutoutPainter(
                            cutoutColor: widget.cutoutColor,
                            cutoutWidthPercentage: widget.cutoutWidthPercentage,
                            cardAspectRatio: widget.cardAspectRatio,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Screenshot(
                    controller: _screenshotController,
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.1,
                            maxScale: 5.0,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix([
                                1, 0, 0, 0, _brightness * 255,
                                0, 1, 0, 0, _brightness * 255,
                                0, 0, 1, 0, _brightness * 255,
                                0, 0, 0, 1, 0,
                              ]),
                              child: SizedBox.expand(
                                child: Image.file(
                                  File(_capturedImageFile!.path),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CutoutPainter(
                                cutoutColor: widget.cutoutColor,
                                cutoutWidthPercentage: widget.cutoutWidthPercentage,
                                cardAspectRatio: widget.cardAspectRatio,
                                shouldDrawDarkOverlay: false,
                                hideBorder: hideCutoutBorder,
                                cutoutYOffset: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  );
                }
              } else {
                return Center(
                  child: ExpressiveLoadingIndicator(
                    color: Theme.of(context).colorScheme.tertiary,
                    constraints: const BoxConstraints(
                      minWidth: 64.0,
                      minHeight: 64.0,
                      maxWidth: 64.0,
                      maxHeight: 64.0,
                    ),
                    polygons: [
                      MaterialShapes.softBurst,
                      MaterialShapes.pentagon,
                      MaterialShapes.pill,
                    ],
                    semanticsLabel: 'Loading',
                    semanticsValue: 'In progress',
                  ),
                );
              }
            },
          ),
          floatingActionButton: _capturedImageFile == null
              ? Container(
                margin: const EdgeInsets.symmetric(vertical: 10), // Only vertical margin
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: .4),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min, // Make row as slim as possible
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'selectFromGallery',
                        onPressed: () async {
                          await _pickImageFromGallery();
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(
                          Icons.photo_library,
                          size: 30,
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      FloatingActionButton(
                        heroTag: 'takePhoto',
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture;
                            await _takePicture();
                          } catch (e) {
                            Navigator.pop(context);
                          }
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
              )
              : Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: .4),
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Brightness: ${_brightness.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.inverseSurface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.brightness_6_rounded),
                            Expanded(
                              child: Slider(
                                value: _brightness,
                                year2023: false,
                                min: -1.0,
                                max: 1.0,
                                //activeColor: widget.cutoutColor,
                                onChanged: (value) {
                                  setState(() {
                                    _brightness = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: 'retakePhoto',
                            onPressed: _retakePicture,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: const Icon(
                              Icons.refresh,
                              size: 30,
                            ),
                          ),
                          FloatingActionButton(
                            heroTag: 'usePhoto',
                            onPressed: _confirmAndSavePicture,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: const Icon(
                              Icons.check,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
        if (_isSaving)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: ExpressiveLoadingIndicator(
                  color: Theme.of(context).colorScheme.tertiary,
                  constraints: const BoxConstraints(
                    minWidth: 64.0,
                    minHeight: 64.0,
                    maxWidth: 64.0,
                    maxHeight: 64.0,
                  ),
                  polygons: [
                    MaterialShapes.softBurst,
                    MaterialShapes.pentagon,
                    MaterialShapes.pill,
                  ],
                  semanticsLabel: 'Saving',
                  semanticsValue: 'Saving image',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final Color cutoutColor;
  final double cutoutWidthPercentage;
  final double cardAspectRatio;
  final bool shouldDrawDarkOverlay;
  final bool hideBorder;
  final double cutoutYOffset;

  _CutoutPainter({
    required this.cutoutColor,
    required this.cutoutWidthPercentage,
    required this.cardAspectRatio,
    this.shouldDrawDarkOverlay = true,
    this.hideBorder = false,
    this.cutoutYOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    double cutoutWidth = screenWidth * cutoutWidthPercentage;
    double cutoutHeight = cutoutWidth / cardAspectRatio;
    if (cutoutHeight > screenHeight * 0.7) {
      cutoutHeight = screenHeight * 0.7;
      cutoutWidth = cutoutHeight * cardAspectRatio;
    }
    final double offsetX = (screenWidth - cutoutWidth) / 2;
    final double offsetY = (screenHeight - cutoutHeight) / 2 + cutoutYOffset;
    final Rect cutoutRect =
        Rect.fromLTWH(offsetX, offsetY, cutoutWidth, cutoutHeight);
    if (shouldDrawDarkOverlay) {
      final Paint backgroundPaint = Paint()
        ..color = Colors.black.withValues(alpha: .5)
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight)),
          Path()
            ..addRRect(
              RRect.fromRectAndRadius(cutoutRect, const Radius.circular(15)),
            ),
        ),
        backgroundPaint,
      );
    }
    if (!hideBorder) {
      final Paint borderPaint = Paint()
        ..color = cutoutColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(15)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) {
    return oldDelegate.cutoutColor != cutoutColor ||
        oldDelegate.cutoutWidthPercentage != cutoutWidthPercentage ||
        oldDelegate.cardAspectRatio != cardAspectRatio ||
        oldDelegate.shouldDrawDarkOverlay != shouldDrawDarkOverlay ||
        oldDelegate.hideBorder != hideBorder ||
        oldDelegate.cutoutYOffset != cutoutYOffset;
  }
}
