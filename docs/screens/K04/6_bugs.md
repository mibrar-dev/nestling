# K04 quest detail — Stage 6 bug hunt (iteration 1)

Scope: `kid_home` · route `/quest-detail` · kid mode. Adversarial pass over
`quest_detail_view.dart`, its states and every route/DB interaction, against
`docs/screens/RULES.md`, the orchestrator rules (including the 14:28 update
in `ORCHESTRATOR_NOTES.md`) and the K03 bug history.
Three bugs found: **two Major** (a DB-driven quest title renders invisible;
the hero tile still uses the pre-batch-5 icon set against the orchestrator
mandate) and **one Minor** (a mismatched route extra silently shows a
different quest). Everything else probed clean.

Proofs live in `app/test/features/kid_home/k04_bugs_test.dart`, skipped by
default (`// skip: K04-BUG-n` comment next to `skip: true`; the test name
carries the id) so the plain suite stays green.

| # | Severity | Status | Area |
|---|---|---|---|
| K04-BUG-1 | **Major** | OPEN | `.kid-title` / `NestBalancedText` + `maxLines: 3` |
| K04-BUG-2 | Minor | OPEN | `_resolveQuest` extra handling |
| K04-BUG-3 | **Major** | OPEN, mandated | hero tile icon glyphs (`_iconFor`) |

Commands:

```
$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:02 +7 ~4: All tests passed!        # skips = the three bug proofs below

$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-1 \
    test/features/kid_home/k04_bugs_test.dart
Expected: a value greater than <50>
  Actual: <0.08544921875>
Expected: a value greater than <100>
  Actual: <0.08544921875>
the quest title must be visible; measured Size(0.1, 102.0)
2 tests failed                      # the bug is real

$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-2 \
    test/features/kid_home/k04_bugs_test.dart
Expected: no matching candidates
  Actual: Found 1 widget with text "Tidy your bedroom"
1 test failed                       # the bug is real

$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-3 \
    test/features/kid_home/k04_bugs_test.dart
Expected: 'assets/icons/ic_quest_bed.svg'
  Actual: 'assets/icons/ic_bed_sit.svg'
1 test failed                       # the bug is real
```

---

## K04-BUG-1 — a quest title that fills all three allowed lines renders **invisible** (Major, OPEN)

**Where:** `app/lib/features/kid_home/presentation/views/quest_detail_view.dart`
(the title, lines ~577–581) — root cause in the shared
`app/lib/core/design_system/components/nest_balanced_text.dart`.

**What happens.** The heading is `NestBalancedText(title, maxLines: 3)`.
`NestBalancedText` first counts lines with `maxLines: 3` applied
(`lineCountFor`), then binary-searches the narrowest width that still lays
out in that many lines. When the title's natural layout needs **3 or more**
lines at the 350 px content width, the probe is capped at 3 and therefore
reports `3 <= 3` at **every** width — including 0.1 px — so the search
collapses. The heading is then rendered inside a `SizedBox(width: 0.1)`:
`TextOverflow.clip` paints nothing and the screen shows an empty ~102 px gap
where the quest title should be. The design CSS has no max-lines
(`.kid-title` is only `text-wrap: balance` + `overflow-wrap: anywhere`), so
the mock never shows this state; P09's quest-name field has no length cap,
so the input is normal product data.

**Measured (bundled Nunito, 390 px wide, `maxWidth` 350, `maxLines: 3`):**

| title | chars | lines at 350 px | balanced width |
|---|---|---|---|
| `Tidy your bedroom` (seed) | 17 | 1 | 257.6 (fine) |
| `Practise your spellings for 20 minutes` | 38 | 2 | 309.2 (fine) |
| `Tidy up the playroom and put all the toys back in the boxes` | 59 | 3 | **0.085 px** |
| `Read your reading book for 20 minutes and write a book review` | 61 | 3 | **0.085 px** |

Widget-level (the 59-char title on the real screen):
`tester.getSize(find.text(title)) == Size(0.1, 102.0)` — the node occupies
three 34 px lines of height but is 0.1 px wide, i.e. invisible.

**Repro.**
1. In P09 create / rename a quest to
   `Tidy up the playroom and put all the toys back in the boxes`, assign Maya.
2. Open that quest's K04 detail (from K03 or deep link
   `/quest-detail` with `extra {'questId': …, 'childId': 'maya'}`).
