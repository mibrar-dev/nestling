## Why SVG for icons and WebP for illustrations

**Icons stay SVG.** All 62 sit on one 24x24 grid, one `currentColor` stroke, no
gradients, no filters, no embedded rasters. One file serves every size and both
colour modes: the platform rasterises at the display density, and
`ColorFilter.mode(..., BlendMode.srcIn)` re-tints the same path for active tabs,
disabled states, the four avatar colours and dark mode. A 1x/2x/3x PNG set would
need 189 files for the same ink coverage, and every non-default colour would need
its own exported copy. SVG also keeps one `ImageCache` entry per icon instead of
six density buckets — that matters when a tab bar, a list and a sheet are all
mounted at once.

**Illustrations are the other way round.** Pip, the nest, the coin, the jar and
the badges are 240-350px multi-colour art that gets scaled per screen (Pip appears
at 64px in a list row and 280px on K06). That is a raster workload: a decoded
`ui.Image` blit is far cheaper than re-walking thousands of path commands, and
Flutter caches decoded images per size. WebP over PNG because these are flat
colour art with large smooth areas — WebP lossless typically lands 25-35% smaller
at visually identical quality, and iOS decodes WebP natively.

The SVGs stay in the bundle either way, so nothing is lost: point a
`NestlingImages` reference at the matching `NestlingIllustrations` constant and it
still renders. `NestlingImages.precache` keeps the first frame clean without
shipping the whole set through the raster pass.

## Conventions baked into this pack

- **Icon files carry no `width`/`height`.** Size at the call site. `viewBox` is
  always `"0 0 24 24"`.
- **`currentColor` everywhere** in icons, so always tint. An untinted icon renders
  black, which is almost never what the design wants.
- **`app_icon.svg` is full-bleed.** No `rx`, no outer stroke, opaque `#17804F` edge
  to edge. iOS and Android apply their own masks, so baked-in rounded corners give
  you a double-rounded, outlined launcher icon. Only `app_icon_foreground.svg` is
  transparent, because the adaptive-icon foreground has to be.
- **`ic_heart` is the solid glyph** (`fill` + `stroke` both currentColor);
  `ic_heart_outline` is the empty one, for the 4-of-5 hearts row on K03.
- **`ic_circle` is the empty stroked ring** (K11 happy-day dots). It was called
  `ic_dot`, which was wrong — nothing in the pack draws a filled dot. The filled
  variant is `ic_check`.
- **Illustrations are not colourable** (`colourable: false`). Pip has authored
  plumage, the badges authored ribbon colours, the meadow authored greens. Only
  recolour via `colorFilter` where the design shows a muted variant — the five
  "not yet earned" badges, which are already drawn grey and dashed.
- **`clipPath` ids are namespaced** (`nestling-jar-in`) so two jar SVGs on one
  route cannot collide in flutter_svg.
- **`rgba()` was rewritten** to `#1E1B3A` + `fill-opacity` in the copied Pip /
  nest / coin art, because `vector_graphics` handles opacity more predictably.
- **Google Fonts:** `google_fonts` fetches at runtime by default. For a children's
  app under the ICO Children's Code you almost certainly want the fonts bundled
  instead — set `GoogleFonts.config.allowRuntimeFetching = false` and ship the
  Inter/Nunito TTFs as assets, or await `GoogleFonts.pendingFonts()`. Keeping the
  names in code (rather than hard-coding `fontFamily:`) makes that a one-liner.

## QA history

**Round 1 — applied**

1. `app_icon.svg` -> full-bleed square. Removed the `rx="240"` corner radius and
   the 24px outer stroke; background is now an opaque `#17804F` rect edge to edge.
   Pip head re-centred at **62%** of the canvas (635px of 1024) via
   `translate(512 512) scale(0.83) translate(-510.5 -478)`. The rounded-square
   version is preserved as a design reference in the OpenDesign project's original
   `assets/app-icon.svg`.
2. `ic_ball` **redrawn** as a football (circle + pentagon). The original drew two
   inward-curving arcs inside a circle, which reads as a clock or a segmented dial,
   not as a ball — and it sits on the K06 "Play" action. The pentagon is
   unambiguous at 24px.
3. `ic_dot` **renamed** to `ic_circle` (Dart: `NestlingIcons.circle`). It was
   always an empty stroked circle, never a filled dot.
4. `NestlingImages` extended from 8 to **25** constants — every illustration plus
   the three brand PNGs — with a per-asset `rasterBox` giving the 1x target, and a
   new `NestlingImages.precache` list (Pip stages, nest, coin) for startup.

