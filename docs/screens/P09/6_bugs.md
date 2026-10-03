# P09 — stage 6 · FIND BUGS (iteration 3)

Tree: `aaea888` (“P09: checkpoint after build (iteration 3)”, includes the
shared batch-5 merge) + the proofs below. No screen code was changed — the
brief forbids fixing here.

Adversarial area sweep (iteration 3): the eight earlier proofs re-run, then
new probes over the iteration-3 changes (`?idea=` prefill, Save-pill rebuild
scope, subscription `onError`, Due-by semantics, Cancel without a Tooltip) and
the batch-5 integration (`NestToggle` 51×31 + hit slop, U+2212 stepper, exact
quest icons, text-field inset): data edge cases (0 / 1 / 6 children,
emoji-leading and long UK names, £0.00 / £999.99 / 9999 coins), rapid double
taps, back navigation and deep links, Drift restart persistence, the
parent/kid guard, dark-mode contrast, 320 dp × text scale 1.3, async gaps,
Europe/London wall-clock storage and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. The
iteration-3 proofs are `skip: true` (bug id in the group name) so the suite
stays green; run them with `--run-skipped` to see them fail. Every probe in
the “attacks that hold” group runs unskipped.

## Iteration-1/2 findings — all FIXED, proofs unskipped and green

| id | what was wrong | fix | proof |
|---|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | streams `watchCoinValuePencePerCoin()` | runs green |
| BUG-P09-2 | double-tap Save created the quest twice | `_saving` guard + pill disabled while saving | runs green |
| BUG-P09-3 | non-picker icon showed no selected tile | `_questIcons.aliases` covers every seeded key | runs green |
| BUG-P09-4 | out-of-range coins unreachable after a tap | `_coinFloor`/`_coinCeiling` widen to the stored value | runs green |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown assignee falls back to `Anyone` | runs green |
| BUG-P09-6 | out-of-range reward silently clamped on save | Save blocked + live-region `Coins must be 1–100` | runs green (2 tests) |
| BUG-P09-7 | tapping the alias-highlighted tile rewrote the key | an already-selected tile's tap is inert | runs green |
| BUG-P09-8 | emoji-leading nickname threw a UTF-16 paint error | `_initial` takes the first grapheme | runs green (2 tests) |

All ten proofs run unskipped in the file (23 passing tests: 10 proofs +
13 probes). No regression.

## Summary — iteration 3

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-9 | **major** | batch 5 left P09’s two toggle compensations stale: the approval card renders 68 (design 72, due card 680 vs 684) and the track paints 307/618.5 instead of 303/620.5 | `BUG-P09-9 — the approval block misses the design after batch 5` › `the approval card is 72 high and the due card starts at 684` **and** `the toggle track is the design rect 303/620.5/51/31` |
| BUG-P09-10 | minor | the shared 59×44 hit slop is clipped by the 40-high approval Row: the toggle’s effective tap target is ~51×40, so taps 5 px above/below or 2 px right of the track miss | `BUG-P09-10 — the 59x44 hit slop is clipped by the approval Row` › `5 px above…` / `5 px below…` / `2 px right…` |
| BUG-P09-11 | minor | an out-of-range reward has no practical repair: a 9999-coin row needs 9899 `−` taps before Save unblocks | `BUG-P09-11 — an out-of-range reward has no practical repair` › `one step must bring 9999 into the 1..100 range` |
| BUG-P09-12 | **major** | four of the six icon tiles still draw the legacy glyphs (Bed, Dishes, Hoover, Bins); the mandatory 20:09 note says use `questBed/questDishes/questHoover/questBins` | `BUG-P09-12 — four icon tiles still draw the legacy glyphs` › `the six tiles draw the design glyphs in design order` |

BUG-P09-9 and BUG-P09-12 are **independently tracked**: `4_review.md` §2/§3
found them and `ORCHESTRATOR_NOTES.md` 20:09 orders both fixes (delete
`toggleTrackOffset`, switch the picker). The proofs here pin the exact
rects/glyphs so the loop can unskip them with the fix; BUG-P09-10 and
BUG-P09-11 are **not** covered by any existing note.

---

## BUG-P09-9 — major — the approval block misses the design after batch 5

**Where:** `quest_editor_view.dart:969-974` (card bottom padding
`NestSpacing.s3`) and `:996-997`
(`Transform.translate(offset: QuestEditorMetrics.toggleTrackOffset)`) +
`quest_editor_widgets.dart:49` (`toggleTrackOffset = Offset(4, -2)`).

