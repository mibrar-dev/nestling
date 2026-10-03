# P04 · Privacy consent — bug hunt (Stage 6, iteration 8)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run. **No screen code was changed.** Re-hunted the iteration-8 tree
after the P04-10 fix (the view zeroes the opt-card title's `letterSpacing`,
checkpoint `9ee096b`).

`app/test/features/privacy_consent/p04_bugs_test.dart`: **17 proofs, all
un-skipped and green** — zero skips in the feature suite. All ten findings
from iterations 1–7 are fixed and pinned. **No new bug was found.**

## P04-10 disposition — fixed (local half of SHARED_REQUEST §7)

- **Fix:** `privacy_consent_view.dart:135-142` sets `letterSpacing: 0` on the
  opt-card title in its `copyWith`, with a comment pointing at the shared
  half. The design sets no tracking; Material's `DefaultTextStyle` was
  leaking 0.3 px through `inherit: true`, which with the bundled Inter pushed
  the title to 250.2 px in the 247 px column.
- **Device evidence (`ui/app_light_8.png` / `app_dark_8.png`, read with the
  file reader):** the title is one line again — its dark-pixel extent is
  **37.0→277.0 in both the design and the app** (identical to 0.1 px); the
  opt card runs **531.7→616.0** vs the design's **531.3→616.0** (Δ0, card
  back to 94 px). Both themes.
- **Objective recovery:** `compare.py` mean diff is the best of any iteration
  — light **3.87 %** (was 4.45 %), dark **3.76 %** (was 4.43 %); the
  regression bands collapsed (band 5: 6.82→**2.60** % light, 7.79→**2.88** %
  dark; band 6 back to **0.40/0.39 %**).
- **Proof:** `[P04-10] the opt-card title stays on one 22px line` is
  un-skipped and green (it loads the bundled Inter faces so the test measures
  the device metrics).

## Iterations 1–5 findings — all fixed and pinned

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** (transactional upsert; migration also guarantees the row) |
| P04-2 | major | row 4 empty peach tile | **FIXED** (`NestIcons.trash`; 1005 ink pixels at 463–503 on the it.-8 shot) |
| P04-3 | major | compact nav 16 px short | **FIXED** (shared merge; chevron 73, h1 107) |
| P04-4 | major | dividers inflate the list 3 px | **FIXED** (shared overlay; tiles 295/351/407/463) |
| P04-5 | minor | double-tap wrote the same value twice | **FIXED** (optimistic emit) |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** (state-aware caption) |
| P04-7 | major | dark shield rendered light | **FIXED** (`NestPrivacyShield`; disc `#1A2A4A`, body `#1F1C2E` = design) |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (revert to stored) |
| P04-9 | minor | overlapping first-run writes kept the earlier value | **FIXED** (transaction) |
| P04-10 | major | opt-card title wrapped after font bundling | **FIXED** (local tracking fix above) |

## Carried shared remainder (not a P04 blocker)

The Material `letterSpacing: 0.3` still leaks into the screen's **other**
texts (`NestType` styles are `inherit: true`). Measured dark-pixel extents on
`ui/app_light_8.png` vs the design: h1 304.7 vs 299.7 (+5.0), standfirst
348.3 vs 338.3 (+10.0), row-1 sub 331.3 vs 321.7 (+9.6), opt sub 272.3 vs
265.0 (+7.3) — the expected 0.3 px × glyph count. **No layout impact on
P04:** every wrap point and every box edge matches the design; the tracking
only widens glyph runs inside their boxes. The shared half of
`SHARED_REQUEST.md` §7 (zero the tracking in `NestType`/`NestTheme`, or
`NestToggle` width 59→51) remains open for the orchestrator; it is carried,
not a P04 defect.

## Adversarial checks this iteration

- **FONTS rule:** the only `google_fonts`/`GoogleFonts` strings in the
  feature are inside `privacy_consent_a11y_test.dart`'s guard test that
  asserts the rule; no imports or calls anywhere in `app/lib`/`app/test`.
- **Guards green:** kid-mode redirect to `/parental-gate`, deep-link back to
  `/create-account`, restart persistence (demo + first-run), first-run
  double-tap last-write-wins, async-gap after leaving, single dialog on a
  double tap, failure captions both directions.
- **Owner rules on the iteration-8 shots:** 20 px gutters; header at design y
  (h1 cap 113–138); list/card/CTA edges aligned; CTA surface to the physical
  edge in both themes (`#FFFFFF` / `#1F1C2E` at y 838); no coloured strip.
- **Unchanged / N/A:** 320 px × scale 1.3 matrix, dark token contrast
  (a11y tests), copy locked to the HTML source, Pip rule (no Pip),
  child-order rule (no children), timezone/money (no dates or money on P04).
- **Process note (not a finding):** the worktree still contains another
  stage's untracked, self-declared temporary `zz_probe_test.dart`; it is the
  sole source of the current `flutter analyze` infos. Every P04 feature file
  is analyzer-clean.

## Suite state at hand-off

- `flutter test test/features/privacy_consent/p04_bugs_test.dart` → **17
  passed, 0 skipped, 0 failed**.
- `flutter test test/features/privacy_consent/` → **160 passed, 0 skipped,
  0 failed**.
- `flutter test` (whole app) → **825 passed, 0 skipped, 0 failed**.
- `compare.py` vs `ui/app_light_8.png` → **3.87 %** (bands 1.61 / 6.02 /
  1.91 / 7.77 / 5.46 / 2.60 / 0.40 / 5.12); vs `ui/app_dark_8.png` →
  **3.76 %** (1.58 / 6.29 / 1.87 / 7.72 / 5.42 / 2.88 / 0.39 / 3.91).
- Feature sources: `dart format` clean, `flutter analyze` clean.

## Verdict

Ten findings across the loop, all fixed and pinned; the iteration-7 wrap
regression is cleared and the screen is at its closest match to the design
yet (light 3.87 %, dark 3.76 %), with the trash glyph, themed shield, list
rhythm and owner rules all verified on the fresh shots. The only open item is
the shared typography-tracking remainder, which no longer causes any layout
or wrap deviation on P04. No major bugs remain.

VERDICT: PASS
