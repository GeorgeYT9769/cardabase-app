# Follow-up 3: detection never ran for some photos, editor snapping, Fit/Fill

Base: branch `cropper-followup-2` (PR #89), including the maintainer's editor redesign (labelled buttons / control modes).

Files changed:
- `lib/util/card_cropper.dart`
- `lib/util/camera_controller.dart`

A unified diff against the branch head is included (`followup3.patch`).

> Note: not compiled or run on a device by me. Detection logic was checked with a Python port on two photos reconstructed from screen recordings (see follow-up 2).

## 1. Automatic detection: the native fallback skipped it completely

`_load` first runs `_prepareImage` in an isolate. If that throws (for example the pure-Dart decoder cannot decode a large phone photo), `_prepareImageNativeFallback` is used, and that fallback returned `_fallbackCorners(w, h)` **without running any detection**. The result is always the centered 80% frame, which is exactly what was seen in the recordings, no matter how good the detection is.

Fix (`card_cropper.dart`):
- The fallback now decodes a small (320 px) copy with the native decoder, reads the RGBA pixels and runs the same detection on it (`_detectFromChannels`, shared with the isolate path).
- `_detectCorners` / `_prepareImage` also return whether a card was found. When it was not, the hint under the photo says "Card not found automatically. Drag the corners onto the card." instead of the usual text.
- Detection results and exceptions are logged with `debugPrint` (`Card detection: found (score ...)` / `nothing found` / `Card detection failed ...`, and `Isolate _prepareImage failed ...` was already logged), so the next test shows in `flutter run` which path was used.
- The unused `_selectWholePhoto` method was removed (its button is not in the tool row anymore).

## 2. Editor: the photo "jumped" while moving it

The photo drag snapped (threshold 12 px) to the centre and the four edges of the frame, comparing them with the edges of a box of screen size x scale. That box is not the visible card or even the visible image, so the guide lines appeared at seemingly random positions and pulled the photo while trying to place the card precisely.

Fix (`camera_controller.dart`): the background photo now moves freely (no snapping, no guide lines). Snapping for text/image overlays is unchanged, where aligning to the centre/edges makes sense.

## 3. Editor: Fit/Fill looked like it did nothing

For a photo that already has the shape of the frame (a cropped card, ratio about 1.59) "Fit" and "Fill" give practically the same result, so nothing visibly happened. In addition the status message was computed before the async fit finished, so it described the previous mode.

Fix (`camera_controller.dart`): `_applyPhotoFit` now returns whether Fit and Fill differ (more than 3%). The button awaits it and shows a correct message: "Whole photo fitted inside the frame", "Photo fills the whole frame", or "Photo already matches the frame (Fit = Fill)".
