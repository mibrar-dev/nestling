# Shared body_text_width report

Branch: `shared/body_text_width` (from `main`). Task brief:
`docs/screens/_shared/body_text_width_finish.md`.

## Root cause

Body/subtitle copy rendered ~3 % wider than the design on every screen. The
shared type scale in `core/design_system/tokens/typography.dart` built its
styles through `GoogleFonts.inter(...)` / `GoogleFonts.nunito(...)`, which
resolves the font at **runtime** by downloading a TTF from the Google Fonts
API and registering it under a family name derived from the package. Two
consequences:

1. **The downloaded build is not the build the design used.** The design
   renders are headless-Chrome screenshots of `design/html-source/*.html`,
   whose only font source is
   `https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Inter:wght@400;500;600;700`
   — the **static** Inter 4.001 / Nunito 3.602 instances. `google_fonts`
   fetches its own copies, and every other build of Inter (variable builds,
   the `opsz` optical-size axis applied, other static cuts) has different
   advance widths. That is the ~3 % drift: it is a font-build mismatch, not
   a size / letter-spacing / line-height error. `tokens.css` confirms no
   optical-size axis, no `font-feature-settings` and no `font-size-adjust`
   on body copy — the only feature setting in the design is `'tnum' 1` on
   `.num/.money`, which is already `FontFeature.tabularFigures()` in
   `NestType.money`.
2. **First-frame text could render in a fallback face.** Until the download
   resolved, the label painted with the platform fallback at a different
   width, so screenshots and `TextPainter` measurements were not stable
   across runs either.

Fix: pin the exact design builds as bundled assets and drop the runtime
fetch entirely. No size, weight, height or letter-spacing value changed —
`NestType` keeps every metric it had.

## Files changed

| File | What |
|---|---|
| `app/assets/fonts/` (new, 7 files) | `Inter-Regular/Medium/SemiBold/Bold.ttf` (400/500/600/700) and `Nunito-Bold/ExtraBold/Black.ttf` (700/800/900) |
| `app/pubspec.yaml` | registers the `Inter` + `Nunito` asset families; drops `google_fonts: ^9.0.0` |
| `app/pubspec.lock` | regenerated (`google_fonts` removed) |
| `app/lib/core/design_system/tokens/typography.dart` | `_inter`/`_nunito` return `TextStyle(fontFamily: 'Inter'/'Nunito', …)` instead of `GoogleFonts.*`; doc comment rewritten |
| `app/lib/core/design_system/components/nest_avatar.dart` | `GoogleFonts.nunito` → `TextStyle(fontFamily: 'Nunito', …)` |
| `app/lib/core/design_system/components/nest_pet_stage.dart` | `GoogleFonts.nunito` → `TextStyle(fontFamily: 'Nunito', …)` (`NestSpeechBubble`) |
| `app/test/design_system/test_harness.dart` | drops `GoogleFonts.config.allowRuntimeFetching = false` |
| `app/test/design_system/theme_shell_test.dart` | same |
| `app/test/test_scope.dart` | same |
| `app/test/features/onboarding/welcome_view_test.dart` | same |
| `app/test/design_system/body_text_width_test.dart` (new) | the measurement test below |

Deliberately **not** changed:

- `app/ios/Podfile.lock` — the worktree's first iOS build regenerated it with
  a `flutter_timezone` pod entry that is unrelated to typography. Reverted so
  the shared diff stays reviewable; any iOS build regenerates it anyway.
- No `lib/features/**/presentation/**` file was touched. No `analysis_options`
  ignore was added.

### Font provenance (verified, not assumed)

Read straight out of each file's `name` table:

```
Inter-Regular.ttf   family='Inter'            sub='Regular'   Version 4.001;git-66647c0bb
Inter-Medium.ttf    family='Inter Medium'     sub='Regular'   Version 4.001;git-66647c0bb
Inter-SemiBold.ttf  family='Inter SemiBold'   sub='Regular'   Version 4.001;git-66647c0bb
Inter-Bold.ttf      family='Inter'            sub='Bold'      Version 4.001;git-66647c0bb
Nunito-Bold.ttf     family='Nunito'           sub='Bold'      Version 3.602
Nunito-ExtraBold.ttf family='Nunito ExtraBold' sub='Regular'  Version 3.602
Nunito-Black.ttf    family='Nunito Black'     sub='Regular'   Version 3.602
```

`fvar` is absent from all seven → every file is a **static** instance, i.e.
the same class of build the `css2` endpoint serves for the weights the design
HTML requests. The `Inter Medium` / `Inter SemiBold` / `Nunito Black`
family names are just Google Fonts' static-instance naming; Flutter keys off
the pubspec `family:` + `weight:` pair, so `fontFamily: 'Inter'` +
`FontWeight.w500` resolves correctly. The weights declared in `pubspec.yaml`
cover **every** weight used anywhere in `lib/` (w400/w500/w600/w700 Inter,
w700/w800/w900 Nunito).

## Before / after

Design reference (from the compare sheets: line start x=44, 390 scale):
P04 line ends x≈363 → width **319**; P05 ends x≈342 → width **298**.
Browser (Chrome) advances for the same strings at Inter 16/24 w400:
**319.97** and **298.43**.

