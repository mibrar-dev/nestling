# P04 · Privacy consent — bug hunt (Stage 6, iteration 9)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run. **No screen code was changed.** Re-hunted the iteration-9 tree
after the screen-wide letter-spacing fix (P04-11: the view's ambient
`DefaultTextStyle.merge(letterSpacing: 0)` + inlined dialog title, checkpoint
`dfb4a63`) and the shared core default (`NestType` letterSpacing 0, main
`fd92d95`, merged `df7c5e1`).

`app/test/features/privacy_consent/p04_bugs_test.dart`: **17 proofs, all
un-skipped and green** — zero skips in the feature suite. All eleven findings
across the loop are fixed and pinned. **No new bug was found.**

## P04-11 disposition — fixed (found by the iteration-8 test stage)

- **What it was (MAJOR, latent):** Material's `bodyMedium` tracking
  (`letterSpacing: 0.25`) leaked into **14 of 15** text runs on the screen
  because `NestType` styles were `inherit: true` and omitted
  `letterSpacing`. The design sets tracking only on `.display` and
  `.status-time` (neither used on P04), so every run was the wrong width; it
  had already caused the P04-10 wrap. Pinned by the iteration-8
  `privacy_consent_geometry_test.dart` (3 red tests), invisible to the
  390 dp UI check because no box edge moved.
- **Fix (iteration 9):** the Scaffold body is wrapped in
  `DefaultTextStyle.merge(style: TextStyle(letterSpacing: 0))` and the
  Privacy Notice dialog inlines its title with `letterSpacing: 0` (the
  dialog's `Material` re-applies `bodyMedium` nearer to the content). The
  shared core default (`NestType._inter/_nunito` → `letterSpacing ?? 0`)
  landed in the same merge, so the screen is now correct with or without the
  ambient zero.
- **Device evidence (`ui/app_light_9.png` / `app_dark_9.png`):** every
  measured dark-pixel extent is now **identical to the design** — h1
  30.0→299.7 (design 299.7), standfirst 30.3→338.3 (338.3), row-1 title
  283.0 (283.0), row-1 sub 321.7 (321.7), opt title 277.0 (277.0), opt sub
  265.0 (265.0). The opt card stays at 531.7→616.0 vs the design's
  531.3→616.0.
- **Objective:** `compare.py` mean diff is the best of the whole loop —
  light **1.84 %** (was 3.87 %), dark **1.74 %** (was 3.76 %); the
  text-width bands collapsed (band 1 6.02→**0.29** %, band 5 2.60→**0.52** %,
  band 6 0.40→**0.21** %). Residual band 7 (4.16/2.94 %) is the ignored
  status bar and the OWNER-rule bottom strip, both expected.
- **Proof:** the iteration-8 geometry contract tests (6/6 green) own this
  finding; `[P04-10]` (title one line, card 94) remains green.

## Iterations 1–8 findings — all fixed and pinned

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** (transactional upsert; migration guarantees the row) |
| P04-2 | major | row 4 empty peach tile | **FIXED** (`NestIcons.trash`; 1005 ink pixels on the shots) |
| P04-3 | major | compact nav 16 px short | **FIXED** (shared merge; chevron 73, h1 107) |
| P04-4 | major | dividers inflate the list 3 px | **FIXED** (shared overlay; tiles 295/351/407/463) |
| P04-5 | minor | double-tap wrote the same value twice | **FIXED** (optimistic emit) |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** (state-aware caption) |
| P04-7 | major | dark shield rendered light | **FIXED** (`NestPrivacyShield`; disc `#1A2A4A`, body `#1F1C2E`) |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (revert to stored) |
| P04-9 | minor | overlapping first-run writes kept the earlier value | **FIXED** (transaction) |
| P04-10 | major | opt-card title wrapped after font bundling | **FIXED** (it. 8; superseded in scope by P04-11) |
| P04-11 | major | Material tracking leaked into 14/15 runs | **FIXED** (it. 9, screen-wide ambient zero + core default) |

## Adversarial checks this iteration

- **LETTER SPACING rule:** P04 sets no tracking where the design has none and
  adds none back; the ambient zero is the design's own value. The known
  non-zero call sites (P12 hero -0.4, K02 `.mark` 1.28) do not exist on P04.
- **FONTS rule:** no `google_fonts`/`GoogleFonts` imports or calls anywhere in
  `app/lib`/`app/test` (the a11y guard builds its needles from pieces and
  scans itself).
- **Guards green:** kid-mode redirect to `/parental-gate`, deep-link back to
  `/create-account`, restart persistence (demo + first-run), first-run
  double-tap last-write-wins, async-gap after leaving, single dialog on a
  double tap, both failure captions, dialog geometry at 320 px / 1.3×.
- **Owner rules on the iteration-9 shots:** 20 px gutters; header at design y;
  list/card/CTA aligned; CTA surface to the physical edge in both themes
  (`#FFFFFF` / `#1F1C2E` at y 838); no coloured strip.
- **Unchanged / N/A:** children/long names/coins/£ values, timezone, money
  rounding (no such data on P04); Pip rule (no Pip); child-order rule (no
  children).
- **Optional cleanup (not a defect):** with the core `letterSpacing ?? 0`
  default now merged, the view's ambient `DefaultTextStyle.merge` and the
  inlined dialog title are redundant no-ops; they are harmless and can be
  simplified whenever the loop next touches the view. `SHARED_REQUEST.md` §7
  still notes that `NestModal` titles on other screens render with Material
  tracking until every consumer gets the same treatment.

## Suite state at hand-off

- `flutter test test/features/privacy_consent/p04_bugs_test.dart` → **17
  passed, 0 skipped, 0 failed**.
- `flutter test test/features/privacy_consent/` → **168 passed, 0 skipped,
  0 failed**.
- `flutter test` (whole app) → **862 passed, 0 skipped, 0 failed**.
- `dart format --set-exit-if-changed .` → 376 files, 0 changed;
  `flutter analyze` → No issues found.
- `compare.py` vs `ui/app_light_9.png` → **1.84 %** (bands 1.56 / 0.29 /
  1.08 / 3.75 / 3.16 / 0.52 / 0.21 / 4.16); vs `ui/app_dark_9.png` →
  **1.74 %** (1.57 / 0.31 / 1.08 / 3.81 / 3.18 / 0.77 / 0.23 / 2.94).

## Verdict

Eleven findings across the loop, all fixed and pinned. The last one
(P04-11, the screen-wide tracking leak that caused the P04-10 wrap) is closed
by the screen-wide zero plus the shared core default, and the iteration-9
shots are pixel-identical to the design on every measured text run, with the
best compare scores of the loop (light 1.84 %, dark 1.74 %). No major bugs
remain; the only follow-ups are optional redundancy cleanup and the core
`NestModal` tracking note, neither of which affects P04's behaviour or
appearance.

VERDICT: PASS
