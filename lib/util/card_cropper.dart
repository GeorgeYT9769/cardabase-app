import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/widgets/blur_app_bar_background.dart';
import 'package:cardabase/util/widgets/labeled_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import 'expressive_loading_indicator.dart';

/// Aspect ratio of the output picture (ID-1 card: 85.60 mm x 53.98 mm).
const double _cardAspectRatio = 1.586;

/// Result of [CardCropScreen].
class CardCropResult {
  const CardCropResult(this.path, {this.edit = false});

  /// Path of the image to use.
  final String path;

  /// `true` if the user wants to continue in the full editor (brightness,
  /// text, stickers, manual positioning). `false` means the picture is final.
  final bool edit;
}

/// Screen that lets the user mark the four corners of a card on a photo
/// (taken with the camera or picked from the gallery). The corners are
/// pre-filled by a simple automatic card detection. On "Done" the card is
/// cut out and its perspective is corrected, so the result is a flat,
/// card-shaped picture.
///
/// Pops with:
/// - a [CardCropResult] with `edit: false` after "Done" (final picture),
/// - a [CardCropResult] with `edit: true` after "Edit more" (cropped picture),
/// - `null` if the user went back without choosing anything.
class CardCropScreen extends StatefulWidget {
  const CardCropScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<CardCropScreen> createState() => _CardCropScreenState();
}

class _CardCropScreenState extends State<CardCropScreen> {
  String? _preparedPath;
  int _imgW = 0;
  int _imgH = 0;

  /// Normalized (0..1) corners: top-left, top-right, bottom-right, bottom-left.
  List<Offset> _corners = const [];
  List<Offset> _detected = const [];

  int _turns = 0;
  int? _dragIndex;
  bool _isDraggingWholeQuad = false;
  bool _busy = false;

  /// When true, dragging a corner also moves the two neighbouring corners so
  /// the whole side follows (rectangle-style resize). When false every corner
  /// moves on its own (free perspective).
  bool _linkSides = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tmp = (await getTemporaryDirectory()).path;
      final outPath = join(tmp, 'crop_src_${DateTime.now().microsecondsSinceEpoch}.jpg');
      final inPath = widget.imagePath;

      List<Object>? result;
      try {
        result = await Isolate.run(
          () => _prepareImage(<String>[inPath, outPath]),
        );
      } catch (e) {
        debugPrint('Isolate _prepareImage failed: $e. Attempting native decoder fallback.');
        result = await _prepareImageNativeFallback(inPath, outPath);
      }

