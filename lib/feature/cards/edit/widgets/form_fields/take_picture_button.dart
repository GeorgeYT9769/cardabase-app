import 'dart:io';

import 'package:cardabase/feature/cards/card_face_error_widget.dart';
import 'package:cardabase/util/camera_controller.dart';
import 'package:cardabase/util/dashed_rect.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class TakePictureButton extends StatefulWidget {
  const TakePictureButton({
    super.key,
    required this.picturePath,
    required this.label,
  });

  final ValueNotifier<String?> picturePath;
  final Widget label;

  @override
  State<TakePictureButton> createState() => _TakePictureButtonState();
}

class _TakePictureButtonState extends State<TakePictureButton> {
  void _resetPicture() {
    widget.picturePath.value = null;
  }

  Future<void> _takePicture() async {
    late final String? picturePath;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final result = await FilePicker.pickFiles();
      picturePath = result?.files.map((file) => file.path).firstOrNull;
    } else {
      picturePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CameraControllerScreen()),
      );
    }

    if (!mounted || picturePath == null) {
      return;
    }
    widget.picturePath.value = picturePath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounceable(
      onTap: () {},
      child: Container(
        alignment: Alignment.center,
        child: SizedBox(
          // TODO(wim): migrate this to LayoutBuilder
          height: (MediaQuery.of(context).size.width - 40) / 1.586,
          width: double.infinity,
          child: CustomPaint(
            painter: DashedRect(
              color: theme.colorScheme.primary,
            ),
            child: GestureDetector(
              onLongPress: _resetPicture,
              child: OutlinedButton(
                onPressed: _takePicture,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                    style: BorderStyle.none,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minimumSize: const Size.fromHeight(100),
                  padding: EdgeInsets.zero, // Remove internal padding
                ),
                child: ValueListenableBuilder(
                  valueListenable: widget.picturePath,
                  builder: (context, path, _) => path != null
                      ? _imagePreview(context, path)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: theme.colorScheme.secondary,
                            ),
                            widget.label,
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePreview(BuildContext context, String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => CardFaceErrorWidget(
          error: error,
          stackTrace: stackTrace,
        ),
      ),
    );
  }
}
