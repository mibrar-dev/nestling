# Fix list after iteration 2

## From 5_ui.md
# P02 Value tour — Stage 5 UI check (iteration 2)

Route `/value-tour`, seed `fresh`, mode `parent`, child `maya`, simulator
604697A9-11DA-462F-9837-396E9CA2493A (390×844). No `ORCHESTRATOR_NOTES.md`
exists; orchestrator stage-prompt rules apply (Pip = `PipAvatar` mochi/sunny,
status-bar differences ignored, data-over-mocks, bottom-edge owner rule).

Provenance: `ui/app_light_2.png` / `app_dark_2.png` were captured earlier in
this iteration (08:35/08:37) after the last screen-code edit (08:31) and were
verified current; `compare.py` was re-run by this stage below.
Compares: `cmp_light_2.png`, `cmp_dark_2.png`.

## Mean diff

- Light: **4.05%** (bands: 0: 2.01, 1: 5.48, 2: 5.26, 3: 6.61, 4: 0.87,
  5: 3.94, 6: 4.39, 7: 3.80). Was 6.50% in iteration 1.
- Dark: **3.85%** (bands: 0: 1.90, 1: 5.36, 2: 5.31, 3: 6.05, 4: 0.81,
  5: 4.09, 6: 4.68, 7: 2.58). Dark token colours sampled identical to
  design. All layout findings apply to both themes.

## Fixed since iteration 1 (verified)

Card geometry now exact (top y=107, pitch 50 px, dots y=534–540, title
y=584–604, button y=742–792 — all identical counts/positions); rows 2–4
titles render in full; tour nav is the spec 60 px; Next button, dots,
progress 4/6, chips, icons/tints, dashed row, CTA padding all match.

## Accepted overrides (not deviations)

- Chip `Sat 3 Oct` vs PNG `Sat 4 Oct`: database wins (4 Oct 2026 is a
  Sunday; seed anchored to Sat 3 Oct 2026 — P02-BUG-5). Correct as shown.
- Row subtitles (`Maya · daily`, `Maya · weekly`, …) vs PNG assignees:
  seeded quest rows win (P02-BUG-4). Correct as shown.
- Bottom edge is bar-surface colour to the physical edge (PNG shows paper;
  owner bottom-edge rule overrides). Correct as shown.
- Status-bar glyphs/time differ (OS-drawn; ignored per rule).

## Deviations (logical px, design ÷ 3)

1. Row-1 title still ellipsised (MAJOR — the one designer-reject left).
   Element: card-1 row 1. Design value: `Empty the dishwasher` in full
   (ends x=240, 14 px clear of the pill at x=254). App value:
   `Empty the dishwas…` (ellipsis, ends x=234). Measured geometry is
   otherwise identical on both sides — pill x=254–312 (w 58), tile x=36–71
   (w 35) — so the text slot is the same 174 px; Flutter's Inter 600
   renders this longest title ~2 px wider than the browser and trips the
   ellipsis. Rows 2–4 fit with a few px to spare. Fix: reclaim a few px on
   this row without touching shared code or spec type (e.g. verify
   `NestCoinPill.small` internals — gap/padding — against design-small and
   tighten if any slack; otherwise shrink nothing and seek designer /
   orchestrator sign-off, since no token-compliant lever remains).

2. Body block sits ~4 px high (MINOR). Element: step-1 body. Design value:
   lines y≈634–644 + 662–668, left x=22. App value: y≈630–640 + 658–664,
   same left edge, same 2-line wrap. Fix: nudge the title→body gap so the
   block lands on the design rows; not a reject on its own.

3. Body punctuation unchanged (MINOR, needs ruling, not a builder defect).
   Element: step-1 body copy. Design PNG: curly quotes + em dash
   (`…“Put the bins out” — or…`). App: straight quotes, no dash, which
   matches DESIGN_SPEC §5 P02 and the repo strings verbatim. Fix:
   orchestrator to rule PNG vs spec-doc; builder then follows.

## Coverage gap (not a failure)

Steps 2–3 (Pip nest / jar cards, `Continue`) are still only peek-visible;
widget tests cover their content (Stage 6: 4 `PipAvatar`s mochi/sunny
[3,1,2,3], no v1 SVGs). Capture pages 2–3 if the loop wants full proof.


## From 6_bugs.md
# P02 Value tour — adversarial bug hunt (Stage 6, iteration 2)

Route `/value-tour`, feature `onboarding`, parent mode, seed `demo`, test
clock pinned to Sat 3 Oct 2026. `docs/screens/P02/ORCHESTRATOR_NOTES.md` now
exists and is mandatory; it overrides the earlier data-over-mocks reading for
this screen (the tour is a marketing illustration).

