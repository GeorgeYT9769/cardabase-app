import 'dart:io';

import 'package:cardabase/feature/cards/card_face_error_widget.dart';
import 'package:cardabase/feature/cards/widgets/full_screen_card_face_page.dart';
import 'package:cardabase/util/camera_controller.dart';
import 'package:cardabase/util/dashed_rect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:image_picker/image_picker.dart';

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

  /// Asks where the picture should come from, so the camera is only started
  /// when the user actually wants to use it.
  Future<void> _choosePictureSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) {
      return;
    }

    XFile? pickedImage;
    if (source == ImageSource.gallery) {
      pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || pickedImage == null) {
        return;
      }
    }

    final String? picturePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraControllerScreen(initialImage: pickedImage),
      ),
    );

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
          child: ValueListenableBuilder(
            valueListenable: widget.picturePath,
            builder: (context, path, _) => Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DashedRect(
                      color: theme.colorScheme.primary,
                    ),
                    child: GestureDetector(
                      onLongPress: _resetPicture,
                      child: OutlinedButton(
                        onPressed: _choosePictureSource,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                            style: BorderStyle.none,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: const Size.fromHeight(100),
                          padding: EdgeInsets.zero, // Remove internal padding
                        ),
                        child: path != null
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
                if (path != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenCardFacePage.image(
                              image: FileImage(File(path)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
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
