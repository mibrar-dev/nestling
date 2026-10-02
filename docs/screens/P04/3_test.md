# P04 · Privacy consent — test notes (STAGE 3, iteration 5)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 5), `4_review.md`,
`5_ui.md`, `6_bugs.md`, `FIXES_4.md`, `SHARED_REQUEST.md` and the mandatory
`ORCHESTRATOR_NOTES.md` — including the **15:27 UPDATE**: `ic_trash.svg` /
`NestIcons.trash` and the token-coloured `NestPrivacyShield` are now in the
tree (shared batch merged as `ce89889`), and the only visible deviation left
was the blank row-4 tile.

## Test inventory — 131 P04 tests, **0 skipped** (every bug proof is green)

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, separator overlay, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `privacy_consent_artwork_test.dart` | 11 **(new)** | artwork provenance + painted-pixel theme proof |
| `p04_bugs_test.dart` | 16 | the nine bug proofs (all green) + clean-behaviour guards |

## Tests added this iteration

The iteration-5 build wired three shared pieces into the screen (trash glyph,
`NestPrivacyShield`, shared `NestList` overlay). Those are new rendering paths,
so this stage pinned **where the artwork comes from** and **what it actually
paints** — not just that something appears.

### 1. Trash glyph provenance (orchestrator note item 1)

- `the shipped SVG carries the design glyph path verbatim` — reads the row-4
  icon's `d="…"` from `design/html-source/screens/P04-privacy.html` and the
  `<path d>` from `app/assets/icons/ic_trash.svg` and asserts they are
  **identical**. This is the assertion that would have caught the original
  defect: a wheelie bin (`ic_bin`) or laundry basket (`ic_basket`) stand-in
  renders *something*, so "an icon exists" is not evidence — the path is.
- `the glyph is token-tintable, not a baked colour` — `currentColor`, no baked
  `fill="#…"`/`stroke="#…"` (a baked hex would ignore the peach ink and render
  wrong in both themes), 2 px stroke.
- `the tile ink is the design --a-peach token in both themes` — reads
  `--a-peach` from `design/html-source/tokens.css` (first = light block, last =
  dark block) and asserts `NestColors.light.aPeach` / `NestColors.dark.aPeach`
  match those hexes and differ from each other. Token-derived, so no hex is
  hard-coded in the app or the test.
- Light and dark widget tests: row 4 renders `NestIcons.trash` at 24 px, the
  icon colour **is** the theme's `aPeach`, the tile background **is** the
  theme's `peachTint`, and the painted `SvgPicture` carries that asset with a
  non-null `ColorFilter` (i.e. it is really tinted, not defaulted to black).

### 2. The shield paints theme tokens — a pixel-level P04-7 proof

