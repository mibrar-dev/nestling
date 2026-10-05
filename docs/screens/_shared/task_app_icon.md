TASK — Nestling app icon, iOS + Android (shared/app_icon)

Source art (designer-approved, do not redraw): design/flutter-asset-pack/assets/brand/
- app_icon.png (1024², RGB, leaf-green #18804F-ish background + Pip) — iOS + legacy Android
- app_icon_foreground.png / .svg (1024², transparent) + app_icon_background.png / .svg — Android adaptive
- play_store_icon_512.png — Play Store listing (copy only; not wired into the build)

1. Copy the brand files into `app/assets/brand/` (keep names). Add `flutter_launcher_icons` (latest stable) as a dev_dependency and a `flutter_launcher_icons:` config in app/pubspec.yaml (or `flutter_launcher_icons.yaml`):
   - `image_path: assets/brand/app_icon.png`, `ios: true`, `remove_alpha_ios: true`, `android: true` (launcher_icon), `min_sdk_android` as the app uses.
   - Adaptive: `adaptive_icon_background: assets/brand/app_icon_background.png`, `adaptive_icon_foreground: assets/brand/app_icon_foreground.png`.
   - SAFE ZONE: Android masks adaptive icons to a circle/squircle of the inner 66 % (72 of 108 dp). Check that every opaque pixel of the foreground lies within a centred circle of radius 0.33×1024·(108/72)/… — concretely, produce `assets/brand/app_icon_foreground_adaptive.png`: the foreground scaled about its centre so its opaque bounding box fits inside the central 66 % circle (radius 338 px of 1024) with ~4 % margin, then use THAT as `adaptive_icon_foreground`. Do it with a small python/PIL script committed under tools/brand/ (re-runnable). Same art, just scaled — no redraw.
   - Monochrome (Android 13 themed icons): generate `assets/brand/app_icon_monochrome.png` from the adaptive foreground: every pixel with alpha > 0 becomes opaque white with the same alpha (single-colour silhouette; keep the eye/beak holes as transparent where the art's inner colours are light? — simplest acceptable: alpha silhouette of the dark ink outlines only: keep pixels whose colour is the ink #1E1B3A ±40, white, others transparent). Wire `adaptive_icon_monochrome:`.
2. Run `dart run flutter_launcher_icons` in app/. Commit the generated iOS AppIcon.appiconset and Android mipmap-*/ + mipmap-anydpi-v26/ files.
3. Verify: iOS Contents.json lists all sizes incl. 1024 marketing (no alpha); Android `ic_launcher.xml` has background/foreground/monochrome. Render a preview sheet `docs/brand/icon_preview.png` (python): iOS rounded square at 180 px; Android circle + squircle masks of the adaptive icon at 192 px; monochrome on a dark tile — so the orchestrator can check the safe zone visually.
4. `cd app && flutter analyze` (No issues found) and `flutter test --timeout 120s` in the FOREGROUND (all green). Do NOT touch any feature code, theme, or the splash. Commit. Write docs/screens/_shared/app_icon_REPORT.md (files, preview path, results) ending with `VERDICT: PASS` or `VERDICT: FAIL`.