Proofs live in `app/test/features/onboarding/p02_bugs_test.dart`: the fixed
iteration-1 bugs stay un-skipped as regressions; the open items are marked
`skip: true` with their bug id so `flutter test` stays green
(`flutter test --run-skipped …` shows all four failing). No screen code was
changed by this stage (tests + `docs/screens/P02/**` only).

| Id | Severity | Status | Failing test / proof |
|---|---|---|---|
| P02-BUG-7 | MAJOR | OPEN | `P02-BUG-7 card-1 titles render in full at the design width` |
| P02-BUG-8 | MAJOR | OPEN | `P02-BUG-8a`, `P02-BUG-8b` |
| P02-BUG-9 | MAJOR | OPEN | `P02-BUG-9 step-1 body and card heads use the design's punctuation` |
| P02-BUG-1..3 | — | FIXED, proofs pass | `P02-BUG-1a/b/c`, `2`, `3a/3b` |
| P02-BUG-6 | — | FIXED, proof passes | `P02-BUG-6` |
| P02-BUG-4/5 | — | VOID | reversed by ORCHESTRATOR_NOTES 1 → replaced by BUG-8 |

---

## P02-BUG-7 — MAJOR — Titles must render in full at the design width (ORCHESTRATOR_NOTES 3)

**Where:** `ValueTourPreviewRow` title (`value_tour_view.dart` card-1 rows),
`maxLines: 1` + `TextOverflow.ellipsis` inside the `.pv-name` slot.

**Repro / evidence**

- `docs/screens/P02/ui/app_light_2.png` and `app_dark_2.png` (device, 390×844):
  row 1 reads **`Empty the dishwas…`**; rows 2–4 are full.
- Pixel measurement of both PNGs (logical px): row-1 title ink runs
  **x 81.3 → 234.3** (ellipsis) while the design runs **x 81.3 → 240.7**
  (full, both themes). The coin pill is the same on both sides
  (app 252.7–313.7, design 253.0–313.7), so the slot ends at x ≈ 245
  (pill 253 − 8dp gap) and the design text needs 159.4 from x 81.3 → only a
  ~4px clearance; Flutter's Inter draws the string wider than the browser's at
  the same 15/600, so the ellipsis trips.
- In the widget-test font every row truncates (intrinsic 244–305 vs the
  154dp slot) — the same defect class is visible even at the design width.
- Notes item 3 also requires: at 320dp + text scale 1.3 the title **wraps
  rather than ellipsises** where the design has room (no widget proof —
  test-font metrics make wrap-vs-scale unobservable; flagged for the UI check).

**Failing test:** `P02-BUG-7 card-1 titles render in full at the design width`
(asserts `RenderParagraph` intrinsic width ≤ its laid-out width for all four
titles; currently 305.0 > 154.0).

**Suggested fix:** honour the notes — match the design's title/badge widths
(the badge must not squeeze the title) so the design's names fit on one line
at 390dp, and make the title font-agnostic (e.g. the `FittedBox(scaleDown)`
pattern already used by `_headChip`); allow wrapping at 320dp × 1.3 instead
of a second ellipsis. Files: `value_tour_preview_row.dart`,
`value_tour_view.dart` (card-width/1.3 path).

## P02-BUG-8 — MAJOR — Card copy must be the design's static data, not the database (ORCHESTRATOR_NOTES 1)

**Where:** `_QuestPreviewCard._rows` subs (`value_tour_view.dart:373-402`) and
`_payoutChipLabel()` used by the card heads.

The iteration-2 build followed the (now superseded) data-over-mocks reading
and rewired the illustration to `Seed.demo` and a derived payout date. The
notes make the design copy mandatory:

| Row title | App now | Required (P02-value-tour.html:72-88) |
|---|---|---|
| Empty the dishwasher | Maya · daily | **Maya · weekly** |
| Put the bins out | Maya · weekly | **Leo · once** |
| Reading – 20 minutes | Maya · daily | Maya · daily ✓ |
| Tidy your bedroom | Maya · daily | **Maya · weekly** |

Chips on cards 1 and 3: app shows the derived next payout Saturday
(`Sat 10 Oct` under the test clock, `Sat 3 Oct` on the Friday device run) —
required: the design's static **`Sat 4 Oct`**. Coin values (15/15/10/15) and
"4 of 6 quests done today" already match the design.

**Failing tests**

- `P02-BUG-8a card-1 rows use the design's static copy`
  (fails: `Maya · daily` vs `Maya · weekly`).
- `P02-BUG-8b both card date chips are the design's 'Sat 4 Oct'`
  (fails: `Sat 10 Oct` vs `Sat 4 Oct`).