**Why it is wrong:** both lines compensated the *old* `NestToggle` (a 59×44
box with the 51×31 track centred inside it). Batch 5 made the track the
widget’s own layout box and moved the 59×44 area into a non-layouting hit
slop (`nest_toggle.dart:12-16,36-44`), so the compensations now double-count:

* the card’s bottom padding was shaved 16→12 to absorb the old 44-high box;
  with a 31-high track the row is driven by the 40-high text block, so the
  card renders **68** where the design is **72** and everything below it (due
  card 680 vs 684, Delete button) sits 4 px high;
* the `Transform` pushes the track **4 px past the content edge** and **2 px
  up** (307/618.5 vs the design 303/620.5).

Measured at HEAD with the bundled Inter (matches `4_review.md` §2’s probe):

| element | design (PNG ÷3) | app at HEAD | Δ |
|---|---|---|---|
| `.card` approval | 20 / 600 / 350 / **72** | 20 / 600 / 350 / **68** | −4 h |
| `.toggle` track | **303** / **620.5** / 51 / 31 | **307** / **618.5** / 51 / 31 | +4 x, −2 y |
| `.card` due | 20 / **684** / 350 / 88 | 20 / **680** / 350 / 88 | −4 y |

Both deltas are outside the owner’s ±2 px rule, and the geometry tests
(`quest_editor_view_geometry_test.dart`, `quest_editor_view_test.dart`) fail
on them today (they are the three P09 failures in the tree-wide suite).

**Repro:** pump `/quest-editor` with the bundled fonts; measure
`getRect(NestCard).at(1)` → height 68; `getRect(NestToggle)` → 307/618.5.

**Suggested fix (verified by 4_review.md §2):** delete the
`Transform.translate` and restore the card’s bottom padding to
`NestSpacing.s4` (16). With only those two edits the card is
`20/600/350/72` and the track `303/620.5/51/31` exactly; then delete
`QuestEditorMetrics.toggleTrackOffset` and its stale comment, and update the
geometry/view tests to assert the track itself (51×31) instead of the old
59×44 box.

## BUG-P09-10 — minor — the shared hit slop is clipped by the approval Row

**Where:** `NestToggle`’s `_ToggleHitSlop` (`nest_toggle.dart:96-168`, shared,
`minWidth 59 / minHeight 44`) used inside the approval `Row`
(`quest_editor_view.dart:975-1005`).

**Why it is wrong:** the slop’s overhang is clipped by the parent `Row`’s
bounds — Flutter hit testing stops at the first render box whose
`size.contains(position)` fails, and the Row is only 40 high (the 16/22 title
+ 13/18 sub) and ends at the content edge (x 354). The design’s `::before`
area is 59×44 centred on the track (x 299→358, y 614→658) and overflows the
row into the card’s padding, which CSS does not clip. Measured at HEAD:

* taps flip at y 616.5…655.5 only (the Row’s bounds) — **615.5 and 656.5 do
  nothing**, so the effective vertical target is **40**, below the 44 minimum
  (RULES §8 / plan §5 “toggle 44 wrapper”);
* the right overhang is dead too: a tap at x 356 (inside the design hit area
  and, at HEAD, even inside the painted track 307→358) does not flip.

The review’s suggested replacement proof (“a tap 7 px above the track still
flips it”, `4_review.md` finding c) would fail for the same reason: 7 px above
620.5 is 613.5, outside the Row. The review’s claim that the 44 px target
“still reaches 59×44 through the shared hit slop” after its two-line fix is
not correct — after removing the Transform the Row is still 40 high.

**Repro:** pump `/quest-editor` (bundled fonts), tap at `(328.5, 615.5)`,
`(328.5, 656.5)` and `(356, 635.5)`: the toggle stays ON.

**Suggested fix:** give the toggle a ≥44-high layout parent so the slop is not
clipped, while keeping the design geometry — e.g. wrap it in
`SizedBox(height: 44)` with the track aligned 4.5 px from the row top and the
card’s bottom padding 12 (card stays 72, track stays 620.5, target 44), or
raise the row’s min height and re-balance the card padding; the invariant the
proofs pin is card 72 + track 303/620.5 + a 59×44 hit area. A component-side
alternative (hit-test the slop against an unclipped ancestor) is a shared
change for the DS, not a P09 fork.