`NestPrivacyShield` is a `CustomPaint`, so the previous proof ("the SVG no
longer bakes `#E6EFFE`") no longer covered what ships. The new tests
rasterise the screen's own painter and read the pixels back:

- `the screen uses NestPrivacyShield, not the baked SVG` — one
  `NestPrivacyShield`, **no** `SvgPicture` whose asset contains
  `privacy_shield`, and the design's alt label is announced.
- `84x84 by default and scaled by its size token`, and `the shield is announced
  as an image` (`isImage` semantics flag).
- `light` / `dark`: `every painted pixel is a theme token` — the painter is
  replayed into an 84×84 picture, and the opaque pixels must contain **all
  four** theme tokens (`skyTint` disc, `surface` body, `leaf` heart, `ink`
  stroke) and **none** of the other theme's `skyTint`/`surface`/`leaf`. That
  last assertion is the regression guard: it is precisely how the light-baked
  illustration broke dark mode, and it can never pass vacuously because the
  same test also requires > half the box to be painted.
- `the light and dark disc tokens match the design CSS` — `--sky-tint` from the
  design tokens file equals `NestColors.light.skyTint` / `NestColors.dark.skyTint`.

Two harness facts this cost me and the file now documents: `Picture.toImage`
clips to the requested box, so a transparent bounding rect is laid first; and
the packed pixel ints must be `0xAARRGGBB` (matching `Color.toARGB32()`), not
`0xRRGGBBAA` — the earlier wrong packing failed loudly rather than silently.

### 3. Re-verified after the mechanism change (no regression)

- **Separator (P04-4) with the shared `NestList` overlay:** row 1 carries none,
  rows 2–4 exactly one each; the line sits on its row's top, inset **72 px**,
  runs to the right edge, 1 px tall, `tokens.line` in both themes; the list is
  exactly the sum of its rows (zero layout height); wrapped rows at 320/1.3
  keep the line on the new boundary; each row stays one merged semantics node
  with no tap/long-press/focus action; and the geometry is still derived from
  the design's own `.list-row + .list-row::before` rule.
- **Bloc / repository:** all 20 + 13 pass unchanged (load, empty, stream error,
  both toggle directions, optimistic emit, revert-to-stored, error clearing,
  transactional first-run upsert with last-write-wins).
- **Routes, copy, a11y, owner rules:** Continue → `/add-children` in
  loaded/loading/failure, back with and without history → `/create-account`,
  toggle stays on `/privacy`, dialog opened and dismissed by `Close` and
  barrier; copy character-by-character against the HTML source (curly
  apostrophe, em dash, NBSP); 20 px gutters and card-edge alignment at
  320/390/430; bottom-CTA surface to the physical edge in both themes.

## Results

```
dart format --output=none --set-exit-if-changed .  → 367 files, 0 changed
flutter analyze                                    → No issues found! (ran in 5.7s)
flutter test test/features/privacy_consent/        → 00:04 +131: All tests passed!
flutter test (whole app)                           → 00:25 +684: All tests passed!
```

**Zero failures and zero skips** — first iteration where the whole P04 suite
runs clean, including all nine bug proofs.

## Bugs found this iteration

**None.** No defect surfaced in the iteration-5 tree. The shared artwork,
the trash wire-up and the shared overlay behave exactly as the fixes describe.

## Open items

None in P04 scope. Every previously filed item is closed:

- P04-1 first-run write dropped → upsert (green)
- P04-2 empty row-4 tile → shared `ic_trash.svg` + wire-up (green, plus the
  path-provenance proof above)
- P04-3 header 16 px high → shared compact nav (green)
- P04-4 separator drift → shared `NestList` overlay (green)
- P04-5 double tap, P04-6 false "it stays off", P04-8 revert target,
  P04-9 non-atomic upsert → all green
- P04-7 dark shield → shared `NestPrivacyShield`, now proven on the painted
  pixels rather than on the asset's source

`SHARED_REQUEST.md` §4's P16 half was never P04's to fix (same UPDATE-only
write shape in `SettingsRepositoryImpl`); §1/§2/§6 are consumed.

Orchestrator notes: item 1 is now proven at the asset-path, token and pixel
level in both themes; item 2 is pixel-exact; item 3 is exact (separator derived
from the design CSS); item 4 owner rules are asserted in both themes.

## Notes (not defects)

- Widget tests run without the bundled Inter/Nunito faces, so the block test
  font widens every line and pushes the opt card below the fold although it
  fits on a 390×844 device; helpers scroll with `ensureVisible` first.
  Absolute row heights stay a device (UI-check) measurement.
- `SemanticsHandle` from `tester.ensureSemantics()` must be disposed **inside**
  the test body; `addTearDown` runs after the end-of-test semantics check.
- Drift reads inside `testWidgets` need `tester.runAsync`; so does
  `Picture.toImage` when rasterising the shield.
- The copy, separator and artwork tests read `design/html-source/**` at
  runtime and fail loudly with the searched paths if the app is ever tested
  outside the repo — deliberately, rather than passing silently.

VERDICT: PASS
