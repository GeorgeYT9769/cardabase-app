# Follow-up: card cropper UX (flash on back, linked sides, detection, final step)

Base: current `main` (card cropper + camera/gallery picker already merged).

Files changed:
- `lib/util/card_cropper.dart`
- `lib/util/camera_controller.dart`
- `lib/feature/cards/edit/widgets/form_fields/take_picture_button.dart`

A unified diff is included (`followup.patch`).

> Note: not compiled or run on a device by me. The detection heuristic was only sanity-checked with a Python port on one reconstructed photo.

## 1. Camera UI flashes when leaving the cropper (gallery flow)

Cause: in the gallery flow the app pushed `CameraControllerScreen(initialImage: ...)` only as a host for the cropper and the editor, and then pushed `CardCropScreen` on top of it. When the cropper was dismissed, the camera screen underneath (camera UI, shutter, frame, hint) was visible for a moment before it was removed too.

Fix: the intermediate screen is gone.
- `take_picture_button.dart`: for "Choose from gallery" the form now pushes `CardCropScreen` directly (`_cropAndUse`). Cancelling returns straight to the form. "Done" copies the cropped PNG to the documents directory and sets `picturePath`. "Edit more" pushes `CameraControllerScreen(initialImage: <cropped file>)`, which now means "open the editor directly with this (already cropped) image" and never starts the camera or the cropper.
- `camera_controller.dart`: `initialImage` opens the editor immediately (fill-fit applied); the cropper is only used in the camera flow (after a photo is taken, or after picking from the gallery icon inside the camera screen). While the cropper is open there the camera screen renders a plain black `Scaffold`, so no camera UI flashes when the cropper opens or closes. Cancelling the cropper returns to the live camera (`_retakePicture`).

## 2. Moving a whole side instead of single corners

`_QuadPainter`/gesture code in `card_cropper.dart`:
- New `_linkSides` toggle (default **on**, link icon in the tool row). When on, dragging a corner also moves its two neighbouring corners (`_moveCornerLinked`): the next corner moves only along the direction of the other side and vice versa, so for a rectangle this is the usual crop-box resize with the opposite corner fixed. It works for rotated frames too (directions are taken from the current sides).
- When off (link-off icon) every corner moves independently, as before (free perspective).
- The hint text under the image changes with the mode. Dragging inside still moves the whole frame.

## 3. Automatic detection did not place the frame

The frame in the reported screenshot was exactly the fallback frame (centered, 80% wide, 1.586:1), i.e. detection returned "not confident". The old segmentation (distance from the median border colour) is fooled by uneven lighting and shadows on a wooden table.

Changes (`_detectCorners`, now split into `_colourModelMask`, `_borderDistanceMask`, `_cornersFromMask`):
- New first strategy: a colour model. 8-level-per-channel histograms are built from the photo border (background) and the centre 40% (card); a pixel is "card" if its colour is clearly more typical for the centre. This copes much better with lit/shadowed tables.
- The previous border-distance segmentation is kept as a second attempt.
- Blob selection, minimum-area rotated rectangle and plausibility checks (blob size 4-90%, aspect ratio 1.2-2.2) are unchanged and shared (`_cornersFromMask`); if both strategies fail the centered fallback frame is still used.
- Portrait cards: in `_done`, if the marked quad is taller than wide the corner order is shifted so the output is landscape (the user can still rotate the image).

Limitations: still a heuristic. It can fail when the card has the same colours as the surface or when other objects touch the photo border; corners remain freely adjustable.

## 4. "Done" looked like the last step but opened another editor

- `CardCropScreen` now pops a `CardCropResult(path, edit)`.
- **Done** (green) = final: the cropped, perspective-corrected PNG is copied to the documents directory (`_finishWithoutEditing`) and returned directly to the form. No second screen.
- **Edit more** (new button, tune icon) = crop and then open the existing editor (brightness, text, stickers, canvas). The editor opens with the picture already filling the frame (`_applyPhotoFit(fill)` was missing after the cropper and is restored), so the "fit" button is no longer needed to make the card fit.
- The old **Skip** button was removed: it only opened the editor with the uncropped photo, which was confusing next to "Edit more". The corners can simply be dragged to the photo edges if the whole photo is wanted.
- Bottom bar: tool row (detect again, rotate, link toggle) and a button row (Edit more, Done).