      if (!mounted || result == null) return;
      final c = (result[2] as List).cast<double>();
      final corners = List<Offset>.generate(
        4,
        (i) => Offset(c[i * 2], c[i * 2 + 1]),
      );
      setState(() {
        _preparedPath = outPath;
        _imgW = result![0] as int;
        _imgH = result[1] as int;
        _corners = corners;
        _detected = List<Offset>.of(corners);
      });
    } catch (e, stack) {
      debugPrint('CardCropScreen _load failed completely: $e\n$stack');
      // Could not process the image: fall back to the original photo.
      if (mounted) Navigator.of(context).pop(CardCropResult(widget.imagePath, edit: true));
    }
  }

  Future<List<Object>> _prepareImageNativeFallback(String inPath, String outPath) async {
    final bytes = await File(inPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 2000,
    );
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;
    final w = image.width;
    final h = image.height;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert native image to PNG byte data');
    }

    await File(outPath).writeAsBytes(byteData.buffer.asUint8List());
    final corners = _fallbackCorners(w, h);
    return <Object>[w, h, corners];
  }

  Future<void> _done({bool edit = false}) async {
    if (_busy || _preparedPath == null) return;
    setState(() => _busy = true);
    try {
      final displayW = _turns.isOdd ? _imgH : _imgW;
      final displayH = _turns.isOdd ? _imgW : _imgH;
      final pts = _corners
          .map((o) => Offset(o.dx * displayW, o.dy * displayH))
          .toList();

      double dist(Offset a, Offset b) => (a - b).distance;
      final w = (dist(pts[0], pts[1]) + dist(pts[3], pts[2])) / 2;

      final hh = (dist(pts[0], pts[3]) + dist(pts[1], pts[2])) / 2;
      final shift = hh > w ? 1 : 0; // portrait card -> make the result landscape
      final ordered = List<Offset>.generate(4, (i) => pts[(i + shift) % 4]);
      final outW = (shift == 1 ? hh : w).round().clamp(800, 1400);
      final outH = (outW / _cardAspectRatio).round();

      final flat = <double>[
        for (final p in ordered) ...[p.dx, p.dy],
      ];
      final srcPath = _preparedPath!;
      final tmp = (await getTemporaryDirectory()).path;
      final outPath = join(tmp, 'crop_out_${DateTime.now().microsecondsSinceEpoch}.png');
      final String path = await Isolate.run(
        () => _warpAndSave(<Object>[srcPath, outPath, flat, outW, outH, _turns]),
      );
      if (mounted) Navigator.of(context).pop(CardCropResult(path, edit: edit));
    } catch (e, stack) {
      debugPrint('CardCropScreen _done error: $e\n$stack');
      try {
        final displayW = _turns.isOdd ? _imgH : _imgW;
        final displayH = _turns.isOdd ? _imgW : _imgH;
        final pts = _corners
            .map((o) => Offset(o.dx * displayW, o.dy * displayH))
            .toList();

        double dist(Offset a, Offset b) => (a - b).distance;
        final w = (dist(pts[0], pts[1]) + dist(pts[3], pts[2])) / 2;
        final hh = (dist(pts[0], pts[3]) + dist(pts[1], pts[2])) / 2;
      final shift = hh > w ? 1 : 0; // portrait card -> make the result landscape
      final ordered = List<Offset>.generate(4, (i) => pts[(i + shift) % 4]);
        final outW = (shift == 1 ? hh : w).round().clamp(800, 1400);
        final outH = (outW / _cardAspectRatio).round();

        final flat = <double>[
          for (final p in ordered) ...[p.dx, p.dy],
        ];
        final srcPath = _preparedPath!;
        final tmp = (await getTemporaryDirectory()).path;
        final outPath = join(tmp, 'crop_out_${DateTime.now().microsecondsSinceEpoch}.png');
        final String path = _warpAndSave(<Object>[srcPath, outPath, flat, outW, outH, _turns]);
        if (mounted) Navigator.of(context).pop(CardCropResult(path, edit: edit));
      } catch (e2, stack2) {
        debugPrint('CardCropScreen _done sync fallback error: $e2\n$stack2');
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not crop the image')),
          );
        }
      }
    }
  }

  /// Moves corner [i] to [target] (normalized) and makes the sides that touch
  /// it follow: the next corner moves only along the direction of the other
  /// side and vice versa. For a rectangle this is the usual crop-box resize
  /// (the opposite corner stays fixed); it also works for rotated frames.
  List<Offset> _moveCornerLinked(int i, Offset target, Size size) {
    Offset toPx(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    Offset toNorm(Offset p) => Offset(
          (p.dx / size.width).clamp(0.0, 1.0),
          (p.dy / size.height).clamp(0.0, 1.0),
        );
    Offset unit(Offset v) {
      final l = v.distance;
      return l < 1e-6 ? Offset.zero : v / l;
    }

    final pts = _corners.map(toPx).toList();
    final next = (i + 1) % 4;
    final prev = (i + 3) % 4;
    final p = pts[i];
    final d = toPx(target) - p;
    final u = unit(pts[next] - p); // direction of the side towards next
    final v = unit(pts[prev] - p); // direction of the side towards prev
    final moveNext = v * (d.dx * v.dx + d.dy * v.dy);
    final movePrev = u * (d.dx * u.dx + d.dy * u.dy);

    final result = List<Offset>.of(_corners);
    result[i] = toNorm(p + d);
    result[next] = toNorm(pts[next] + moveNext);
    result[prev] = toNorm(pts[prev] + movePrev);
    return result;
  }

  void _rotate90() {
    HapticFeedback.selectionClick();
    setState(() {
      _turns = (_turns + 1) % 4;
    });
  }

  void _rotateBack90() {
    HapticFeedback.selectionClick();
    setState(() {
      _turns = (_turns - 1) % 4;
    });
  }

  /// Moves the frame to the edges of the photo (for pictures that already
  /// show only the card).
  void _selectWholePhoto() {
    HapticFeedback.selectionClick();
    setState(() {
      _corners = <Offset>[
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];
    });
  }

  void _resetToDetected() {
    HapticFeedback.selectionClick();
    setState(() {
      _corners = List<Offset>.of(_detected);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corners reset to detected area'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _preparedPath != null;
    final settings = GetIt.I<SettingsBox>().value;
    final advancedTextures = settings.theme.advancedTextures;
    final rightBackButton = settings.theme.rightBackButton;
    final backButton = IconButton(
      icon: const Icon(Icons.arrow_back_ios_new),
      color: theme.colorScheme.tertiary,
      onPressed: _busy ? null : () => Navigator.of(context).pop(),
    );

    return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor:
                advancedTextures ? Colors.transparent : theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace:
                advancedTextures ? const BlurAppBarBackground(alpha: .8) : null,
            title: Text(
              'Crop card',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
            centerTitle: true,
            leading: rightBackButton ? null : backButton,
            actions: [if (rightBackButton) backButton],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: !ready
                        ? Center(
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
                        )
                        : LayoutBuilder(builder: (context, constraints) {
                            final size = constraints.biggest;
                            final displayW = _turns.isOdd ? _imgH : _imgW;
                            final displayH = _turns.isOdd ? _imgW : _imgH;
                            final scale = math.min(size.width / displayW, size.height / displayH);
                            final dw = displayW * scale;
                            final dh = displayH * scale;
                            final rect = Rect.fromLTWH(
                              (size.width - dw) / 2,
                              (size.height - dh) / 2,
                              dw,
                              dh,
                            );
                            Offset toScreen(Offset n) => Offset(
                                  rect.left + n.dx * rect.width,
                                  rect.top + n.dy * rect.height,
                                );
                            final screenPoints = _corners.map(toScreen).toList();

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (d) {
                                int? nearest;
                                double best = 64; // touch radius
                                for (var i = 0; i < 4; i++) {
                                  final dd = (screenPoints[i] - d.localPosition).distance;
                                  if (dd < best) {
                                    best = dd;
                                    nearest = i;
                                  }
                                }
                                _dragIndex = nearest;
                                _isDraggingWholeQuad = (nearest == null);
                              },
                              onPanUpdate: (d) {
                                if (_dragIndex != null) {
                                  final i = _dragIndex!;
                                  final s = screenPoints[i] + d.delta;
                                  final nx = ((s.dx - rect.left) / rect.width).clamp(0.0, 1.0);
                                  final ny = ((s.dy - rect.top) / rect.height).clamp(0.0, 1.0);
                                  setState(() {
                                    _corners = _linkSides
                                        ? _moveCornerLinked(i, Offset(nx, ny), rect.size)
                                        : (List<Offset>.of(_corners)..[i] = Offset(nx, ny));
                                  });
                                } else if (_isDraggingWholeQuad) {
                                  final dxNorm = d.delta.dx / rect.width;
                                  final dyNorm = d.delta.dy / rect.height;

                                  double clampedDx = dxNorm;
                                  double clampedDy = dyNorm;

                                  for (final c in _corners) {
                                    if (c.dx + clampedDx < 0.0) clampedDx = -c.dx;
                                    if (c.dx + clampedDx > 1.0) clampedDx = 1.0 - c.dx;
                                    if (c.dy + clampedDy < 0.0) clampedDy = -c.dy;
                                    if (c.dy + clampedDy > 1.0) clampedDy = 1.0 - c.dy;
                                  }

                                  if (clampedDx != 0.0 || clampedDy != 0.0) {
                                    setState(() {
                                      _corners = _corners
                                          .map((c) => Offset(c.dx + clampedDx, c.dy + clampedDy))
                                          .toList();
                                    });
                                  }
                                }
                              },
                              onPanEnd: (_) {
                                setState(() {
                                  _dragIndex = null;
                                  _isDraggingWholeQuad = false;
                                });
                              },
                              onPanCancel: () {
                                setState(() {
                                  _dragIndex = null;
                                  _isDraggingWholeQuad = false;
                                });
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fromRect(
                                    rect: rect,
                                    child: RotatedBox(
                                      quarterTurns: _turns,
                                      child: Image.file(
                                        File(_preparedPath!),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _QuadPainter(
                                          points: screenPoints,
                                          imageRect: rect,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_dragIndex != null) ...[
                                    (() {
                                      const double magSize = 96.0;
                                      const double zoom = 2.2;
                                      final activeCorner = _corners[_dragIndex!];
                                      final activeScreenPoint = screenPoints[_dragIndex!];

                                      double bubbleCenterX = activeScreenPoint.dx;
                                      double bubbleCenterY = activeScreenPoint.dy - 85;

                                      if (bubbleCenterY - magSize / 2 < 10) {
                                        bubbleCenterY = activeScreenPoint.dy + 85;
                                      }

                                      bubbleCenterX = bubbleCenterX.clamp(
                                        magSize / 2 + 10,
                                        size.width - magSize / 2 - 10,
                                      );

                                      final imageLeft = magSize / 2 - activeCorner.dx * dw * zoom;
                                      final imageTop = magSize / 2 - activeCorner.dy * dh * zoom;

                                      return Positioned(
                                        left: bubbleCenterX - magSize / 2,
                                        top: bubbleCenterY - magSize / 2,
                                        width: magSize,
                                        height: magSize,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black54,
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    left: imageLeft,
                                                    top: imageTop,
                                                    width: dw * zoom,
                                                    height: dh * zoom,
                                                    child: RotatedBox(
                                                      quarterTurns: _turns,
                                                      child: Image.file(
                                                        File(_preparedPath!),
                                                        fit: BoxFit.fill,
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: theme.colorScheme.primary,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    })(),
                                  ],
                                ],
                              ),
                            );
                          }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    _linkSides
                        ? 'Drag a corner to resize the frame (its sides follow), '
                            'or drag inside to move it.'
                        : 'Drag each corner separately, '
                            'or drag inside to move the frame.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.inverseSurface.withValues(alpha: .75),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                              Expanded(
                                child: LabeledIconButton(
                                  icon: Icons.auto_fix_high,
                                  label: 'Auto-detect',
                                  tooltip: 'Place the frame on the card again',
                                  onPressed: ready && !_busy ? _resetToDetected : null,
                                ),
                              ),
                              Expanded(
                                child: LabeledIconButton(
                                  icon: Icons.rotate_left,
                                  label: 'Rotate L',
                                  tooltip: 'Rotate the photo -90°',
                                  onPressed: ready && !_busy ? _rotateBack90 : null,
                                ),
                              ),
                              Expanded(
                                child: LabeledIconButton(
                                  icon: Icons.rotate_right,
                                  label: 'Rotate R',
                                  tooltip: 'Rotate the photo 90°',
                                  onPressed: ready && !_busy ? _rotate90 : null,
                                ),
                              ),
                              Expanded(
                                child: LabeledIconButton(
                                  icon: _linkSides ? Icons.link : Icons.link_off,
                                  label: _linkSides ? 'Linked sides' : 'Free corners',
                                  tooltip: _linkSides
                                      ? 'Sides follow the corner (tap to move corners freely)'
                                      : 'Corners move freely (tap to link the sides)',
                                  onPressed: ready && !_busy
                                      ? () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _linkSides = !_linkSides);
                                        }
                                      : null,
                                ),
                              ),
                              Expanded(
                                child: LabeledIconButton(
                                  icon: Icons.skip_next,
                                  label: 'Skip & Edit',
                                  tooltip: 'Skip cropping and edit the image',
                                  onPressed: ready && !_busy
                                      ? () => Navigator.of(context).pop(CardCropResult(widget.imagePath, edit: true))
                                      : null,
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: ready && !_busy
                                  ? () => _done(edit: true)
                                  : null,
                              icon: const Icon(Icons.tune),
                              label: const Text('Edit cutout'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: ready && !_busy ? _done : null,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Done'),
                              style: theme.outlinedButtonTheme.style?.copyWith(
                                backgroundColor: WidgetStatePropertyAll(Colors.green.shade700),
                                foregroundColor: const WidgetStatePropertyAll(Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter({
    required this.points,
    required this.imageRect,
    required this.color,
  });

  final List<Offset> points;
  final Rect imageRect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final quad = Path()..addPolygon(points, true);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(imageRect),
      quad,
    );
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: .55),
    );
    canvas.drawPath(
      quad,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (final p in points) {
      canvas.drawCircle(p, 18, Paint()..color = color.withValues(alpha: .25));
      canvas.drawCircle(p, 8, Paint()..color = color);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Image processing. Everything below runs in a background isolate.
// ---------------------------------------------------------------------------

/// Decodes the photo, applies its EXIF orientation, limits its size, saves
/// the normalized JPEG to `args[1]` and detects the card corners.
/// Returns `[width, height, List<double> corners(8 normalized values)]`.
List<Object> _prepareImage(List<String> args) {
  final bytes = File(args[0]).readAsBytesSync();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('Unsupported image');
  }
  image = img.bakeOrientation(image);
  const maxSide = 2400;
  if (image.width > maxSide || image.height > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  File(args[1]).writeAsBytesSync(img.encodeJpg(image, quality: 92));
  final corners = _detectCorners(image);
  return <Object>[image.width, image.height, corners];
}

List<double> _fallbackCorners(int w, int h) {
  double rw = 0.8;
  double rh = rw * w / _cardAspectRatio / h;
  if (rh > 0.8) {
    rh = 0.8;
    rw = rh * h * _cardAspectRatio / w;
  }
  final l = (1 - rw) / 2;
  final t = (1 - rh) / 2;
  return <double>[l, t, l + rw, t, l + rw, t + rh, l, t + rh];
}

int _otsu(Uint8List data) {
  final hist = List<int>.filled(256, 0);
  for (final v in data) {
    hist[v]++;
  }
  final total = data.length;
  double sum = 0;
  for (var i = 0; i < 256; i++) {
    sum += i * hist[i];
  }
  double sumB = 0;
  int wB = 0;
  double maxVar = -1;
  int threshold = 0;
  for (var t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB.toDouble() * wF * (mB - mF) * (mB - mF);
    if (between > maxVar) {
      maxVar = between;
      threshold = t;
    }
  }
  return threshold;
}

Uint8List _morph(Uint8List src, int w, int h, {required bool dilate}) {
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      bool result = !dilate;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          final ny = y + dy;
          final v = (nx >= 0 && nx < w && ny >= 0 && ny < h)
              ? src[ny * w + nx]
              : 0;
          if (dilate) {
            if (v == 1) result = true;
          } else {
            if (v == 0) result = false;
          }
        }
      }
      out[y * w + x] = result ? 1 : 0;
    }
  }
  return out;
}

int _median(List<int> values) {
  values.sort();
  return values[values.length ~/ 2];
}

/// Card detection (heuristic).
///
/// The photo is split into "card" and "background" in several different ways
/// (colour model of the photo centre vs. border, distance from the border
/// colour, dark and light areas). Every candidate blob is judged by how well
/// its convex hull fills its minimum-area rotated rectangle (a card is a
/// rectangle), whether the aspect ratio is card-like and whether it is
/// roughly centred; the best candidate wins. Using the convex hull means
/// glare or bright printed areas on the card do not break the detection.
///
/// If nothing plausible is found and the photo itself already has the shape
/// of a card (the user cropped it before), the whole photo is used; otherwise
/// a centered card-shaped frame is returned. The user can always correct the
/// corners by hand.
List<double> _detectCorners(img.Image full) {
  try {
    final scale = 320 / math.max(full.width, full.height);
    final w = math.max(8, (full.width * scale).round());
    final h = math.max(8, (full.height * scale).round());
    final small = img.copyResize(
      full,
      width: w,
      height: h,
      interpolation: img.Interpolation.average,
    );

    final rCh = Uint8List(w * h);
    final gCh = Uint8List(w * h);
    final bCh = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = small.getPixel(x, y);
        final i = y * w + x;
        rCh[i] = p.r.toInt();
        gCh[i] = p.g.toInt();
        bCh[i] = p.b.toInt();
      }
    }

    final masks = <Uint8List>[
      _colourModelMask(rCh, gCh, bCh, w, h, 0.2),
      _colourModelMask(rCh, gCh, bCh, w, h, 0.4),
      _borderDistanceMask(rCh, gCh, bCh, w, h, 1.0),
      _borderDistanceMask(rCh, gCh, bCh, w, h, 0.7),
      _greyMask(rCh, gCh, bCh, w, h, dark: true),
      _greyMask(rCh, gCh, bCh, w, h, dark: false),
    ];

    _CardCandidate? best;
    for (final mask in masks) {
      final c = _cornersFromMask(mask, w, h);
      if (c != null && (best == null || c.score > best.score)) {
        best = c;
      }
    }
    if (best != null) return best.corners;

    // Nothing found. A photo that is already card-shaped is most likely a
    // picture of the card only: use all of it.
    final aspect = full.width / full.height;
    final bool cardShaped = (aspect >= 1.35 && aspect <= 1.85) ||
        (aspect >= 0.54 && aspect <= 0.74);
    if (cardShaped) {
      return <double>[0, 0, 1, 0, 1, 1, 0, 1];
    }
    return _fallbackCorners(full.width, full.height);
  } catch (_) {
    return _fallbackCorners(full.width, full.height);
  }
}

/// A card-like blob: [corners] are 8 normalized values (top-left, top-right,
/// bottom-right, bottom-left), [score] is higher for better candidates.
class _CardCandidate {
  _CardCandidate(this.corners, this.score);

  final List<double> corners;
  final double score;
}

/// "Card" = colours that are more typical for the centre of the photo (a
/// square of [centreFraction] of its size) than for its border (8 levels per
/// channel, smoothed histograms).
Uint8List _colourModelMask(
  Uint8List rCh,
  Uint8List gCh,
  Uint8List bCh,
  int w,
  int h,
  double centreFraction,
) {
  const bins = 512;
  final fg = List<double>.filled(bins, 0);
  final bg = List<double>.filled(bins, 0);
  var nf = 0;
  var nb = 0;
  final margin = math.max(2, (0.05 * math.min(w, h)).round());
  final lo = 0.5 - centreFraction / 2;
  final hi = 0.5 + centreFraction / 2;
  final x0 = (w * lo).round(), x1 = (w * hi).round();
  final y0 = (h * lo).round(), y1 = (h * hi).round();
  int binOf(int i) =>
      ((rCh[i] >> 5) << 6) | ((gCh[i] >> 5) << 3) | (bCh[i] >> 5);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (x < margin || y < margin || x >= w - margin || y >= h - margin) {
        bg[binOf(i)]++;
        nb++;
      } else if (x >= x0 && x < x1 && y >= y0 && y < y1) {
        fg[binOf(i)]++;
        nf++;
      }
    }
  }

  final mask = Uint8List(w * h);
  if (nf == 0 || nb == 0) return mask;
  for (var i = 0; i < w * h; i++) {
    final k = binOf(i);
    final pf = (fg[k] + 0.5) / (nf + bins * 0.5);
    final pb = (bg[k] + 0.5) / (nb + bins * 0.5);
    mask[i] = pf > 1.5 * pb ? 1 : 0;
  }
  return mask;
}

/// "Card" = pixels far from the median colour of the photo border.
/// [thresholdFactor] scales the automatically found (Otsu) threshold.
Uint8List _borderDistanceMask(
  Uint8List rCh,
  Uint8List gCh,
  Uint8List bCh,
  int w,
  int h,
  double thresholdFactor,
) {
  final margin = math.max(2, (0.05 * math.min(w, h)).round());
  final rs = <int>[], gs = <int>[], bs = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (x < margin || y < margin || x >= w - margin || y >= h - margin) {
        final i = y * w + x;
        rs.add(rCh[i]);
        gs.add(gCh[i]);
        bs.add(bCh[i]);
      }
    }
  }
  final mr = _median(rs), mg = _median(gs), mb = _median(bs);

  final dist = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    final dr = rCh[i] - mr;
    final dg = gCh[i] - mg;
    final db = bCh[i] - mb;
    dist[i] = math
        .sqrt((dr * dr + dg * dg + db * db).toDouble())
        .clamp(0, 255)
        .round();
  }
  final threshold = math.max(_otsu(dist) * thresholdFactor, 20.0);
  final mask = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    mask[i] = dist[i] > threshold ? 1 : 0;
  }
  return mask;
}

