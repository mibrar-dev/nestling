# Nestling — design deliverables (v1.1)

Source of truth: Open Design project `nestling-uk-family-chores-mobile-ui-e9c1`
(`~/Library/Application Support/Open Design/namespaces/release-stable/data/projects/nestling-uk-family-chores-mobile-ui-e9c1/`).

## screens/ — one PNG per screen, 1170×2532 (iPhone, 390×844 @3x), lossless
- `light/` — 30 screens
- `dark/` — the same 30 screens in dark mode

| Group | Screens |
|---|---|
| Onboarding | P01 welcome · P02 value tour · P03 create account · P04 privacy · P05 add children · P06 pocket money · P07 paywall · P17 parental gate |
| Parent | P08 today · P08b today (empty) · P09 quest editor · P10 quest library · P11 approvals · P12 money · P13 payout · P14 rewards · P15 child profile · P16 settings |
| Kid mode | K01 profile picker · K02 PIN · K03 kid home · K03b all done · K04 quest detail · K05 quest complete · K06 Pip · K07 evolution · K08 shop · K09 jar · K10 payout day · K11 badges |

## store/ — upload-ready, RGB (no alpha)
- `ios-6.9in-1320x2868/` — 8 slides (App Store required size)
- `ios-6.5in-1284x2778/` — 8 slides (optional older size)
- `play-phone-1080x1920/` — 8 slides (Google Play phone)
- `play-feature-graphic-1024x500/` — Play feature graphic

Slides: 01 hero · 02 quests · 03 Pip · 04 pocket money · 05 approvals · 06 rewards · 07 payout day · 08 privacy.
Copy speaks to parents only (Apple 2.3.8 / 5.1.4(b): no "for kids" wording); no prices except "14-day free trial".

## flutter/ — optimised asset pack
- `assets/icons/` — 63 line icons, SVG 24×24, `currentColor` (tint with `ColorFilter`)
- `assets/illustrations/` — 22 colour SVGs (SVGO-optimised)
- `assets/images/` + `2.0x/` + `3.0x/` — WebP rasters of every illustration (Flutter picks the density automatically)
- `assets/brand/` — `app_icon.png` 1024 (full-bleed, no alpha), `app_icon_foreground.png` (adaptive), `play_store_icon_512.png`, source SVGs
- `lib/gen/nestling_assets.dart` — typed path constants (`NestlingIcons`, `NestlingIllustrations`, `NestlingImages`, `precache` list); all 113 paths verified to exist
- `lib/theme/nestling_tokens.dart` — light + dark colour tokens, spacing, radii, text styles, `ThemeExtension`
- `pubspec_snippet.yaml` — `flutter_svg`, `google_fonts`, asset folders, `flutter_launcher_icons` config
- `manifest.json`, `optimisation-report.json`, `README.md`

Fonts: Nunito + Inter via the `google_fonts` package (or bundle the TTFs from Google Fonts for offline).
