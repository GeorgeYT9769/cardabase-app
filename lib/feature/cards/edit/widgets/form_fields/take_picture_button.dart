import 'dart:io';

import 'package:cardabase/feature/cards/card_face_error_widget.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/cards/widgets/full_screen_card_face_page.dart';
import 'package:cardabase/util/widgets/blur_app_bar_background.dart';
import 'package:cardabase/util/camera_controller.dart';
import 'package:cardabase/util/card_cropper.dart';
import 'package:cardabase/util/dashed_rect.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';


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
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _PictureSourceBottomSheet(
        onTakePhoto: () => Navigator.pop(sheetContext, ImageSource.camera),
        onChooseFromGallery: () =>
            Navigator.pop(sheetContext, ImageSource.gallery),
      ),
    );
    if (!mounted || source == null) {
      return;
    }

    if (source == ImageSource.gallery) {
      final XFile? pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || pickedImage == null) {
        return;
      }
      await _cropAndUse(pickedImage);
      return;
    }

    final String? picturePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraControllerScreen(),
      ),
    );

    if (!mounted || picturePath == null) {
      return;
    }
    widget.picturePath.value = picturePath;
  }

  /// Gallery flow: the cropper is opened directly from the form (no camera
  /// screen in between). "Done" uses the cropped card as the final picture,
  /// "Edit more" continues in the editor.
  Future<void> _cropAndUse(XFile pickedImage) async {
    final CardCropResult? result = await Navigator.push<CardCropResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CardCropScreen(imagePath: pickedImage.path),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    if (!result.edit) {
      String path = result.path;
      try {
        final String target = join(
          (await getApplicationDocumentsDirectory()).path,
          '${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await File(result.path).copy(target);
        path = target;
      } catch (_) {
        // Fall back to the temporary file.
      }
      if (!mounted) {
        return;
      }
      widget.picturePath.value = path;
      return;
    }

    final String? editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CameraControllerScreen(initialImage: XFile(result.path)),
      ),
    );
    if (!mounted || editedPath == null) {
      return;
    }
    widget.picturePath.value = editedPath;
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

class _PictureSourceBottomSheet extends StatelessWidget {
  const _PictureSourceBottomSheet({
    required this.onTakePhoto,
    required this.onChooseFromGallery,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advancedTextures = GetIt.I<SettingsBox>().value.theme.advancedTextures;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          if (advancedTextures)
            const Positioned.fill(
              child: BlurAppBarBackground(alpha: .5),
            ),
          Material(
            color: advancedTextures
                ? theme.colorScheme.surface.withValues(alpha: 0.5)
                : theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Wrap(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.camera_alt,
                            color: theme.colorScheme.tertiary,
                          ),
                          title: Text(
                            'Take a photo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: const FontWeight(700),
                            ),
                          ),
                          onTap: onTakePhoto,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.photo_library,
                            color: theme.colorScheme.tertiary,
                          ),
                          title: Text(
                            'Choose from gallery',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: const FontWeight(700),
                            ),
                          ),
                          onTap: onChooseFromGallery,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