/// "Card" = the dark (or light) part of a lightly blurred grey version of the
/// photo, split at the Otsu threshold.
Uint8List _greyMask(
  Uint8List rCh,
  Uint8List gCh,
  Uint8List bCh,
  int w,
  int h, {
  required bool dark,
}) {
  var grey = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    grey[i] = ((299 * rCh[i] + 587 * gCh[i] + 114 * bCh[i]) ~/ 1000);
  }
  // Two passes of a 3x3 box blur.
  for (var pass = 0; pass < 2; pass++) {
    final blurred = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0;
        var n = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            sum += grey[ny * w + nx];
            n++;
          }
        }
        blurred[y * w + x] = sum ~/ n;
      }
    }
    grey = blurred;
  }
  final t = _otsu(grey);
  final mask = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    final isDark = grey[i] <= t;
    mask[i] = (dark ? isDark : !isDark) ? 1 : 0;
  }
  return mask;
}

/// Convex hull (monotone chain), counter-clockwise in a y-up system.
List<Offset> _convexHull(List<Offset> points) {
  final p = List<Offset>.of(points);
  p.sort((a, b) {
    final c = a.dx.compareTo(b.dx);
    return c != 0 ? c : a.dy.compareTo(b.dy);
  });
  if (p.length < 3) return p;
  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lower = <Offset>[];
  for (final q in p) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower[lower.length - 1], q) <= 0) {
      lower.removeLast();
    }
    lower.add(q);
  }
  final upper = <Offset>[];
  for (final q in p.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper[upper.length - 1], q) <= 0) {
      upper.removeLast();
    }
    upper.add(q);
  }
  lower.removeLast();
  upper.removeLast();
  return <Offset>[...lower, ...upper];
}