| String (NestType.body, Inter 16/24 w400) | Design | Before (app ink) | After (measured) | Drift after |
|---|---|---|---|---|
| P04 `Exactly what we store — and nothing else.` | 319.0 | ≈330 (ends x≈374) | **319.97** | +0.30 % |
| P05 `Nicknames only — no photos, no email.` | 298.0 | ≈307 (ends x≈351) | **298.43** | +0.14 % |
| P03 `You're the grown-up in charge. Children never need an email.` | 463.59 (browser) | wraps a word early | **463.59** | 0.00 % |
| P04 `Your family's privacy` (Nunito 900 28, `h1`) | 280.52 (browser) | — | **280.56** | +0.01 % |

"Before" values are the orchestrator's ink-extent measurements on the
390-wide compare sheets (x≈374 / x≈351 ⇒ ≈3.4 % / ≈2.9 % wide). "After" are
`TextPainter` advances against the bundled assets. Both sides carry one
side-bearing of slack, so the residual ~0.2 % is inside measurement noise.

### Simulator check — `tools/screens/shot.sh`

```
bash tools/screens/shot.sh $PWD/app /privacy /tmp/bt_p04.png \
  604697A9-11DA-462F-9837-396E9CA2493A light fresh parent maya
python3 tools/screens/compare.py design/screens/light/P04-privacy.png \
  /tmp/bt_p04.png /tmp/bt_p04_cmp.png
```

`compare.py` mean diff **10.14 %** (bands 0-105: 3.66, 105-211: 10.54,
211-316: 8.47, 316-422: 12.56, 422-527: 7.71, 527-633: 6.60, 633-738: 24.62,
738-844: 7.03).

**That number is not a typography signal, and the subtitle cannot be
measured from it.** On this branch `/privacy` is still the foundation
placeholder — `PrivacyConsentView` is an `AppBar('P04 Privacy & consent')`
plus a `ListView` of seeded title/subtitle pairs. The design's own copy
(`Exactly what we store — and nothing else.`) is **not on screen yet**, so
"does the line end at x 363" is unanswerable here; the 10.14 % is the
placeholder-vs-design layout gap (wrong gutters, wrong card, wrong order)
that the P04 screen agent closes on their own branch.

What the shot *does* prove is that the bundled font is the one actually
painting on-device. Ink extents measured from `/tmp/bt_p04.png` (1170 px,
@3x) for the five rendered subtitle lines, against the advance predicted
from `assets/fonts/Inter-Regular.ttf` at the same size:

| Subtitle line | predicted ink | measured ink | Δ @390 |
|---|---|---|---|
| `Nestling never sells data or shows adverts.` | 905 | 903.0 | +0.67 px |
| `No photos, no email, no chat, no location.` | 870 | 873.0 | −1.00 px |
| `Your family data stays close to home.` | 788 | 786.9 | +0.37 px |
| `One tap in Settings removes your family.` | 859 | 849.9 | +3.03 px |
| `Optional — helps us fix bugs. Off by default.` | 938 | 930.9 | +2.37 px |

Worst residual 3.03 px at 390 scale (0.98 %), and part of that is my ink
threshold clipping the trailing period. So the simulator, the unit test and
the browser reference all agree on the same font metrics.

## Tests added

`app/test/design_system/body_text_width_test.dart` — loads the bundled
families through `FontLoader` in `setUpAll`, then measures with
`TextPainter`:

- `shared body text widths match the design › body style stays Inter 16/24 w400 from the bundled family`
- `shared body text widths match the design › P04/P05 body advances match the browser renders`
- `shared body text widths match the design › P03 subtitle unwrapped advance matches the browser render`
- `shared body text widths match the design › P03 subtitle wraps after "never" in a 350 px column`
- `shared body text widths match the design › P04 heading advance matches the browser render`

Tolerance is **1 %**, tighter than the 1.5 % the brief asked for. The test
cannot pass on a missing font: an unresolvable family advances one em per
glyph, so the P05 string would measure 592.0 instead of 298.43 — verified.

Gates: `dart format .` → 362 files, 0 changed. `flutter analyze` →
**No issues found!** (no new ignores). `flutter test` → **558 tests, all
pass** (557 before, +1 from the added style-wiring test).

## What follow-up screen agents must do

1. **Nothing is required.** The fix is entirely in shared code and is
   backward-compatible: same public API (`NestType.*` signatures unchanged),
   same families, same weights, same metrics. No screen file needs editing.
2. **Stop using `GoogleFonts.*`.** The dependency is gone from
   `pubspec.yaml`; any new `import 'package:google_fonts/google_fonts.dart'`
   will not resolve. Use `NestType.*` / `context.nestText.*` (tokens only,
   per `RULES.md`).
3. **No `allowRuntimeFetching` line in new tests.** Tests that used to set
   `GoogleFonts.config.allowRuntimeFetching = false` no longer need it; the
   four existing call sites were cleaned up. If you re-add a screen test
   copied from an older branch, drop that line.
4. **P04 / P05 / P03 owners:** re-run `shot.sh` + `compare.py` on your
   branch. The text now lands on the design advance, so any remaining band
   drift on those screens is layout, not type.
5. If you add a font weight that is not already bundled, add the `.ttf` to
   `app/assets/fonts/` **and** a matching `family`/`weight` pair in
   `pubspec.yaml` — an unbundled weight silently falls back and re-widens
   the text, which this test would catch for `body`/`h1` only.

VERDICT: PASS