import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' as typed_data;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
import 'card_cropper.dart';
import 'expressive_loading_indicator.dart';
import 'widgets/blur_wrapper.dart';
import 'widgets/labeled_icon_button.dart';

enum _PhotoFitMode { custom, fit, fill }
enum _ActiveControlMode { none, brightness, size, rotation }

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

  /// When set, the screen opens straight in the editor with this image
  /// (already cropped by the caller) and never starts the camera.
  final XFile? initialImage;

  const CameraControllerScreen({
    super.key,
    this.initialImage,
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

  Offset _photoPosition = Offset.zero;
  double _photoScale = 1.0;
  double _photoRotation = 0.0;
  _ActiveControlMode _activeControlMode = _ActiveControlMode.none;
  String? _statusMessage;

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
  bool _isFlashOn = false;

  _PhotoFitMode _fitMode = _PhotoFitMode.custom;
  bool _rotationSnapped = false;
  bool _cropperOpen = false;

  /// The photo that was handed to the cropper (camera flow). "Back" in the
  /// editor returns to the cropper with this photo instead of leaving.
  XFile? _cropSourceFile;

  static const double _maxScale = 6.0;
  static const double _snapThreshold = 0.06; // ~3.4 degrees

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialImage != null) {
      // Editor-only flow (image already cropped by the caller): the camera is
      // never opened.
      _capturedImageFile = widget.initialImage;
      _initializeControllerFuture = Future<void>.value();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyPhotoFit(_PhotoFitMode.fill);
      });
    } else {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) return;
    _cameras ??= await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      return;
    }
    final controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _cameraController = controller;
    _initializeControllerFuture = controller.initialize();
    if (!mounted) return;
    setState(() {});
  }

  /// Fully releases the camera (turns off the Android camera-in-use
  /// indicator). Called as soon as the camera is no longer needed, i.e. after
  /// a photo is taken, a gallery image is picked or a canvas color is chosen.
  Future<void> _releaseCamera() async {
    final controller = _cameraController;
    if (controller == null) return;
    _cameraController = null;
    _initializeControllerFuture = Future<void>.value();
    if (_isFlashOn) {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
      _isFlashOn = false;
    }
    if (mounted) setState(() {});
    // Wait for a frame so CameraPreview is no longer in the tree before the
    // controller is disposed.
    await WidgetsBinding.instance.endOfFrame;
    try {
      await controller.dispose();
    } catch (_) {}
  }

  bool get _inEditingMode => _capturedImageFile != null || _canvasColor != null;

  /// Lets the user mark the card corners (auto-detected first). "Done" uses
  /// the cut-out card as the final picture, "Edit more" continues in
  /// the editor.
  Future<void> _openCropper(XFile file) async {
    _cropSourceFile = file;
    _cropperOpen = true;
    if (mounted) setState(() {});
    final CardCropResult? result = await Navigator.of(context).push<CardCropResult>(
      MaterialPageRoute(
        builder: (_) => CardCropScreen(imagePath: file.path),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      // Cancelled: back to the live camera.
      _cropperOpen = false;
      _retakePicture();
      return;
    }
    if (!result.edit) {
      await _finishWithoutEditing(result.path);
      return;
    }
    _cropperOpen = false;
    setState(() {
      _capturedImageFile = XFile(result.path);
      _canvasColor = null;
      _selectedOverlayId = null;
      _fitMode = _PhotoFitMode.custom;
      _initPhotoPosition();
    });
    await _applyPhotoFit(_PhotoFitMode.fill);
  }

  /// Uses the cropped card as the final picture without opening the editor.
  Future<void> _finishWithoutEditing(String sourcePath) async {
    try {
      final String path = join(
        (await getApplicationDocumentsDirectory()).path,
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await File(sourcePath).copy(path);
      if (mounted) Navigator.pop(context, path);
    } catch (_) {
      if (mounted) Navigator.pop(context, sourcePath);
    }
  }

  void _haptic() {
    HapticFeedback.selectionClick();
  }

  /// Snaps angles close to 0/90/180/270 degrees and gives a small vibration
  /// when the snap point is entered.
  double _snapRotation(double angle) {
    final a = _normalizeAngle(angle);
    final nearest = (a / (math.pi / 2)).roundToDouble() * (math.pi / 2);
    if ((a - nearest).abs() < _snapThreshold) {
      if (!_rotationSnapped) {
        _rotationSnapped = true;
        _haptic();
      }
      return _normalizeAngle(nearest);
    }
    _rotationSnapped = false;
    return a;
  }

  Future<Size?> _readImageSize(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Size _cutoutSize(Size screen) {
    double w = screen.width * widget.cutoutWidthPercentage;
    double h = w / widget.cardAspectRatio;
    if (h > screen.height * 0.7) {
      h = screen.height * 0.7;
      w = h * widget.cardAspectRatio;
    }
    return Size(w, h);
  }

  /// Centers the background photo in the frame and scales it so that it
  /// either fills the whole frame (fill) or is fully visible inside it (fit).
  Future<void> _applyPhotoFit(_PhotoFitMode mode) async {
    final file = _capturedImageFile;
    if (file == null || file.path.isEmpty || _canvasColor != null) return;
    final imageSize = await _readImageSize(file.path);
    if (!mounted || imageSize == null) return;
    final screen = MediaQuery.of(context).size;
    final cutout = _cutoutSize(screen);

    // Size of the image as drawn at scale 1 (BoxFit.contain in the screen).
    final r = math.min(
      screen.width / imageSize.width,
      screen.height / imageSize.height,
    );
    final dispW = imageSize.width * r;
    final dispH = imageSize.height * r;
    final c = math.cos(_photoRotation).abs();
    final sn = math.sin(_photoRotation).abs();

    double scale;
    if (mode == _PhotoFitMode.fill) {
      final hx = (cutout.width * c + cutout.height * sn) / 2;
      final hy = (cutout.width * sn + cutout.height * c) / 2;
      scale = math.max(2 * hx / dispW, 2 * hy / dispH);
    } else {
      scale = math.min(
        cutout.width / (dispW * c + dispH * sn),
        cutout.height / (dispW * sn + dispH * c),
      );
    }
    setState(() {
      _photoScale = scale.clamp(0.2, _maxScale);
      _photoPosition = Offset.zero;
      _fitMode = mode;
    });
  }

  void _rotatePhotoBy(double delta) {
    _haptic();
    setState(() {
      _photoRotation = _normalizeAngle(_photoRotation + delta);
      _rotationSnapped = true;
    });
    if (_fitMode != _PhotoFitMode.custom) {
      _applyPhotoFit(_fitMode);
    }
  }

  /// Resets everything done in the editor (brightness, photo position, size
  /// and rotation, texts and stickers). Leaving the editor is done with the
  /// back button.
  Future<void> _resetEditor() async {
    _haptic();
    setState(() {
      _brightness = 0.0;
      _photoRotation = 0.0;
      _photoScale = 1.0;
      _photoPosition = Offset.zero;
      _rotationSnapped = false;
      _overlayItems.clear();
      _selectedOverlayId = null;
      _verticalGuideX = null;
      _horizontalGuideY = null;
      _fitMode = _PhotoFitMode.custom;
      _activeControlMode = _ActiveControlMode.none;
      _statusMessage = null;
    });
    await _applyPhotoFit(_PhotoFitMode.fill);
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release the camera whenever the app is in the background.
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Only (re)open the camera if we are actually in camera mode.
      if (!_inEditingMode && !_cropperOpen && widget.initialImage == null) {
        _initializeCamera();
      }
    }
  }

  void _initPhotoPosition() {
    _photoPosition = Offset.zero;
    _photoScale = 1.0;
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
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await controller.takePicture();
      if (!mounted) return;
      // The camera is not needed any more: release it so the system
      // "camera in use" indicator disappears and the device stops heating up.
      await _releaseCamera();
      if (!mounted) return;
      await _openCropper(file);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      await _releaseCamera();
      if (!mounted) return;
      await _openCropper(image);
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
          title: const Text('Canvas Color'),
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
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: Theme.of(context).outlinedButtonTheme.style?.copyWith(),
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
      await _releaseCamera();
    }
  }

  Future<void> _addOverlayImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      final screenSize = MediaQuery.of(context).size;
      const itemSize = 112.0;
      final newItem = _OverlayItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'image',
        imagePath: image.path,
        position: Offset((screenSize.width - itemSize) / 2, (screenSize.height - itemSize) / 2),
      );
      setState(() {
        _overlayItems.add(newItem);
        _selectedOverlayId = newItem.id;
        _activeControlMode = _ActiveControlMode.size;
        _statusMessage = 'Image overlay added';
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
              title: const Text('Text'),
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
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: Theme.of(context).outlinedButtonTheme.style?.copyWith(),
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, textController.text),
                  style: Theme.of(context).outlinedButtonTheme.style?.copyWith(),
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
      final theme = Theme.of(context);
      final newItem = _OverlayItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'text',
        text: resultText.trim(),
        color: selectedColor,
        position: Offset.zero,
      );
      final itemSize = _measureItemSize(newItem, theme);
      newItem.position = Offset(
        (screenSize.width - itemSize.width) / 2,
        (screenSize.height - itemSize.height) / 2,
      );
      setState(() {
        _overlayItems.add(newItem);
        _selectedOverlayId = newItem.id;
        _activeControlMode = _ActiveControlMode.size;
        _statusMessage = 'Text overlay added';
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

  Widget _buildLiveCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final previewSize = _cameraController!.value.previewSize;
    if (previewSize != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    final aspect = _cameraController!.value.aspectRatio;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 100,
          height: 100 * aspect,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  void _retakePicture() {
    if (widget.initialImage != null) {
      // Opened from the gallery: go back so the user can choose again.
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _cropSourceFile = null;
      _fitMode = _PhotoFitMode.custom;
      _rotationSnapped = false;
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
    // Camera was released after the previous capture; start it again.
    _initializeCamera();
  }

  /// In the camera flow the editor was reached through the cropper, so "back"
  /// goes back to the cropper (same photo) instead of leaving everything.
  bool get _backReturnsToCropper =>
      widget.initialImage == null &&
      _cropSourceFile != null &&
      _capturedImageFile != null &&
      _canvasColor == null &&
      !_cropperOpen;

  void _handleBack() {
    if (_backReturnsToCropper) {
      _openCropper(_cropSourceFile!);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_cropperOpen) {
      // The cropper sits above this route. Render a neutral backdrop so no
      // camera UI flashes while the cropper opens or closes.
      return const Scaffold(backgroundColor: Colors.black);
    }

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
    // Photo tools apply to the background photo when it (or nothing) is selected.
    final bool isPhotoTarget = isPhotoSelected || _selectedOverlayId == null;

    final bool inEditingMode =
        _capturedImageFile != null || _canvasColor != null;

    return PopScope(
      canPop: !_backReturnsToCropper,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: ValueListenableBuilder(
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
                onPressed: _handleBack,
              ),
            ),
          ),
        );

        return Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: false,
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
                                  child: _buildLiveCameraPreview(),
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
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: constraints.maxHeight / 2 +
                                      _cutoutSize(
                                        Size(
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        ),
                                      ).height /
                                          2 +
                                      8,
                                  child: IgnorePointer(
                                    child: Text(
                                      'Place the card in view.\n'
                                          'You can mark its corners after taking the photo.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
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
                                Positioned.fill(
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
                                                .clamp(0.2, _maxScale);
                                            _fitMode = _PhotoFitMode.custom;
                                          }
                                          if (details.rotation != 0.0) {
                                            _photoRotation = _snapRotation(
                                              _initialRotation +
                                                  details.rotation,
                                            );
                                            _fitMode = _PhotoFitMode.custom;
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

                                          final photoW = screenW * _photoScale;
                                          final photoH = screenH * _photoScale;

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
                                          _fitMode = _PhotoFitMode.custom;
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
                                    child: Transform.translate(
                                      offset: _photoPosition,
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
                                              child: SizedBox.expand(
                                                child: Image.file(
                                                  File(_capturedImageFile!.path),
                                                  fit: BoxFit.contain,
                                                ),
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
                                  left: item.position.dx +
                                      ((_measureItemSize(item, theme).width /
                                          item.scale) *
                                          (item.scale - 1)) /
                                          2,
                                  top: item.position.dy +
                                      ((_measureItemSize(item, theme).height /
                                          item.scale) *
                                          (item.scale - 1)) /
                                          2,
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
                                                .clamp(0.2, _maxScale);
                                          }
                                          if (details.rotation != 0.0) {
                                            item.rotation = _snapRotation(
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
                padding: const EdgeInsets.only(
                  bottom: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.large(

                      heroTag: 'takePhotoShutter',
                      elevation: 4,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: const CircleBorder(),
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          await _takePicture();
                        } catch (e) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Icon(
                        Icons.camera_alt,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlurWrapper(
                      useBlur: advancedTextures,
                      borderRadius: BorderRadius.circular(15),
                      blurSigma: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: theme.colorScheme.surface
                              .withValues(alpha: .4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(2),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
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
                                tooltip: 'Paint Canvas',
                                onPressed: _pickCanvasColorDialog,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(2),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                style: ButtonStyle(
                                  iconSize:
                                  const WidgetStatePropertyAll(26),
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
                                tooltip:
                                _isFlashOn ? 'Flash On' : 'Flash Off',
                                onPressed: _toggleFlash,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(2),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                style: ButtonStyle(
                                  iconSize:
                                  const WidgetStatePropertyAll(26),
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
                          ],
                        ),
                      ),
                    ),
                  ],
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
                        if (_activeControlMode == _ActiveControlMode.brightness && _canvasColor == null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 2.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.brightness_6_rounded, size: 22),
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
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _brightness = 0.0;
                                    });
                                  },
                                  child: Text(
                                    _brightness.toStringAsFixed(1),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_activeControlMode == _ActiveControlMode.size) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 2.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.aspect_ratio, size: 22),
                                Expanded(
                                  child: Slider(
                                    year2023: false,
                                    value: (isPhotoSelected
                                        ? _photoScale
                                        : selectedItem.scale)
                                        .clamp(0.2, _maxScale),
                                    min: 0.2,
                                    max: _maxScale,
                                    onChanged: (val) {
                                      setState(() {
                                        if (isPhotoSelected) {
                                          _photoScale = val;
                                          _fitMode = _PhotoFitMode.custom;
                                        } else {
                                          selectedItem.scale = val;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isPhotoSelected) {
                                        _photoScale = 1.0;
                                      } else {
                                        selectedItem.scale = 1.0;
                                      }
                                    });
                                  },
                                  child: Text(
                                    '${((isPhotoSelected ? _photoScale : selectedItem.scale) * 100).round()}%',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_activeControlMode == _ActiveControlMode.rotation) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 2.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.screen_rotation, size: 22),
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
                                        final norm = _snapRotation(val);
                                        if (isPhotoSelected) {
                                          _photoRotation = norm;
                                          _fitMode = _PhotoFitMode.custom;
                                        } else {
                                          selectedItem.rotation = norm;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isPhotoSelected) {
                                        _photoRotation = 0.0;
                                      } else {
                                        selectedItem.rotation = 0.0;
                                      }
                                    });
                                  },
                                  child: Text(
                                    '${(_normalizeAngle(isPhotoSelected ? _photoRotation : selectedItem.rotation) * 180 / math.pi).round()}°',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.inverseSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              _statusMessage ?? 'Tap an action below to edit photo',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.inverseSurface,
                              ),
                            ),
                          ),
                        ],
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              if (_selectedOverlayId != null && !isPhotoSelected) ...[
                                LabeledIconButton(
                                  icon: Icons.aspect_ratio,
                                  label: 'Size',
                                  isSelected: _activeControlMode == _ActiveControlMode.size,
                                  onPressed: () {
                                    setState(() {
                                      _activeControlMode = _activeControlMode == _ActiveControlMode.size
                                          ? _ActiveControlMode.none
                                          : _ActiveControlMode.size;
                                    });
                                  },
                                ),
                                LabeledIconButton(
                                  icon: Icons.screen_rotation,
                                  label: 'Rotation',
                                  isSelected: _activeControlMode == _ActiveControlMode.rotation,
                                  onPressed: () {
                                    setState(() {
                                      _activeControlMode = _activeControlMode == _ActiveControlMode.rotation
                                          ? _ActiveControlMode.none
                                          : _ActiveControlMode.rotation;
                                    });
                                  },
                                ),
                                LabeledIconButton(
                                  icon: Icons.rotate_left,
                                  label: 'Rotate L',
                                  tooltip: 'Rotate overlay 90° left',
                                  onPressed: () {
                                    setState(() {
                                      selectedItem.rotation = _normalizeAngle(selectedItem.rotation - math.pi / 2);
                                      _activeControlMode = _ActiveControlMode.none;
                                      _statusMessage = 'Rotated overlay left';
                                    });
                                  },
                                ),
                                LabeledIconButton(
                                  icon: Icons.rotate_right,
                                  label: 'Rotate R',
                                  tooltip: 'Rotate overlay 90° right',
                                  onPressed: () {
                                    setState(() {
                                      selectedItem.rotation = _normalizeAngle(selectedItem.rotation + math.pi / 2);
                                      _activeControlMode = _ActiveControlMode.none;
                                      _statusMessage = 'Rotated overlay right';
                                    });
                                  },
                                ),
                              ] else ...[
                                if (_canvasColor == null) ...[
                                  LabeledIconButton(
                                    icon: Icons.brightness_6,
                                    label: 'Brightness',
                                    isSelected: _activeControlMode == _ActiveControlMode.brightness,
                                    onPressed: () {
                                      setState(() {
                                        _activeControlMode = _activeControlMode == _ActiveControlMode.brightness
                                            ? _ActiveControlMode.none
                                            : _ActiveControlMode.brightness;
                                      });
                                    },
                                  ),
                                  if (isPhotoTarget) ...[
                                    LabeledIconButton(
                                      icon: Icons.rotate_left,
                                      label: 'Rotate L',
                                      tooltip: 'Rotate 90° left',
                                      onPressed: () {
                                        _rotatePhotoBy(-math.pi / 2);
                                        setState(() {
                                          _activeControlMode = _ActiveControlMode.none;
                                          _statusMessage = 'Rotated to the left';
                                        });
                                      },
                                    ),
                                    LabeledIconButton(
                                      icon: Icons.rotate_right,
                                      label: 'Rotate R',
                                      tooltip: 'Rotate 90° right',
                                      onPressed: () {
                                        _rotatePhotoBy(math.pi / 2);
                                        setState(() {
                                          _activeControlMode = _ActiveControlMode.none;
                                          _statusMessage = 'Rotated to the right';
                                        });
                                      },
                                    ),
                                    LabeledIconButton(
                                      icon: _fitMode == _PhotoFitMode.fill ? Icons.fit_screen : Icons.crop_free,
                                      label: _fitMode == _PhotoFitMode.fill ? 'Fit' : 'Fill',
                                      tooltip: _fitMode == _PhotoFitMode.fill ? 'Fit whole photo in frame' : 'Fill the frame',
                                      onPressed: () {
                                        _applyPhotoFit(
                                          _fitMode == _PhotoFitMode.fill ? _PhotoFitMode.fit : _PhotoFitMode.fill,
                                        );
                                        setState(() {
                                          _activeControlMode = _ActiveControlMode.none;
                                          _statusMessage = _fitMode == _PhotoFitMode.fill
                                              ? 'Fitted photo in frame'
                                              : 'Filled frame with photo';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                                if (_selectedOverlayId == null) ...[
                                  LabeledIconButton(
                                    icon: Icons.palette,
                                    label: 'Canvas',
                                    tooltip: 'Canvas Color',
                                    onPressed: () {
                                      setState(() {
                                        _activeControlMode = _ActiveControlMode.none;
                                      });
                                      _pickCanvasColorDialog();
                                    },
                                  ),
                                  LabeledIconButton(
                                    icon: Icons.add_photo_alternate,
                                    label: 'Add Image',
                                    tooltip: 'Add Image Overlay',
                                    onPressed: () {
                                      setState(() {
                                        _activeControlMode = _ActiveControlMode.none;
                                      });
                                      _addOverlayImage();
                                    },
                                  ),
                                  LabeledIconButton(
                                    icon: Icons.text_fields,
                                    label: 'Add Text',
                                    tooltip: 'Add Text Overlay',
                                    onPressed: () {
                                      setState(() {
                                        _activeControlMode = _ActiveControlMode.none;
                                      });
                                      _addOverlayText();
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_selectedOverlayId == null ||
                                isPhotoSelected) ...[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: OutlinedButton.icon(
                                    onPressed: _resetEditor,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reset'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: OutlinedButton.icon(
                                    onPressed: _confirmAndSavePicture,
                                    icon: Icon(Icons.check),
                                    label: const Text('Confirm'),
                                    style: theme.outlinedButtonTheme.style?.copyWith(
                                      backgroundColor: WidgetStatePropertyAll(Colors.green.shade700),
                                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
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
                                      side: WidgetStatePropertyAll(
                                        BorderSide(
                                          color: theme.colorScheme.error,
                                          width: 2.0,
                                        ),
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Confirm additions'),
                                    onPressed: () {
                                      setState(() {
                                        _selectedOverlayId = null;
                                      });
                                    },
                                  ),
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
      ),
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