double _polygonArea(List<Offset> poly) {
  double s = 0;
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i];
    final b = poly[(i + 1) % poly.length];
    s += a.dx * b.dy - b.dx * a.dy;
  }
  return s.abs() / 2;
}

/// Finds the best card-like blob in [raw] and returns its minimum-area
/// rotated rectangle, or `null` if there is no plausible one.
_CardCandidate? _cornersFromMask(Uint8List raw, int w, int h) {
  var mask = raw;
  // Open (remove noise), then close (fill small holes).
  for (var k = 0; k < 2; k++) {
    mask = _morph(mask, w, h, dilate: false);
  }
  for (var k = 0; k < 4; k++) {
    mask = _morph(mask, w, h, dilate: true);
  }
  for (var k = 0; k < 2; k++) {
    mask = _morph(mask, w, h, dilate: false);
  }

  // Connected components (4-neighbourhood).
  final labels = Int32List(w * h);
  final areas = <int>[0];
  var next = 0;
  final stack = <int>[];
  for (var i = 0; i < w * h; i++) {
    if (mask[i] == 1 && labels[i] == 0) {
      next++;
      labels[i] = next;
      stack.add(i);
      var area = 0;
      while (stack.isNotEmpty) {
        final c = stack.removeLast();
        area++;
        final cx = c % w;
        final cy = c ~/ w;
        void visit(int nx, int ny) {
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) return;
          final n = ny * w + nx;
          if (mask[n] == 1 && labels[n] == 0) {
            labels[n] = next;
            stack.add(n);
          }
        }

        visit(cx - 1, cy);
        visit(cx + 1, cy);
        visit(cx, cy - 1);
        visit(cx, cy + 1);
      }
      areas.add(area);
    }
  }
  if (next == 0) return null;

  // Only the largest few blobs are worth a closer look.
  final order = List<int>.generate(next, (i) => i + 1)
    ..sort((a, b) => areas[b].compareTo(areas[a]));
  final labelsToCheck = order.take(5).where((l) => areas[l] >= 0.04 * w * h);

  _CardCandidate? best;
  for (final label in labelsToCheck) {
    // Boundary pixels of the blob.
    final pts = <Offset>[];
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (labels[y * w + x] != label) continue;
        bool boundary = false;
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
          boundary = true;
        } else if (labels[y * w + x - 1] != label ||
            labels[y * w + x + 1] != label ||
            labels[(y - 1) * w + x] != label ||
            labels[(y + 1) * w + x] != label) {
          boundary = true;
        }
        if (boundary) {
          final px = x + 0.5, py = y + 0.5;
          pts.add(Offset(px, py));
          if (px < minX) minX = px;
          if (px > maxX) maxX = px;
          if (py < minY) minY = py;
          if (py > maxY) maxY = py;
        }
      }
    }
    if (pts.length < 8) continue;

    final hull = _convexHull(pts);
    if (hull.length < 3) continue;
    final hullArea = _polygonArea(hull);
    final fraction = hullArea / (w * h);
    if (fraction < 0.08 || fraction > 0.85) continue;
    // Strongly concave blobs (not a card).
    if (hullArea / areas[label] > 1.6) continue;

    // Minimum-area rotated rectangle around the hull.
    double bestArea = double.infinity;
    double bestC = 1, bestS = 0;
    double bMinU = 0, bMaxU = 0, bMinV = 0, bMaxV = 0;
    for (var deg = 0; deg < 90; deg++) {
      final t = deg * math.pi / 180;
      final c = math.cos(t);
      final s = math.sin(t);
      double minU = double.infinity, maxU = -double.infinity;
      double minV = double.infinity, maxV = -double.infinity;
      for (final p in hull) {
        final u = p.dx * c + p.dy * s;
        final v = -p.dx * s + p.dy * c;
        if (u < minU) minU = u;
        if (u > maxU) maxU = u;
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
      final area = (maxU - minU) * (maxV - minV);
      if (area < bestArea) {
        bestArea = area;
        bestC = c;
        bestS = s;
        bMinU = minU;
        bMaxU = maxU;
        bMinV = minV;
        bMaxV = maxV;
      }
    }

    final rw = bMaxU - bMinU;
    final rh = bMaxV - bMinV;
    if (math.min(rw, rh) < 1) continue;
    final ratio = math.max(rw, rh) / math.min(rw, rh);
    final rectangularity = hullArea / (rw * rh);
    if (ratio < 1.2 || ratio > 2.2 || rectangularity < 0.85) continue;

    Offset back(double u, double v) =>
        Offset(u * bestC - v * bestS, u * bestS + v * bestC);
    final centre = back((bMinU + bMaxU) / 2, (bMinV + bMaxV) / 2);
    final centreScore = 1 -
        math.min(
          1.0,
          math.sqrt(math.pow(centre.dx / w - 0.5, 2) +
                  math.pow(centre.dy / h - 0.5, 2)) *
              2,
        );
    var touches = 0;
    // Morphology pulls blobs a couple of pixels away from the photo edge.
    const edgeTolerance = 4;
    if (minX <= edgeTolerance) touches++;
    if (maxX >= w - edgeTolerance) touches++;
    if (minY <= edgeTolerance) touches++;
    if (maxY >= h - edgeTolerance) touches++;
    // A real card photographed on a surface does not run into the photo
    // edges; a blob that touches two or more edges is a part of the picture
    // (for instance the white upper half of a card-only photo).
    if (touches >= 2) continue;
    final score = rectangularity -
        0.35 * (math.log(ratio / _cardAspectRatio)).abs() +
        0.1 * centreScore -
        0.15 * touches;

    if (best != null && score <= best.score) continue;

    final quad = <Offset>[
      back(bMinU, bMinV),
      back(bMaxU, bMinV),
      back(bMaxU, bMaxV),
      back(bMinU, bMaxV),
    ];
    quad.sort((a, b) => a.dy.compareTo(b.dy));
    final top = quad.sublist(0, 2)..sort((a, b) => a.dx.compareTo(b.dx));
    final bottom = quad.sublist(2, 4)..sort((a, b) => a.dx.compareTo(b.dx));
    final ordered = <Offset>[top[0], top[1], bottom[1], bottom[0]];
    best = _CardCandidate(<double>[
      for (final p in ordered) ...[
        (p.dx / w).clamp(0.0, 1.0),
        (p.dy / h).clamp(0.0, 1.0),
      ],
    ], score);
  }
  return best;
}