3. The tile, pill, hint, steps and cheer render; the title is an empty gap
   and the whole lower stack sits ~100 px lower than the design (content
   still scrolls, no overflow error).

**Failing tests.**
- `K04-BUG-1: balancedWidthFor collapses to zero when the text exceeds
  maxLines` (unit, asserts `> 50`; actual `0.085`)
- `K04-BUG-1: a long quest title measures ~0 px on the detail screen`
  (widget, asserts width `> 100`; actual `Size(0.1, 102.0)`)

Run: `flutter test --timeout 120s --run-skipped --plain-name K04-BUG-1
test/features/kid_home/k04_bugs_test.dart`

**Suggested fix (shared component — SHARED_REQUEST territory, not editable
by this screen).** In `NestBalancedText.build`, count the lines with
`maxLines: null`; when that count exceeds the requested `maxLines`, the text
can never balance within the cap — return `_text()` at full width (clip /
ellipsis as configured) instead of the narrowed `SizedBox`. Keep the
balancing behaviour for text that fits within `maxLines`. A regression test
belongs next to the component and in K03 (`kid_home_view_test.dart` has a
same-shaped title path).

**Not a K04-only effect.** Any caller that passes `maxLines` with a
DB/user-driven string is exposed (K04 is the only current caller with a
DB-driven title; K03/P07 headings are static or single-line).

---

## K04-BUG-2 — a route `extra` naming another child silently swaps in a different quest (Minor, OPEN)

**Where:** `_resolveQuest` in
`app/lib/features/kid_home/presentation/views/quest_detail_view.dart`
(lines ~112–129).

**What happens.** Branch 1 only fires when the extra's `childId` equals the
active child (`questId is String && (childId == null || childId ==
state.child?.id)`). Any other extra — including one that names **another
child's quest** — falls through to branch 2 (`q-tidy`), 3 (first to-do) or 4
(first item) and shows a completely different quest. The view's own comment
says the opposite: “An id that no longer resolves is an unknown quest, NOT a
licence to show a different one.” If the requested id is unknown it *does*
go to the missing state (covered by `quest_detail_view_test.dart`); a
mismatched child is the hole.

**Repro.** Active child Maya; push
`/quest-detail` with `extra: {'questId': 'q-bed', 'childId': 'leo'}` (K03
always passes the active child, so this needs a crafted push / deep link).
Expected (defensible): the “Pick a quest” missing state — the screen cannot
show a quest the playing child did not ask for. Actual: `Tidy your bedroom`
(Maya's `q-tidy` fallback) with an enabled **I did it!** button, so one
extra tap would complete a quest that was never requested.

**Failing test.** `K04-BUG-2: an extra naming another child must not show a
different quest` (asserts `Tidy your bedroom` is absent and `Pick a quest`
is present; actual: Tidy renders).
Run: `flutter test --timeout 120s --run-skipped --plain-name K04-BUG-2
test/features/kid_home/k04_bugs_test.dart`

**Severity rationale.** Not reachable through the app's own navigation (K03
always passes the playing child; deep links cannot carry `extra`) — crafted
programmatic pushes only. Minor.

**Suggested fix.** In `_resolveQuest`, when the extra supplies a String
`questId` and it does not resolve for the active child, return `null`
(→ `_QuestMissing`) regardless of whether `childId` matched. Use the
`q-tidy` / first-to-do / first-item fallbacks only when **no** `questId`
was supplied (the `shot.sh` direct-launch path the plan documents).

---

## K04-BUG-3 — the hero tile uses the pre-batch-5 icon set, against a
mandatory orchestrator ruling (Major, OPEN, mandated)

**Where:** `_iconFor` in
`app/lib/features/kid_home/presentation/views/quest_detail_view.dart`
(lines ~79–90).