**Suggested fix:** restore the design constants (view-local) and the static
`Sat 4 Oct` chip labels; delete `_payoutChipLabel()`/the `Seed`/`london_time`
imports if unused. Update the tests that pinned the seed-derived copy:
`value_tour_view_test.dart:823-824` (`Maya · daily` ×3 / `Maya · weekly` ×1),
`:237` (`Sat 4 Oct` findsNothing) and the chip-helper comments at `:51-53`.
Files: `value_tour_view.dart`, `value_tour_view_test.dart`.

## P02-BUG-9 — MAJOR — Copy typography must match the design character by character (ORCHESTRATOR_NOTES 2)

**Where:** `_ValueTourViewState._steps[0].detail` and the card-head strings.

- Step-1 body: app is
  `Pick from 40+ ready-made jobs like 'Put the bins out' or make your own.`
  Design (`P02-value-tour.html:129`, `&ldquo; &rdquo; &mdash;`) is
  **`Pick from 40+ ready-made jobs like “Put the bins out” — or make your
  own.`** (curly quotes + em dash).
- Card heads: app `Today's quests` / `Pip's nest` / `Maya's jar`; the HTML
  (`&rsquo;`) uses **U+2019**: `Today’s quests`, `Pip’s nest`, `Maya’s jar`.

**Failing test:** `P02-BUG-9 step-1 body and card heads use the design's
punctuation` (body string not found; then the three curly-apostrophe heads).

**Suggested fix:** use the HTML strings verbatim in `_steps` and the card
heads; mirror the body string in `OnboardingRepositoryImpl._steps` (feature
data layer, RULES §1) so the pre-load and loaded copies cannot drift. Update
`value_tour_view_test.dart:44` and the `"Today's quests"` / `"Pip's nest"` /
`"Maya's jar"` finders (`:235, :265, :367, :790, :797, :819, :899, :1164,
:1316, :1368, :1379`). Files: `value_tour_view.dart`,
`onboarding_repository_impl.dart`, `value_tour_view_test.dart`.

---

## Fixed in iteration 2 — re-verified by the un-skipped proofs

- **P02-BUG-1 (pager 400 + copy room):** `PageView` is 400dp (520 at 1.3);
  card exactly x20→330, y107→507 (design); dots box 529–547 (ink 534–540);
  copy viewport 253dp ≥ the 196dp design budget. `P02-BUG-1a/b/c` pass.
- **P02-BUG-2 (38dp rows):** `ValueTourPreviewRow` measures 38.0dp; rows 2–4
  titles render full on device (`P02-BUG-2` passes).
- **P02-BUG-3 (short screens):** pager + copy share one vertical scrollable;
  320×568@1.0 and 375×667@1.3 take-exception clean; the body is reachable by
  scrolling (`scrollUntilVisible` probe) and horizontal paging still works at
  320×568 (page 0→1). `P02-BUG-3a/b` pass.
- **P02-BUG-6 (back):** `PopScope` routes a vetoed system back to `/welcome`
  from the in-flow tour and from a deep link (`P02-BUG-6` passes).
- **Void:** P02-BUG-4 (seed subs) and P02-BUG-5 (derived date) were *filed in
  iteration 1 and "fixed" in iteration 2*, but ORCHESTRATOR_NOTES 1 reverses
  both rulings for this illustration; their proofs were replaced by BUG-8.

## Checked — no new bug (iteration-2 re-run)

- **Short screens / text scale:** 320×568@1.0, 375×667@1.3, 320×844@1.3 all
  free of RenderFlex overflow; layout scrolls; horizontal paging intact.
- **Rapid taps:** no page skip; two taps within 200ms advance one page
  (the in-flight animation is retargeted). Benign.
- **Back / deep links:** in-flow and deep-link back both land `/welcome`
  (PopScope). Post-onboarding deep links are still allowed by the shared
  router; not a P02 defect.
- **Kid guard, dark tokens, money, timezone, async/dispose, a11y labels:**
  unchanged from iteration 1 (all clean); the new preview row uses only
  `context.nest` tokens; the add-row labels are exposed as plain text.
- **Stage 5 residue:** the "body block 4px high" is an ink-level difference —
  the body *box* is exactly design (623–671); the remainder is BUG-9's
  punctuation once the copy is restored.

## Verification (run this stage, `app/`)

- `flutter test test/features/onboarding/p02_bugs_test.dart` —
  **7 passed, 4 skipped, 0 failed**.
- `flutter test --run-skipped …/p02_bugs_test.dart` — the four open proofs
  fail with the expected values (`305.0 > 154.0`; `Maya · daily` vs
  `Maya · weekly`; `Sat 10 Oct` vs `Sat 4 Oct`; curly-quote body missing).
- `flutter test` (full) — **547 passed, 4 skipped**.
- `flutter analyze` — `No issues found!`; `dart format` clean.
- No screen code touched; only `p02_bugs_test.dart` and this file.