/// Perspective-corrects the quadrilateral given by `args[2]` (8 pixel
/// coordinates: top-left, top-right, bottom-right, bottom-left) of the image
/// at `args[0]` into an `args[3]` x `args[4]` picture saved to `args[1]`.
String _warpAndSave(List<Object> args) {
  var src = img.decodeImage(File(args[0] as String).readAsBytesSync());
  if (src == null) {
    throw const FormatException('Unsupported image');
  }

  final turns = args.length > 5 ? args[5] as int : 0;
  if (turns == 1) {
    src = img.copyRotate(src, angle: 90);
  } else if (turns == 2) {
    src = img.copyRotate(src, angle: 180);
  } else if (turns == 3) {
    src = img.copyRotate(src, angle: 270);
  }

  final c = (args[2] as List).cast<double>();
  final outW = args[3] as int;
  final outH = args[4] as int;

  final x0 = c[0], y0 = c[1];
  final x1 = c[2], y1 = c[3];
  final x2 = c[4], y2 = c[5];
  final x3 = c[6], y3 = c[7];

  // Unit square -> quadrilateral projective mapping (Heckbert).
  final dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
  final dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
  double a, b, cc, d, e, f, g, h;
  if (dx3.abs() < 1e-9 && dy3.abs() < 1e-9) {
    a = x1 - x0;
    b = x2 - x1;
    cc = x0;
    d = y1 - y0;
    e = y2 - y1;
    f = y0;
    g = 0;
    h = 0;
    // For a parallelogram, (u, v) -> x0 + u*(x1-x0) + v*(x3-x0).
    b = x3 - x0;
    e = y3 - y0;
  } else {
    final den = dx1 * dy2 - dx2 * dy1;
    g = (dx3 * dy2 - dx2 * dy3) / den;
    h = (dx1 * dy3 - dx3 * dy1) / den;
    a = x1 - x0 + g * x1;
    b = x3 - x0 + h * x3;
    cc = x0;
    d = y1 - y0 + g * y1;
    e = y3 - y0 + h * y3;
    f = y0;
  }

  final out = img.Image(width: outW, height: outH);
  final maxX = src.width - 1;
  final maxY = src.height - 1;

  for (var y = 0; y < outH; y++) {
    final v = (y + 0.5) / outH;
    for (var x = 0; x < outW; x++) {
      final u = (x + 0.5) / outW;
      final den = g * u + h * v + 1;
      final sx = ((a * u + b * v + cc) / den - 0.5).clamp(0.0, maxX.toDouble());
      final sy = ((d * u + e * v + f) / den - 0.5).clamp(0.0, maxY.toDouble());
      final ix = sx.floor();
      final iy = sy.floor();
      final fx = sx - ix;
      final fy = sy - iy;
      final jx = math.min(ix + 1, maxX);
      final jy = math.min(iy + 1, maxY);

      final p00 = src.getPixel(ix, iy);
      final r00 = p00.r.toDouble(), g00 = p00.g.toDouble(), b00 = p00.b.toDouble();
      final p10 = src.getPixel(jx, iy);
      final r10 = p10.r.toDouble(), g10 = p10.g.toDouble(), b10 = p10.b.toDouble();
      final p01 = src.getPixel(ix, jy);
      final r01 = p01.r.toDouble(), g01 = p01.g.toDouble(), b01 = p01.b.toDouble();
      final p11 = src.getPixel(jx, jy);
      final r11 = p11.r.toDouble(), g11 = p11.g.toDouble(), b11 = p11.b.toDouble();

      double mix(double v00, double v10, double v01, double v11) {
        final top = v00 + (v10 - v00) * fx;
        final bottom = v01 + (v11 - v01) * fx;
        return top + (bottom - top) * fy;
      }

      out.setPixelRgb(
        x,
        y,
        mix(r00, r10, r01, r11).round(),
        mix(g00, g10, g01, g11).round(),
        mix(b00, b10, b01, b11).round(),
      );
    }
  }

  File(args[1] as String).writeAsBytesSync(img.encodePng(out));
  return args[1] as String;
}
