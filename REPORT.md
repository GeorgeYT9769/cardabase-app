# Card picture flow: camera/gallery choice, camera release, easier framing and editing

Target: cardabase-app v1.10.0 (`1.10.0+25`)

Files changed:
- `lib/feature/cards/edit/widgets/form_fields/take_picture_button.dart`
- `lib/util/camera_controller.dart`
- `lib/util/card_cropper.dart` (**new**)

A unified diff of all files is included (`card-image-ux.patch`).

> Note: I could not run `flutter analyze` / build in my environment, so the changes are untested on a device. Please compile and test before merging.

## Problems

1. **Tapping "Front face picture" / "Back face picture" always opens the camera.** Even when the user only wants to upload an image from the gallery, the camera is initialised first (CPU/battery use, device heats up) and the gallery is reachable only through a small icon inside the camera screen.
2. **Camera stays active while editing.** After taking a photo the app switches to the edit mode, but `CameraController` is never disposed until the whole screen is closed. The Android "camera in use" indicator (green dot) stays on. `didChangeAppLifecycleState(resumed)` could also silently restart the camera while editing.
3. **Framing a card is hard.** The user has to align the card to the frame while holding the phone, with no hint that the photo can be adjusted afterwards.
4. **Editing is complicated.** Gallery images were shown with `BoxFit.contain` over the full screen and had to be moved/scaled by hand into the frame. Rotation only had a two-finger gesture and a slider, with no snapping, no haptic feedback and no way to get back to exactly 0° (it always ends up slightly off).

## Changes

### `take_picture_button.dart`
- Tapping the picture box now opens a bottom sheet: **Take a photo** / **Choose from gallery**.
- For the gallery, `ImagePicker.pickImage` is called directly from the form. The camera screen is not started at all; the picked file is passed to `CameraControllerScreen(initialImage: ...)`. Cancelling the picker returns to the form.

### `camera_controller.dart`
- New optional parameter `initialImage`. If set, `initState` goes straight into the editor and never calls `_initializeCamera()`. "Retake" in this case just pops back to the form.
- New `_releaseCamera()`: nulls `_cameraController`, rebuilds (so `CameraPreview` leaves the tree), waits for `endOfFrame`, then calls `dispose()`. It turns the flash off first. It is called after:
  - `takePicture()` succeeds,
  - an image is picked from the gallery inside the camera screen,
  - a canvas color is chosen.
  This removes the system camera indicator while editing.
- `_initializeCamera()` is idempotent (returns if a controller exists) and is called again by `_retakePicture()`.
- Lifecycle: the camera is released on `inactive`/`paused`; on `resumed` it is restarted only if we are in live-camera mode (not editing, not opened from gallery).
- `_takePicture()` now uses a local, null-checked controller. A double tap on the shutter can no longer hit a released controller (previously this would have popped the screen via the `catch`).
- **Easier framing / editing**
  - Hint text above the frame in camera mode: "Place the card inside the frame. You can adjust it after taking the photo."
  - Gallery images are auto-placed to **fill** the frame, centered (`_applyPhotoFit(fill)`). The fit is computed from the real image size and the current rotation (bounding box of the rotated frame/image).
  - New tool row (shown when the background photo is selected or nothing is selected, so no extra tap is needed): rotate 90° left, reset rotation to 0°, rotate 90° right, toggle **fill the frame / fit whole photo**. Rotating with these buttons re-applies the current fit mode.
  - Rotation snapping to 0/90/180/270° within ~3.4° (`_snapRotation`), applied to the two-finger gesture and to the rotation slider, for the photo and for overlays. A `HapticFeedback.selectionClick()` is fired once when the snap point is entered, and the value stays "sticky" until the user rotates past the threshold.
  - Max scale raised from 4.0 to 6.0 (`_maxScale`) so "fill" works for very wide/tall images.
  - Manual pan/zoom/rotate switches the fit mode to `custom` so the fit buttons don't fight the user's adjustments.

## New: card cropper (`card_cropper.dart`) — Document-Scanner-style crop

Photos from the camera and from the gallery now go through a new `CardCropScreen` before the existing editor:

- The photo is shown with a quadrilateral and 4 draggable corner handles (outside area dimmed). The corners are pre-filled by an automatic card detection.
- **Done** cuts the card out and corrects its perspective into a card-shaped (1.586:1) PNG. The result then opens in the existing editor (brightness, overlays, canvas) already filling the frame, so no manual zoom/centering is needed.
- Buttons: re-run auto-detect, rotate result 90°, **Skip** (use the whole photo as before), **Done**. Back returns to the camera (or the form for gallery images).
- The camera is already released before the cropper opens, and `resumed` does not restart it while the cropper is open.

Implementation (all in pure Dart, no new dependencies; the heavy work runs in `Isolate.run`):
- `_prepareImage`: decodes, applies EXIF orientation (`img.bakeOrientation`), limits the longest side to 2400 px, saves a normalised JPEG used for display and warping, then runs `_detectCorners`.
- `_detectCorners` (heuristic): downsizes to ~320 px; takes the median colour of the outer 5% border as background; marks pixels far from it (Otsu threshold, minimum 20); morphological open/close; picks the connected blob containing the centre (or the largest); minimum-area rotated rectangle of its boundary (1° steps); validates blob size (4–90% of image), rectangle aspect ratio (1.2–2.2) and falls back to a centered card-shaped frame if not confident.
- `_warpAndSave`: unit-square → quad projective mapping (Heckbert) with bilinear sampling, output 800–1400 px wide at 1.586:1. If the marked quad is portrait, the corner order is shifted so the result is landscape.

Limitations:
- Detection assumes the card differs in colour from the surface around the image edge. It can fail on cards of the same colour as the table, or when something else touches the image border. Corners are always adjustable by hand.
- The detected rectangle ignores perspective, so for tilted photos the user may need to nudge the corners.
- No live (real-time) detection in the camera preview and no magnifier while dragging corners.
- Not compiled or tested on a device by me.

## Possible follow-ups (not done)
- Respect the app's `vibrateOnDifferentActions` setting for the snap haptic (currently uses `HapticFeedback.selectionClick()` directly; `VibrationProvider.vibrateSelection()` could be used instead).
- Live card-edge overlay in the camera preview (`startImageStream`), magnifier while dragging a corner, better detection (edge/contour based).
- Optional setting to remember the preferred picture source and to skip the cropper.
