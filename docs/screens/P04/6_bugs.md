# P04 · Privacy consent — bug hunt (Stage 6, iteration 7)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run. **No screen code was changed.** Re-hunted the iteration-7 tree
after the font-bundling merge (`1b2109e`, main `bbc7b55`/`a4691f9`:
google_fonts removed, Inter/Nunito bundled) and shared batch 2 (`0bafd2a`).

`app/test/features/privacy_consent/p04_bugs_test.dart`: **17 proofs —
16 green + 1 skipped** (the new P04-10). Nine of the ten findings are fixed
and pinned; the tenth is new this iteration. Run the skipped proof with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 16 passed, 1 failed (P04-10, by design)
```

A regression **did** slip through this iteration's font change: the opt-card
title now wraps to two lines. `VERDICT: FAIL`.

## New finding

### P04-10 — the opt-card title wraps to two lines after the font bundling; card 22 px taller than the design — MAJOR

- **Symptom (visible in `ui/app_light_7.png` / `ui/app_dark_7.png`):**
  "Optional: help improve **Nestling**" breaks after "improve"; the title is
  2 × 22 px instead of one 16/22 line, and the opt card runs 531→643 instead
  of the design's 531→621 — 22 px taller than both the design and the
  iteration-6 shot (which was one line). Both themes, `SEED=fresh`, parent.
- **Objective regression:** `compare.py` mean diff rose from iteration 6 to
  iteration 7 — light 4.08 %→**4.45 %** (band 5 4.19→**6.82** %, band 6
  0.40→0.82 %), dark 3.98 %→**4.43 %** (band 5 4.44→**7.79** %, band 6
  0.39→0.80 %). Bands 5–6 are exactly the opt-card region.
- **Root cause (measured, not guessed):** the design's `.opt-title` has **no
  letter-spacing**, but the app's `NestType` styles are `inherit: true` and
  omit `letterSpacing`, so the Scaffold's Material `DefaultTextStyle`
  (`bodyMedium`, `letterSpacing: 0.3`) leaks in. With the newly bundled Inter
  (which matches the design's own static build), the title needs
  **250.2 px** in P04's **247 px** text column:
  - widget style alone (bundled Inter): `TextPainter` width **242.5 px**;
  - merged with the Scaffold default (`letterSpacing: 0.3` over 30 glyphs):
    **250.2 px** → wraps.
  The design avoids this because its text column is **255 px** (its toggle
  occupies 51 px; `NestToggle` reserves `minWidth: 59`), and its font has no
  tracking. Before the bundling, the runtime-downloaded Inter was ~9 px
  narrower and the string fitted at 247 (iteration-6 shot: one line, 241.7 px).
- **Repro (test):** `--run-skipped … --plain-name '[P04-10]'` — the proof
  loads the bundled `assets/fonts/Inter-*.ttf` via `FontLoader('Inter')`,
  pumps `/privacy`, and measures the rendered title: expected height `22`,
  actual `44.0`; the follow-up assertion pins the card at the design's `94`
  (currently 116). Deterministic — the same measurement the device makes.
- **Failing test:** `[P04-10] the opt-card title stays on one 22px line`.
- **Fix (shared; either option clears P04 — filed as SHARED_REQUEST §7):**
  1. **Core typography (preferred):** default `letterSpacing: 0` in
     `NestType._inter/_nunito` (or zero the textTheme in `NestTheme`) so
     Material's 0.3 px tracking stops leaking into design styles app-wide;
     the design sets no tracking except `.display`/`.status-time`
     (-0.01 em).
  2. **Core component:** `NestToggle` `minWidth: 59` → the design's 51
     (the track still clears the 44 px tap target), restoring the design's
     255 px text column.
  A P04-local `letterSpacing: 0` on this one Text would clear the screen but
  leaves the leak on every other screen; prefer the shared fix.

## Disposition — iterations 1–5 findings (all fixed and green)

| Id | Sev | Finding | Status / proof |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** (it. 2, transactional upsert; migration also guarantees the row) |
| P04-2 | major | row 4 empty peach tile | **FIXED** (it. 5, `NestIcons.trash`; shot probe: 1005 ink pixels at 463–503) |
| P04-3 | major | compact nav 16 px short | **FIXED** (shared merge; chevron 73, h1 107) |
| P04-4 | major | dividers inflate the list 3 px | **FIXED** (it. 4; shared `NestList` overlay, four direct children; tiles 295/351/407/463) |
| P04-5 | minor | double-tap wrote the same value twice | **FIXED** (it. 2, optimistic emit) |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** (it. 2, state-aware caption) |
| P04-7 | major | dark shield rendered light | **FIXED** (it. 5, `NestPrivacyShield`; disc `#1A2A4A`, body `#1F1C2E` = design) |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (it. 3, revert to `_crashFrom(items)`) |
| P04-9 | minor | overlapping first-run writes kept the earlier value | **FIXED** (it. 4, transaction; deterministic proof green) |

## Verified this iteration

- **FONTS rule:** `grep -rn "google_fonts|GoogleFonts" app/lib app/test
  app/pubspec.yaml` → **no matches**; every P04 test file is clean (the
  iteration-7 build removed the last four call sites).
- **Identity/pixel probes on `ui/app_{light,dark}_7.png`:** row-4 rust glyph
  present; dark disc/body exactly the design's; light disc `#E6EFFE`; tile
  tops 295/463 and opt-card top 531.7 vs design 531.3; bottom CTA surface to
  the physical edge both themes (`#FFFFFF` / `#1F1C2E` at y 838); h1 gutter
  x≈20.
- **Guards re-run green:** kid-mode redirect to `/parental-gate`, deep-link
  back to `/create-account`, restart persistence (demo + first-run),
  first-run double-tap last-write-wins, async-gap after leaving, single
  dialog on a double tap.
- **Unchanged / N/A:** 320 px × scale 1.3 matrix, dark token contrast
  (a11y tests), copy locked to the HTML source, child-order rule (no
  children), timezone/money (no dates or money on P04).
- **Process note (not a finding):** at hand-off this worktree also contains
  another stage's untracked `zz_probe_test.dart` (self-declared temporary)
  which is the only source of `flutter analyze` infos; the P04 feature files
  themselves are analyzer-clean.

## Suite state at hand-off

- `flutter test test/features/privacy_consent/` → **159 passed, 1 skipped,
  0 failed** (the skip is P04-10).
- `flutter test test/features/privacy_consent/p04_bugs_test.dart` → 16
  passed, 1 skipped.
- `--run-skipped` on the bug file → **1 failed** (P04-10: title 44 vs 22).
- Feature sources: `dart format` clean, `flutter analyze` clean (the
  app-wide analyzer infos belong to the other stage's temp probe above).

## Verdict

Nine of ten findings are fixed and pinned, and the two shared-batch wire-ups
from iteration 5 (trash glyph, themed shield) are verified on the iteration-7
shots. But the font bundling regressed the opt card: its title wraps to two
lines and the card is 22 px taller than the design, lifting the compare bands
5–6 and making this screen visibly different from both the design and its own
iteration-6 state. The fix is shared (typography tracking or `NestToggle`
width) and is filed with measurements.

VERDICT: FAIL
