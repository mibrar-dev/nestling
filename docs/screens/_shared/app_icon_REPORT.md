# Report — shared/app_icon (Nestling launcher icon, iOS + Android)

## Files changed

Brand art (copied, names kept — already byte-identical with the
designer-approved sources in `design/flutter-asset-pack/assets/brand/`):

- `app/assets/brand/app_icon.png`, `app_icon.svg`,
  `app_icon_background.png/.svg`, `app_icon_foreground.png/.svg`,
  `play_store_icon_512.png` (copy only, not wired into the build)

Generated (do not hand-edit; re-run the script instead):

- `app/assets/brand/app_icon_foreground_adaptive.png` — foreground scaled
  0.8510 about its centre; opaque max distance 323.3 px <= safe circle 338 px
- `app/assets/brand/app_icon_monochrome.png` — ink (#1E1B3A ±40) recoloured
  white, alpha preserved; everything else transparent

Tooling (re-runnable from the repo root, no redraw of the art):

- `tools/brand/generate_icons.py` — derives the two files above, asserts the
  safe zone, prints scale/distances
- `tools/brand/render_preview.py` — renders the preview sheet below

Config + generated launcher output:

- `app/pubspec.yaml` — `flutter_launcher_icons: ^0.14.4` dev_dependency plus
  `flutter_launcher_icons:` config (`image_path` brand icon, `ios: true`,
  `remove_alpha_ios: true`, `android: true`, `min_sdk_android: 21` matching
  `flutter.minSdkVersion`, adaptive background/foreground/monochrome)
- `app/pubspec.lock` — new dev dependency
- iOS `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` — regenerated
  (Contents.json incl. 1024 ios-marketing, RGB, leaf-green corner verified) +
  `project.pbxproj` (new 50/57/72 px members)
- Android `app/android/app/src/main/res/mipmap-*/ic_launcher.png` (legacy),
  `drawable-*/ic_launcher_{background,foreground,monochrome}.png`,
  `mipmap-anydpi-v26/ic_launcher.xml` (background/foreground/monochrome)

Tests:

- `app/test/core/app_icon_test.dart` (new, 6 tests — names in § Tests added)

Preview:

- `docs/brand/icon_preview.png` — 180 px iOS rounded square; 192 px adaptive
  full-bleed with mask circle, circle-masked, squircle-masked; monochrome on
  a dark tile. Pip sits fully inside every mask; themed silhouette reads.

## What / why

The app shipped with default Flutter launcher icons (white iOS 1024 tile).
This wires the designer-approved Pip icon into both stores' launchers:
full-bleed brand art on iOS/legacy Android, safe-zone-fitted adaptive icon
plus a themed monochrome silhouette on Android 13+. The foreground's raw
opaque extent (max 381 px from centre) breached the 66 % mask circle, so the
script scales the whole layer about its centre (same art, 0.851x) instead of
cropping. No feature, theme, splash, router, or DI code touched.

## Tests added (`app/test/core/app_icon_test.dart`)

1. `brand source art is bundled at the expected sizes`
2. `adaptive foreground fits the Android safe zone`
3. `monochrome icon is a white-only silhouette in the safe zone`
4. `pubspec wires the generated icons into flutter_launcher_icons`
5. `iOS AppIcon lists all sizes incl. 1024 marketing without alpha`
6. `Android adaptive icon wires background/foreground/monochrome`

## Results

- `cd app && dart format .` — clean (only the new test file formatted once)
- `flutter analyze` — `No issues found!` (no new ignores)
- `flutter test --timeout 120s` (foreground) — all passed
  (`+5048 ~16: All tests passed!`, 16 pre-existing skips)
- Preview checked visually: Pip inside circle + squircle, mono readable.

## Follow-up screens must do

- Nothing. No shared API changed; no screen action needed. If the brand art
  ever changes, re-run `python3 tools/brand/generate_icons.py`, then
  `dart run flutter_launcher_icons` in `app/`, then
  `python3 tools/brand/render_preview.py`, and update this report.

VERDICT: PASS