**Mandate.** `ORCHESTRATOR_NOTES.md` (14:28, QA of `cmp_light_1`):
“The quest hero icon must be the design's glyph. For the 'bed' quest it is
the flat bed (shared `NestIcons.questBed`, added in batch 5 from the P09
HTML), not the current bed-with-figure icon. Map each quest's icon key to
the same design glyphs P09 uses (questBed / questDishes / questHoover /
questBins …).” The stage-5 UI check had ACCEPTed `bedSit` (its deviation
#1, written before this ruling); the ruling now overrides that
disposition.

**What happens.** K04 maps the seed/DB keys to the OLD icon assets:
`bed → bedSit`, `dishwasher → dishwasher`, `hoover → hoover`,
`bins → bin`, `plate → table` — while P09 (the editor that writes these
keys) draws `bed/sofa → questBed`, `dishwasher/plate → questDishes`,
`hoover → questHoover`, `bin/bins/shirt/bag → questBins`, `book → book`,
`paw/leaf → paw` (`quest_editor_view.dart` `_questIcons`, batch 5). The
hero tile is the largest graphic on the screen, so the screen visibly
renders a different illustration from the design and from its editor.

**Repro.** Open any seeded quest on K04 (e.g. `q-tidy` via K03 or a direct
launch): the 120×120 tile draws `assets/icons/ic_bed_sit.svg` instead of
the design's `assets/icons/ic_quest_bed.svg`. Same for `q-dishwasher`,
`q-hoover`, `q-bins`.

**Failing test.** `K04-BUG-3: the hero tile uses the P09 design glyphs`
(loops q-tidy / q-dishwasher / q-hoover / q-bins, asserts the single 64 px
`NestIcon`'s asset; actual: `ic_bed_sit.svg`, expected
`ic_quest_bed.svg`).
Run: `flutter test --timeout 120s --run-skipped --plain-name K04-BUG-3
test/features/kid_home/k04_bugs_test.dart`

**Suggested fix (screen-local, allowed by RULES §1).** Replace `_iconFor`
with the P09 key/alias table: `sofa → questBed`, `bed → questBed`,
`plate → questDishes`, `dishwasher → questDishes`, `hoover → questHoover`,
`bins/shirt/bag/bin → questBins`, `book → book`, `leaf/paw → paw`,
fallback `questCard`. (K03 carries the same stale copy of the mapping in
its own `_iconFor`; its loop should mirror this.)

---

## Checked clean (evidence kept in `k04_bugs_test.dart`, running un-skipped)

- **Back navigation.** Double-tapping either Back (top `NestIconButton` or
  the bottom bar) pops exactly one route and never stacks/under-pops —
  verified from a pushed stack.
- **Deep link, zero children.** `/quest-detail` under `Seed.empty` shows
  “Who's playing?” and Choose reaches `/who-is-playing`; no crash.
- **Restart / Drift persistence.** After completing q-tidy and re-pumping a
  fresh app instance on the same database, the primary button is disabled
  (`enabled=false`, no tap action) — the seeded `to_do` row flipped to
  `done_pending` and stayed flipped.
- **Rapid taps.** Same-frame double tap of “I did it!” dispatches one
  completion and one celebration (existing tests); a staggered second tap
  during a slow write dispatches a second event, but `completeQuest`'s
  transaction is idempotent — one row, one `/quest-complete` push. The
  same-frame “complete + Back” race ends on the celebration with the row
  saved and no exception. Not filed.
- **Money/data edges.** £ amounts never appear on K04 (kid rule); 9999-coin
  quest at 320 px / 1.3× text fits the pill (`+9999`, rect 66…254) with no
  overflow; `+0` coins renders (`Plus 0 coins`); a 30 h-old daily
  completion reads as *to do* again (London period ruling) with the button
  enabled; empty quest list → “Pick a quest”; enum-ish values
  (`pipStage` out of range, unknown icon, unknown pip style) all fall back
  safely (shared helpers); unmapped icon keys still fall back to
  `questCard` — the wrong-glyph mapping itself is K04-BUG-3.
- **Dark mode / owner rules.** Every K04 token pair ≥ 4.5:1 in both themes
  (ink/ink2 on both sky stops, ink on surface, coinInk on coinTint, ink on
  peachTint, onLeaf on leaf); the dark bottom bar surface reaches the
  physical edge under a 34 px home-indicator inset — no meadow/sky strip.
- **Async gaps.** `_complete`'s post-frame latch release and the
  `_GateLockButton` guard are `mounted`-checked; bloc 9.2.1's emitter drops
  emits after close (`if (super.isClosed) return`), so the “write lands
  after the route closed” case cannot throw. Verified in the K03 suite
  pattern and by inspection.

## Out of scope / not findings

- The steps render unticked on arrival while the design PNG shows two
  ticked — the plan's approved deviation (v1 keeps no per-quest step
  storage).
- Simulators were not used; all proofs run in `flutter test`.
- Only `app/test/features/kid_home/k04_bugs_test.dart` and this file were
  written; the screen was not modified.

VERDICT: FAIL