`app_icon.svg` puts the head at 62%; `app_icon_foreground.svg` stays at 66%. That
4% delta is deliberate — 66% is Android's guaranteed-visible adaptive-icon safe
area and is a platform constraint, not a style choice. Do not unify them.

## Known issues found in the screens (not in this pack)

Source-design problems. The assets are extracted faithfully — fix them in the
screens or map around them in Flutter.

1. **P10 quest rows are icon-shifted by one.** The table shape sits in the "Put
   the bins out" row, the bin shape in "Empty the dishwasher", the paw in "Hoover
   the stairs", and the book in "Help with the washing". Icons are named by
   **shape**, not by the row they were authored into — re-map `NestlingIcons` to the
   right quest when you build P10.
2. **K08 "Park cafe trip"** was authored with the lamp shape. `ic_lamp` is now a
   real lamp and `ic_cafe` a real coffee cup, so re-map the K08 card to
   `NestlingIcons.cafe`.
3. **P14 and K08 draw two different reward icon sets** for the same rewards
   (`ic_film` vs `ic_film_strip`, `ic_clock` vs `ic_moon`, `ic_cafe` vs
   `ic_lamp`). These are distinct subjects, not duplicates — film player vs film
   strip, clock vs moon, coffee cup vs lamp. Kept separate deliberately.
   `ic_baking_bag` was the one true duplicate and was deleted in QA round 2;
   K08 baking now uses `ic_chef_hat`.
4. **Two container glyphs:** `ic_bin` (UK wheelie bin, "Put the bins out") and
   `ic_basket` (laundry basket, P02/P04). Not merged — different objects.
5. **Three authored lock variants** (P17, P15+P16, kid screens) merged into
   `ic_lock`; three authored check weights (2, 2.6, 3) merged into `ic_check` at
   stroke-width 2. Restore the chunkier kid tick with a heavier stroke if the 56px
   kid target reads thin.
6. **`meadow_hill` was authored with `preserveAspectRatio="none"`** so the hills
   stretch to the device width. In Flutter prefer `DecorationImage(fit:
   BoxFit.cover)` or the `nestlingKidSky` gradient rather than `SvgPicture`, so the
   curves are never distorted.
7. **No dark mode in tokens.css.** `NestlingColorsDark` is derived, not authored —
   read its doc comment and get design sign-off before shipping it.
8. **No `ic_eye_off`.** P03 has a show-password eye only; build the sibling from
   `ic_eye` plus a slash when you wire the toggle.

## Excluded

| Asset | Why | Use instead |
| --- | --- | --- |
| Apple mark (P03) | Apple brand guidelines | Official *Sign in with Apple* SDK button (`sign_in_with_apple`) |
| Google "G" (P03) | Google branding guidelines | Official *Google Sign-In* SDK button (`google_sign_in`) |
| Signal / wifi / battery | Drawn by iOS and Android | The real status bar |

Do not ship the two sign-in vectors. All five are recorded in `manifest.json` under
`kind: "excluded"` and mirrored in `NestlingExcluded` in the generated Dart file, so
they cannot be reintroduced by accident.

## What the orchestrator still has to do

1. **SVGO** every file in `assets/icons/` and `assets/illustrations/`
   (`preset-default`, `removeViewBox` **off** — the viewBox is required for scaling,
   and `currentColor` must survive).
2. **Rasterise all 22 illustrations** to `assets/images/<name>.webp` at 1x/2x/3x.
   The 1x target for each is its largest on-screen usage and is recorded in that
   entry's `rasterBox`, e.g. `pip_stage_3` 280x280, `meadow_hill` 390x390,
   `confetti` 320x250, `coins_burst` 320x320, `sparkles` 350x350, badges 104x104.
3. **Rasterise the 3 brand PNGs** at 1024x1024 from `assets/brand/app_icon.svg`,
   `app_icon_foreground.svg` and `app_icon_background.svg`. Keep the foreground's
   alpha; `remove_alpha_ios: true` handles the composite on the iOS side.
4. **QA sizes:** icons under ~1 KB after SVGO, illustrations under ~4 KB.
   `pip_stage_4` is the heaviest (2.4 KB) because of the three tail feathers and the
   scarf.

## File map

```
flutter/
  manifest.json                    source of truth for every asset
  pubspec_snippet.yaml             deps + assets/ + flutter_launcher_icons
  README.md
  assets/
    icons/            62 x ic_*.svg          24x24, currentColor
    illustrations/    22 x *.svg            full colour
    brand/             3 x *.svg             1024 launcher artwork
    images/            25 x *.webp           (pending raster pass)
  lib/
    gen/nestling_assets.dart        NestlingIcons / Illustrations / Brand / Images
    theme/nestling_tokens.dart      colours, spacing, radii, shadows, type, ThemeExtension
```
