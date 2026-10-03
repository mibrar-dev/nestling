# P03 Create account — bug hunt (Stage 6, iteration 8)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: the iteration-8 INTEGRATE checkpoint `b09cdfd` (build PASS) on
`screen/P03`. **No screen code was changed by this stage**; no test file
needed a change either, so this report is the only artifact. All standing
rules were applied (`ORCHESTRATOR_NOTES.md`; PIP/status bar/data-over-mocks/
bottom edge/alignment/COPY; CHILD ORDER — N/A; FONTS; LETTER SPACING; CHIP
ROWS — N/A; BALANCED HEADINGS; TRIAL; SIMULATORS). **No simulator was booted,
installed on, screenshotted or driven by this stage** — per the iteration-8
rule, only the UI stage may use one.

## Ledger — nothing open on P03

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…23 | — | iterations 1–7's bugs | **all fixed**; green regression guards |
| P03-BUG-24 | major (mandatory rule) | headline ignored the BALANCED HEADINGS rule | **fixed iteration 8**; proof un-skipped and green |

`SHARED_REQUEST.md` §7 (`NestType.legalCaption` 13/20 token) and §10
(`NestBalancedText` collapse when `maxLines` clips at every offered width)
remain open, both **non-blocking** and orchestrator-owned: §7's override is
pinned by P03-BUG-12, and §10 is unreachable on this screen (see below).

## Verification of the iteration-8 fixes (independent)

**P03-BUG-24 — the headline now uses `NestBalancedText`.** I read the tree
(`create_account_view.dart:98-106`): `Semantics(header: true, child:
NestBalancedText('Create your family account', style: NestType.h1(…),
textAlign: TextAlign.left, maxLines: 3))`, with `_headlineMaxWidth` and its
comment deleted. The proof (`p03_bugs_test.dart`, un-skipped) now also pins
`textAlign == TextAlign.left`, the copy, `maxLines == 3` and the 20dp gutter.

**Real-font matrix probe (my own, with the bundled Inter/Nunito loaded via
`FontLoader`, on the shipped screen):**

| surface | rendered box | lines | overflow/clip |
|---|---|---|---|
| 390 × 1.0 | x 20.0–217.7 | `Create your` / `family account` | none (`exceeded=false`) |
| 320 × 1.0 | x 20.0–217.7 | `Create your` / `family account` | none |
| 430 × 1.0 | x 20.0–384.3 | `Create your family account` (one line) | none |
| 390 × 1.3 | x 20.0–277.0 | `Create your` / `family account` | none |
| 320 × 1.3 | x 20.0–277.0 | `Create your` / `family account` | none |

So the balanced search reproduces the design's break and left gutter at
every supported size and at the clamped 1.3 scale, with no ellipsis or
clipping. The build's arbitration is right: the retired 240dp cap was a
no-op that merely bounded the search — the component narrows to the same
197.68dp "family account" line by itself.

- **`P03-BUG-7`'s bound stays green** — the harness-font balanced box is
  still under 260, so the proof keeps guarding "constrained, not full-bleed".
- **The shared `balanced_text_ellipsis` merge (`d556232`) is a different
  fix** (uncapped headings previously truncated to one ellipsis line); P03
  passes `maxLines: 3`, so its path is unchanged — the component's `clip`
  default only replaces the old ellipsis on this screen, and no overflow is
  reachable (matrix above).
- **§10 is unreachable on P03.** The collapse needs a heading that exceeds
  `maxLines` at *every* offered width; P03's h1 needs two lines at full
  width at every supported size/scale (matrix), so the clamped painter never
  degenerates. `typography_test.dart`'s "the headline is not a per-glyph
  column at text scale 1.3" stays as the regression guard, and §10 records
  the component fix for whoever hits it.

## Checked — no bug found

- **BALANCED HEADINGS / FONTS / LETTER SPACING / TOKENS** — the only balanced
  heading uses the component; no `google_fonts` anywhere in `lib/`/`test/`;
  no local tracking (`typography_test.dart` walks every rendered run); no new
  literal in the migration (the one screen-owned number remains
  `_OrRow._orLabelLineBox = 15.7`).
- **UI-shape rule** — `typography_test.dart` now also pins the visible
  shapes (field outlines, brand pills, rules, CTA pill inside the panel), not
  only text ink; the UI stage owns the fresh capture.
- **Standing hunt list** — kid-mode guard (`/create-account` → gate), back
  and deep links, restart persistence (one owner row, password never
  written), double-tap guard, 320/390/430 × 1.0/1.3 matrix, dark-mode
  contrast, bottom edge (surface to y=844, raster proof) and 20px gutters:
  all green or N/A, unchanged by this iteration.
- **N/A on this static parent-mode form** — 0/1/6 children, long UK names,
  £0.00/£999.99/9999 coins, empty lists, money rounding, timezone/BST,
  CHILD ORDER, PIP, PERIODS, TRIAL (no subscription writes; the demo seed is
  the active subscriber).
- **No probe leftovers** — the iteration-7 `zz_probe8_test.dart` is gone;
  `pixel_probe.dart` is the documented raster helper imported by the tests.

## Observations (not bugs, not blocking)

- **`formError` can be announced twice in principle** (shared live-region
  row + the listener's `SemanticsService.sendAnnouncement`). Carried from
  iteration 6; the live-region half is unobservable in a widget test and the
  fix is a product call (drop `sendAnnouncement`, or scope it to messages
  with no visible row). No proof filed.
- **Filled-state simulator capture** — `ui/filled-{light,dark}.png` exist
  from iteration 6's `filled_shot.sh`; the UI stage should compare those and
  refresh the capture after this headline migration (its remit, and the only
  stage allowed to touch a simulator).

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `394 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **167 passed, 0 failed, 0 skipped**.
- `flutter test` (full) → **1192 passed, 0 failed, 0 skipped**.

## Verdict

No P03-local bug remains: the mandatory BALANCED HEADINGS gap (P03-BUG-24)
is fixed and independently verified with the design fonts across the full
supported matrix, and every earlier proof on the screen is green with no
skips. The only open items are the two non-blocking shared requests (§7 the
13/20 legal-caption token, §10 the component's maxLines-clamp collapse,
which this screen cannot reach) plus the one a11y observation above.

VERDICT: PASS
