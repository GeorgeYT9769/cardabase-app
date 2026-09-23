import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' as typed_data;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../feature/settings/get_it.dart';
import '../feature/settings/model.dart';
import 'expressive_loading_indicator.dart';
import 'widgets/blur_wrapper.dart';

class _OverlayItem {
  final String id;
  final String type; // 'image' or 'text'
  String? imagePath;
  String? text;
  Color color;
  Offset position;
  double scale;
  double rotation;

  _OverlayItem({
    required this.id,
    required this.type,
    this.imagePath,
    this.text,
    this.color = Colors.white,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

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
  Color? _canvasColor;
  double _brightness = 0.0;
  bool _isFlashOn = false;

  Offset _photoPosition = Offset.zero;
  double _photoScale = 1.0;
  double _photoRotation = 0.0;

  final List<_OverlayItem> _overlayItems = [];
  String? _selectedOverlayId;

  double? _verticalGuideX;
  double? _horizontalGuideY;

  Offset? _focusIndicatorPosition;
  bool _showFocusIndicator = false;
  Timer? _focusTimer;

  Offset _initialFocalPoint = Offset.zero;
  Offset _initialPosition = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

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
    if (_isFlashOn) {
      try {
        _cameraController?.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
    _focusTimer?.cancel();
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

  void _initPhotoPosition() {
    final screenSize = MediaQuery.of(context).size;
    final screenW = screenSize.width;
    final screenH = screenSize.height;

    double cutoutWidth = screenW * widget.cutoutWidthPercentage;
    double cutoutHeight = cutoutWidth / widget.cardAspectRatio;
    if (cutoutHeight > screenH * 0.7) {
      cutoutHeight = screenH * 0.7;
      cutoutWidth = cutoutHeight * widget.cardAspectRatio;
    }
    final cutoutLeft = (screenW - cutoutWidth) / 2;
    final cutoutTop = (screenH - cutoutHeight) / 2;

    _photoPosition = Offset(
      cutoutLeft - (300 - cutoutWidth) / 2,
      cutoutTop - (300 / widget.cardAspectRatio - cutoutHeight) / 2,
    );
    _photoScale = cutoutWidth / 300.0;
    _photoRotation = 0.0;
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() {
          _isFlashOn = false;
        });
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
        });
      }
    } catch (e) {
      // Ignore if flash mode isn't supported on device/emulator
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _cameraController!.takePicture();
      if (_isFlashOn) {
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (_) {}
        _isFlashOn = false;
      }
      setState(() {
        _capturedImageFile = file;
        _canvasColor = null;
        _selectedOverlayId = 'BACKGROUND_PHOTO';
        _initPhotoPosition();
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
        _canvasColor = null;
        _selectedOverlayId = 'BACKGROUND_PHOTO';
        _initPhotoPosition();
      });
    }
  }

  Future<void> _pickCanvasColorDialog() async {
    Color? chosenColor;

    final List<Map<String, dynamic>> presetColors = [
      {'name': 'Transparent', 'color': Colors.transparent},
      {'name': 'White', 'color': Colors.white},
      {'name': 'Black', 'color': Colors.black},
      {'name': 'Red', 'color': Colors.red},
      {'name': 'Amber', 'color': Colors.amber},
      {'name': 'Green', 'color': Colors.green},
      {'name': 'Blue', 'color': Colors.blue},
      {'name': 'Cyan', 'color': Colors.cyan},
      {'name': 'Purple', 'color': Colors.purple},
      {'name': 'Grey', 'color': Colors.grey},
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Canvas Color'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: presetColors.length,
              itemBuilder: (context, index) {
                final item = presetColors[index];
                final Color color = item['color'];
                final bool isTransparent = color == Colors.transparent;

                return GestureDetector(
                  onTap: () {
                    chosenColor = color;
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTransparent ? Colors.grey.shade300 : color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: isTransparent
                        ? const Icon(Icons.block, color: Colors.red, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (chosenColor != null) {
      setState(() {
        _canvasColor = chosenColor;
        _capturedImageFile = XFile('');
        _transformationController.value = Matrix4.identity();
      });
    }
  }

  Future<void> _addOverlayImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      final screenSize = MediaQuery.of(context).size;
      final newItem = _OverlayItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'image',
        imagePath: image.path,
        position: Offset(screenSize.width / 2 - 50, screenSize.height / 3),
      );
      setState(() {
        _overlayItems.add(newItem);
        _selectedOverlayId = newItem.id;
      });
    }
  }

  Future<void> _addOverlayText() async {
    final TextEditingController textController = TextEditingController();
    Color selectedColor = Colors.white;

    final List<Color> colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.amber,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    final String? resultText = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Text Overlay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter text...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: colors.map((c) {
                        final isSelected = c == selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = c;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.cyan : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, textController.text),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (resultText != null && resultText.trim().isNotEmpty) {
      final screenSize = MediaQuery.of(context).size;
      final newItem = _OverlayItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'text',
        text: resultText.trim(),
        color: selectedColor,
        position: Offset(screenSize.width / 2 - 50, screenSize.height / 3),
      );
      setState(() {
        _overlayItems.add(newItem);
        _selectedOverlayId = newItem.id;
      });
    }
  }

  double _normalizeAngle(double angle) {
    if (angle.isNaN || angle.isInfinite) return 0.0;
    double a = (angle + math.pi) % (2 * math.pi);
    if (a < 0) {
      a += 2 * math.pi;
    }
    return (a - math.pi).clamp(-math.pi, math.pi);
  }

  Size _measureItemSize(_OverlayItem item, ThemeData theme) {
    if (item.type == 'image') {
      final base = 112.0 * item.scale;
      return Size(base, base);
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: item.text ?? '',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Roboto',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = (tp.width + 12) * item.scale;
      final h = (tp.height + 12) * item.scale;
      return Size(w, h);
    }
  }

  Future<String> _cropAndSaveAdjustedImage() async {
    if (_capturedImageFile == null && _canvasColor == null) return '';
    setState(() {
      hideCutoutBorder = true;
      _selectedOverlayId = null;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    final typed_data.Uint8List? imageBytes =
        await _screenshotController.capture(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    setState(() {
      hideCutoutBorder = false;
    });
    if (imageBytes == null) return _capturedImageFile?.path ?? '';
    final fullImage = img.decodeImage(imageBytes);
    if (fullImage == null) return _capturedImageFile?.path ?? '';

    final int imgW = fullImage.width;
    final int imgH = fullImage.height;
    int cropWidth = (imgW * widget.cutoutWidthPercentage).round();
    int cropHeight = (cropWidth / widget.cardAspectRatio).round();
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
    final String path = join(
      (await getApplicationDocumentsDirectory()).path,
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(path).writeAsBytes(img.encodePng(cropped));
    return path;
  }

  Future<void> _confirmAndSavePicture() async {
    if (_capturedImageFile == null && _canvasColor == null) return;
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

  Future<void> _setFocusPoint(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final Offset localPosition = details.localPosition;
    final double x =
        (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final double y =
        (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    try {
      if (_cameraController!.value.focusPointSupported) {
        await _cameraController!.setFocusPoint(Offset(x, y));
      }
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Ignore if focus is not supported by device hardware
    }

    setState(() {
      _focusIndicatorPosition = localPosition;
      _showFocusIndicator = true;
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showFocusIndicator = false;
        });
      }
    });
  }

  void _retakePicture() {
    setState(() {
      _capturedImageFile = null;
      _canvasColor = null;
      _brightness = 0.0;
      _photoScale = 1.0;
      _photoRotation = 0.0;
      _photoPosition = Offset.zero;
      _overlayItems.clear();
      _selectedOverlayId = null;
      _verticalGuideX = null;
      _horizontalGuideY = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _OverlayItem selectedItem = _overlayItems.firstWhere(
      (item) => item.id == _selectedOverlayId,
      orElse: () => _OverlayItem(
        id: '',
        type: '',
        position: Offset.zero,
      ),
    );

    final bool isPhotoSelected = _selectedOverlayId == 'BACKGROUND_PHOTO';

    final bool inEditingMode =
        _capturedImageFile != null || _canvasColor != null;

    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, box, _) {
        final settings = box.value;
        final advancedTextures = settings.theme.advancedTextures;
        final rightBackButton = settings.theme.rightBackButton;
        final backButton = Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
          child: BlurWrapper(
            useBlur: advancedTextures,
            isCircle: true,
            blurSigma: 10,
            child: Container(
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );

        return Stack(
          children: [
            Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                forceMaterialTransparency: true,
                leading: !rightBackButton ? backButton : null,
                actions: [
                  if (rightBackButton) backButton,
                ],
                centerTitle: true,
                elevation: 0.0,
                backgroundColor: theme.colorScheme.surface,
              ),
              body: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (!inEditingMode) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapDown: (details) =>
                                _setFocusPoint(details, constraints),
                            child: Stack(
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
                                      cutoutWidthPercentage:
                                          widget.cutoutWidthPercentage,
                                      cardAspectRatio: widget.cardAspectRatio,
                                    ),
                                  ),
                                ),
                                if (_showFocusIndicator &&
                                    _focusIndicatorPosition != null)
                                  Positioned(
                                    left: _focusIndicatorPosition!.dx - 24,
                                    top: _focusIndicatorPosition!.dy - 24,
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity: _showFocusIndicator ? 1.0 : 0.0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      return Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: _canvasColor ?? Colors.black,
                          child: Stack(
                            children: [
                              if (_canvasColor == null &&
                                  _capturedImageFile != null &&
                                  _capturedImageFile!.path.isNotEmpty)
                                Positioned(
                                  left: _photoPosition.dx,
                                  top: _photoPosition.dy,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedOverlayId = 'BACKGROUND_PHOTO';
                                      });
                                    },
                                    onScaleStart: (details) {
                                      setState(() {
                                        _selectedOverlayId = 'BACKGROUND_PHOTO';
                                        _initialScale = _photoScale;
                                        _initialRotation = _photoRotation;
                                        _initialFocalPoint = details.focalPoint;
                                        _initialPosition = _photoPosition;
                                      });
                                    },
                                    onScaleUpdate: (details) {
                                      if (_selectedOverlayId ==
                                          'BACKGROUND_PHOTO') {
                                        setState(() {
                                          final rawPosition =
                                              _initialPosition +
                                                  (details.focalPoint -
                                                      _initialFocalPoint);

                                          if (details.scale != 1.0) {
                                            _photoScale = (_initialScale *
                                                    details.scale)
                                                .clamp(0.2, 4.0);
                                          }
                                          if (details.rotation != 0.0) {
                                            _photoRotation = _normalizeAngle(
                                              _initialRotation +
                                                  details.rotation,
                                            );
                                          }

                                          final screenSize =
                                              MediaQuery.of(context).size;
                                          final screenW = screenSize.width;
                                          final screenH = screenSize.height;

                                          double cutoutWidth = screenW *
                                              widget.cutoutWidthPercentage;
                                          double cutoutHeight =
                                              cutoutWidth /
                                                  widget.cardAspectRatio;
                                          if (cutoutHeight > screenH * 0.7) {
                                            cutoutHeight = screenH * 0.7;
                                            cutoutWidth = cutoutHeight *
                                                widget.cardAspectRatio;
                                          }
                                          final cutoutLeft =
                                              (screenW - cutoutWidth) / 2;
                                          final cutoutRight =
                                              cutoutLeft + cutoutWidth;
                                          final cutoutTop =
                                              (screenH - cutoutHeight) / 2;
                                          final cutoutBottom =
                                              cutoutTop + cutoutHeight;
                                          final cutoutCenterX = screenW / 2;
                                          final cutoutCenterY = screenH / 2;

                                          final photoW = 300.0 * _photoScale;
                                          final photoH = (300.0 /
                                                  widget.cardAspectRatio) *
                                              _photoScale;

                                          double newX = rawPosition.dx;
                                          double newY = rawPosition.dy;

                                          final photoCenterX =
                                              newX + photoW / 2;
                                          final photoCenterY =
                                              newY + photoH / 2;
                                          final photoLeft = newX;
                                          final photoRight = newX + photoW;
                                          final photoTop = newY;
                                          final photoBottom = newY + photoH;

                                          const threshold = 12.0;

                                          bool snapV = false;
                                          double? vLineX;

                                          bool snapH = false;
                                          double? hLineY;

                                          // Horizontal Snapping
                                          if ((photoCenterX - cutoutCenterX)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutCenterX - photoW / 2;
                                            snapV = true;
                                            vLineX = cutoutCenterX;
                                          } else if ((photoLeft - cutoutLeft)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutLeft;
                                            snapV = true;
                                            vLineX = cutoutLeft;
                                          } else if ((photoRight - cutoutRight)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutRight - photoW;
                                            snapV = true;
                                            vLineX = cutoutRight;
                                          }

                                          // Vertical Snapping
                                          if ((photoCenterY - cutoutCenterY)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutCenterY - photoH / 2;
                                            snapH = true;
                                            hLineY = cutoutCenterY;
                                          } else if ((photoTop - cutoutTop)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutTop;
                                            snapH = true;
                                            hLineY = cutoutTop;
                                          } else if ((photoBottom -
                                                      cutoutBottom)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutBottom - photoH;
                                            snapH = true;
                                            hLineY = cutoutBottom;
                                          }

                                          _photoPosition = Offset(newX, newY);
                                          _verticalGuideX =
                                              snapV ? vLineX : null;
                                          _horizontalGuideY =
                                              snapH ? hLineY : null;
                                        });
                                      }
                                    },
                                    onScaleEnd: (details) {
                                      setState(() {
                                        _verticalGuideX = null;
                                        _horizontalGuideY = null;
                                      });
                                    },
                                    child: Transform.rotate(
                                      angle: _photoRotation,
                                      alignment: Alignment.center,
                                      child: Transform.scale(
                                        scale: _photoScale,
                                        alignment: Alignment.center,
                                        child: Container(
                                          decoration: _selectedOverlayId ==
                                                      'BACKGROUND_PHOTO' &&
                                                  !hideCutoutBorder
                                              ? BoxDecoration(
                                                  border: Border.all(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: ColorFiltered(
                                            colorFilter: ColorFilter.matrix([
                                              1,
                                              0,
                                              0,
                                              0,
                                              _brightness * 255,
                                              0,
                                              1,
                                              0,
                                              0,
                                              _brightness * 255,
                                              0,
                                              0,
                                              1,
                                              0,
                                              _brightness * 255,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                            ]),
                                            child: SizedBox(
                                              width: 300,
                                              height: 300 /
                                                  widget.cardAspectRatio,
                                              child: Image.file(
                                                File(_capturedImageFile!.path),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              for (final item in _overlayItems) ...[
                                Positioned(
                                  left: item.position.dx,
                                  top: item.position.dy,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedOverlayId = item.id;
                                      });
                                    },
                                    onScaleStart: (details) {
                                      setState(() {
                                        _selectedOverlayId = item.id;
                                        _initialScale = item.scale;
                                        _initialRotation = item.rotation;
                                        _initialFocalPoint = details.focalPoint;
                                        _initialPosition = item.position;
                                      });
                                    },
                                    onScaleUpdate: (details) {
                                      if (_selectedOverlayId == item.id) {
                                        setState(() {
                                          final rawPosition =
                                              _initialPosition +
                                                  (details.focalPoint -
                                                      _initialFocalPoint);

                                          if (details.scale != 1.0) {
                                            item.scale = (_initialScale *
                                                    details.scale)
                                                .clamp(0.2, 4.0);
                                          }
                                          if (details.rotation != 0.0) {
                                            item.rotation = _normalizeAngle(
                                              _initialRotation +
                                                  details.rotation,
                                            );
                                          }

                                          final screenSize =
                                              MediaQuery.of(context).size;
                                          final screenW = screenSize.width;
                                          final screenH = screenSize.height;

                                          double cutoutWidth = screenW *
                                              widget.cutoutWidthPercentage;
                                          double cutoutHeight =
                                              cutoutWidth /
                                                  widget.cardAspectRatio;
                                          if (cutoutHeight > screenH * 0.7) {
                                            cutoutHeight = screenH * 0.7;
                                            cutoutWidth = cutoutHeight *
                                                widget.cardAspectRatio;
                                          }
                                          final cutoutLeft =
                                              (screenW - cutoutWidth) / 2;
                                          final cutoutRight =
                                              cutoutLeft + cutoutWidth;
                                          final cutoutTop =
                                              (screenH - cutoutHeight) / 2;
                                          final cutoutBottom =
                                              cutoutTop + cutoutHeight;
                                          final cutoutCenterX = screenW / 2;
                                          final cutoutCenterY = screenH / 2;

                                          final itemSize =
                                              _measureItemSize(item, theme);
                                          final itemW = itemSize.width;
                                          final itemH = itemSize.height;

                                          double newX = rawPosition.dx;
                                          double newY = rawPosition.dy;

                                          final itemCenterX = newX + itemW / 2;
                                          final itemCenterY = newY + itemH / 2;
                                          final itemLeft = newX;
                                          final itemRight = newX + itemW;
                                          final itemTop = newY;
                                          final itemBottom = newY + itemH;

                                          const threshold = 12.0;

                                          bool snapV = false;
                                          double? vLineX;

                                          bool snapH = false;
                                          double? hLineY;

                                          // Horizontal Snapping
                                          if ((itemCenterX - cutoutCenterX)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutCenterX - itemW / 2;
                                            snapV = true;
                                            vLineX = cutoutCenterX;
                                          } else if ((itemLeft - cutoutLeft)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutLeft;
                                            snapV = true;
                                            vLineX = cutoutLeft;
                                          } else if ((itemRight - cutoutRight)
                                                  .abs() <
                                              threshold) {
                                            newX = cutoutRight - itemW;
                                            snapV = true;
                                            vLineX = cutoutRight;
                                          }

                                          // Vertical Snapping
                                          if ((itemCenterY - cutoutCenterY)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutCenterY - itemH / 2;
                                            snapH = true;
                                            hLineY = cutoutCenterY;
                                          } else if ((itemTop - cutoutTop)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutTop;
                                            snapH = true;
                                            hLineY = cutoutTop;
                                          } else if ((itemBottom -
                                                      cutoutBottom)
                                                  .abs() <
                                              threshold) {
                                            newY = cutoutBottom - itemH;
                                            snapH = true;
                                            hLineY = cutoutBottom;
                                          }

                                          item.position = Offset(newX, newY);
                                          _verticalGuideX =
                                              snapV ? vLineX : null;
                                          _horizontalGuideY =
                                              snapH ? hLineY : null;
                                        });
                                      }
                                    },
                                    onScaleEnd: (details) {
                                      setState(() {
                                        _verticalGuideX = null;
                                        _horizontalGuideY = null;
                                      });
                                    },
                                    child: Transform.rotate(
                                      angle: item.rotation,
                                      alignment: Alignment.center,
                                      child: Transform.scale(
                                        scale: item.scale,
                                        alignment: Alignment.center,
                                        child: Container(
                                          decoration: _selectedOverlayId ==
                                                      item.id &&
                                                  !hideCutoutBorder
                                              ? BoxDecoration(
                                                  border: Border.all(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                )
                                              : null,
                                          padding: const EdgeInsets.all(6),
                                          child: item.type == 'image'
                                              ? Image.file(
                                                  File(item.imagePath!),
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.contain,
                                                )
                                              : Text(
                                                  item.text ?? '',
                                                  style: theme
                                                      .textTheme.titleLarge
                                                      ?.copyWith(
                                                    fontFamily: 'Roboto',
                                                    color: item.color,
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: const [
                                                      Shadow(
                                                        blurRadius: 4,
                                                        color: Colors.black,
                                                      ),
                                                      Shadow(
                                                        blurRadius: 4,
                                                        color: Colors.black,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (!hideCutoutBorder) ...[
                                if (_verticalGuideX != null)
                                  Positioned(
                                    left: _verticalGuideX! - 1,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 2,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                if (_horizontalGuideY != null)
                                  Positioned(
                                    top: _horizontalGuideY! - 1,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                              ],
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CutoutPainter(
                                      cutoutColor: widget.cutoutColor,
                                      cutoutWidthPercentage:
                                          widget.cutoutWidthPercentage,
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
              floatingActionButton: !inEditingMode
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: BlurWrapper(
                        useBlur: advancedTextures,
                        borderRadius: BorderRadius.circular(20),
                        blurSigma: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:
                                theme.colorScheme.surface.withValues(alpha: .4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(6),
                                child: IconButton(
                                  style: ButtonStyle(
                                    iconSize: const WidgetStatePropertyAll(26),
                                    iconColor: WidgetStatePropertyAll(
                                      theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.palette,
                                  ),
                                  tooltip: 'Paint Canvas',
                                  onPressed: _pickCanvasColorDialog,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(6),
                                child: IconButton(
                                  style: ButtonStyle(
                                    iconSize: const WidgetStatePropertyAll(26),
                                    iconColor: WidgetStatePropertyAll(
                                      _isFlashOn
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                  icon: Icon(
                                    _isFlashOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                  ),
                                  tooltip: _isFlashOn ? 'Flash On' : 'Flash Off',
                                  onPressed: _toggleFlash,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(6),
                                child: IconButton(
                                  style: ButtonStyle(
                                    iconSize: const WidgetStatePropertyAll(26),
                                    iconColor: WidgetStatePropertyAll(
                                      theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.photo_library,
                                  ),
                                  tooltip: 'Gallery',
                                  onPressed: () async {
                                    await _pickImageFromGallery();
                                  },
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(6),
                                child: IconButton(
                                  style: ButtonStyle(
                                    iconSize: const WidgetStatePropertyAll(26),
                                    iconColor: WidgetStatePropertyAll(
                                      theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.camera_alt,
                                  ),
                                  tooltip: 'Take Photo',
                                  onPressed: () async {
                                    try {
                                      await _initializeControllerFuture;
                                      await _takePicture();
                                    } catch (e) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: BlurWrapper(
                        useBlur: advancedTextures,
                        borderRadius: BorderRadius.circular(20),
                        blurSigma: 10.0,
                        child: Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:
                                theme.colorScheme.surface.withValues(alpha: .4),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_canvasColor == null) ...[
                                Text(
                                  'Brightness: ${_brightness.toStringAsFixed(1)}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.inverseSurface,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.brightness_6_rounded),
                                      Expanded(
                                        child: Slider(
                                          year2023: false,
                                          value: _brightness.clamp(-1.0, 1.0),
                                          min: -1.0,
                                          max: 1.0,
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
                              ],
                              if (isPhotoSelected ||
                                  selectedItem.id.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.aspect_ratio,
                                        size: 20,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          year2023: false,
                                          value: (isPhotoSelected
                                                  ? _photoScale
                                                  : selectedItem.scale)
                                              .clamp(0.2, 4.0),
                                          min: 0.2,
                                          max: 4.0,
                                          onChanged: (val) {
                                            setState(() {
                                              if (isPhotoSelected) {
                                                _photoScale = val;
                                              } else {
                                                selectedItem.scale = val;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const Icon(
                                        Icons.rotate_right,
                                        size: 20,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          year2023: false,
                                          value: _normalizeAngle(
                                            isPhotoSelected
                                                ? _photoRotation
                                                : selectedItem.rotation,
                                          ),
                                          min: -math.pi,
                                          max: math.pi,
                                          onChanged: (val) {
                                            setState(() {
                                              final norm = _normalizeAngle(val);
                                              if (isPhotoSelected) {
                                                _photoRotation = norm;
                                              } else {
                                                selectedItem.rotation = norm;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    child: IconButton(
                                      style: ButtonStyle(
                                        iconSize:
                                            const WidgetStatePropertyAll(26),
                                        iconColor: WidgetStatePropertyAll(
                                          theme.colorScheme.inverseSurface,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.palette,
                                      ),
                                      tooltip: 'Canvas Color',
                                      onPressed: _pickCanvasColorDialog,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    child: IconButton(
                                      style: ButtonStyle(
                                        iconSize:
                                            const WidgetStatePropertyAll(26),
                                        iconColor: WidgetStatePropertyAll(
                                          theme.colorScheme.inverseSurface,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                      ),
                                      tooltip: 'Add Image Overlay',
                                      onPressed: _addOverlayImage,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    child: IconButton(
                                      style: ButtonStyle(
                                        iconSize:
                                            const WidgetStatePropertyAll(26),
                                        iconColor: WidgetStatePropertyAll(
                                          theme.colorScheme.inverseSurface,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.text_fields,
                                      ),
                                      tooltip: 'Add Text Overlay',
                                      onPressed: _addOverlayText,
                                    ),
                                  ),
                                  if (_selectedOverlayId != null) ...[
                                    if (!isPhotoSelected) ...[
                                      Container(
                                        margin: const EdgeInsets.all(6),
                                        child: IconButton(
                                          style: ButtonStyle(
                                            iconSize:
                                                const WidgetStatePropertyAll(
                                              26,
                                            ),
                                            iconColor: WidgetStatePropertyAll(
                                              theme.colorScheme.error,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete Overlay',
                                          onPressed: () {
                                            setState(() {
                                              _overlayItems.removeWhere(
                                                (i) =>
                                                    i.id == _selectedOverlayId,
                                              );
                                              _selectedOverlayId = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                    Container(
                                      margin: const EdgeInsets.all(6),
                                      child: IconButton(
                                        style: ButtonStyle(
                                          iconSize:
                                              const WidgetStatePropertyAll(26),
                                          iconColor: WidgetStatePropertyAll(
                                            theme.colorScheme.primary,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        tooltip: 'Confirm Additions',
                                        onPressed: () {
                                          setState(() {
                                            _selectedOverlayId = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      margin: const EdgeInsets.all(6),
                                      child: IconButton(
                                        style: ButtonStyle(
                                          iconSize:
                                              const WidgetStatePropertyAll(26),
                                          iconColor: WidgetStatePropertyAll(
                                            theme.colorScheme.inverseSurface,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.refresh,
                                        ),
                                        tooltip: 'Retake',
                                        onPressed: _retakePicture,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(6),
                                      child: IconButton(
                                        style: ButtonStyle(
                                          iconSize:
                                              const WidgetStatePropertyAll(26),
                                          iconColor: WidgetStatePropertyAll(
                                            theme.colorScheme.inverseSurface,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.check,
                                        ),
                                        tooltip: 'Use Image',
                                        onPressed: _confirmAndSavePicture,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            ),
            if (_isSaving)
              Positioned.fill(
                child: BlurWrapper(
                  useBlur: advancedTextures,
                  blurSigma: 10.0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: ExpressiveLoadingIndicator(
                        color: theme.colorScheme.tertiary,
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
              ),
          ],
        );
      },
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