## BUG-P09-11 — minor — an out-of-range reward has no practical repair

**Where:** `_coinsOutOfRange` + the widened `_coinFloor`/`_coinCeiling`
(`quest_editor_view.dart:366-372, 472-478`) and the one-step stepper
(`:889-899`).

**Why it is wrong:** the BUG-P09-6 fix correctly blocks Save with the
`Coins must be 1–100` caption, and BUG-P09-4 widened the stepper so the stored
value is reachable — but the only repair path is one tap per coin. A 9999-coin
row needs **9899 `−` taps** before Save unblocks; a 0-coin row needs one `+`.
The parent is stuck with a blocked save on a corrupt row and no practical way
out (the brief’s “9999 coins” edge case).

**Repro:** plant `coins: 9999`, open `?id=q-9999` (caption on, Save dead), tap
`decrease` once → `9998`, caption still on, Save still dead.

**Suggested fix:** make the first step jump the boundary — when
`_coins > _maxCoins`, `−` sets `_coins = _maxCoins` (and when
`_coins < _minCoins`, `+` sets `_minCoins`) — so one tap repairs the row and
the caption clears; alternatively show a one-tap `Use 100` action beside the
caption. Keep the displayed-as-stored value until the parent acts.

## BUG-P09-12 — major — four icon tiles still draw the legacy glyphs

**Where:** `_questIcons` (`quest_editor_view.dart:293, 298, 300, 306`):
`NestIcons.bed / dishwasher / hoover / bin`.

**Why it is wrong:** `ORCHESTRATOR_NOTES.md` 17:57 item 1 bans look-alike
substitutions and 20:09 + `docs/screens/_shared/shared_batch5_REPORT.md`
(lines ~87-90, ~209) deliver the exact design paths as
`NestIcons.questBed / questDishes / questHoover / questBins`
(`nest_icon.dart:36-39`, `assets/icons/ic_quest_*.svg`). The picker still
draws the legacy assets (`ic_bed.svg`, `ic_dishwasher.svg`, `ic_hoover.svg`,
`ic_bin.svg`), which is the stage-5 UI check’s blocking deviation (whole-tile
MAE 17.5–20.5 for Dishes/Hoover/Bins; `5_ui.md` deviation 1). Book and Paw
are byte-identical to the design and stay unchanged.

**Repro:** open `/quest-editor`; `QuestIconTile.icon` for the four keys is
`assets/icons/ic_bed.svg` etc., not `assets/icons/ic_quest_*.svg`.

**Suggested fix:** switch the four entries to
`NestIcons.questBed / questDishes / questHoover / questBins` (design order is
already correct) and update the icon pins in
`quest_editor_data_integrity_test.dart:170` in the same commit (the review
flagged that stale pin too).

---

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet row
  and `Keep it` never pop a second route; double-tap **Save** is guarded
  (iteration-1 proof green).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain **and** with
  `?id=`) lands on `/parental-gate`.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** at 320 × 1.3: pills wrap in creation order,
  `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` keeps ≥ 4.5:1.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock `17:00` (`Before tea (5pm)`).
- **A11y actions:** due-sheet rows and the delete-confirm buttons expose
  `SemanticsAction.tap`; `performAction(tap)` moves the real state/DB.
- **`?idea=` prefill** (new in iteration 3) is covered by
  `quest_editor_view_test.dart` (prefill, fresh id on save, unknown-id
  fallback) and passes — no new proof needed here.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:05 +23 ~7: All tests passed!        # 10 fixed proofs + 13 probes
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+23 -7: Some tests failed              # the seven iteration-3 proofs fail as documented
$ flutter test test/features/quests
01:12 +384 ~7 -3: Some tests failed    # only BUG-P09-9's three geometry rects
$ flutter test
02:53 +2598 ~8 -4: Some tests failed   # tree-wide
```

The tree-wide run has four failures, all outside this file: the three P09
geometry/view tests that pin the pre-batch-5 toggle (they fail on BUG-P09-9’s
rects — the review already documented their needed updates), and a core
`family_time_test.dart` `.single` failure (`Bad state: Too many elements`)
that belongs to `test/core/`, not this feature. Neither is a new P09 finding.

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (briefs, UI PNGs, `5_ui.md`, etc.); it was left
untouched.

VERDICT: FAIL
