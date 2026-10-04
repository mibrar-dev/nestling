# K04 quest detail — Stage 6 bug hunt (iteration 4)

Scope: `kid_home` · route `/quest-detail` · kid mode. Fourth adversarial pass
over the iteration-4 build, against `docs/screens/RULES.md`, the orchestrator
rules (including the ICONS rule) and `ORCHESTRATOR_NOTES.md` (14:28, 15:08,
and the new 16:38 iteration-4 rulings).

**Result: no open bugs. Every finding from iterations 1–3 is fixed and
verified; K04-BUG-5 is closed as ACCEPTED by orchestrator ruling and its
proof now pins the accepted state instead of failing. No new bugs found.**

| # | Severity | Status (iter 4) | Area |
|---|---|---|---|
| K04-BUG-1 | was Major | **FIXED iter 2 · verified** | `.kid-title` / `NestBalancedText` + `maxLines` |
| K04-BUG-2 | was Minor | **FIXED iter 2 · verified** | `_resolveQuest` extra handling |
| K04-BUG-3 | was Major (mandated) | **FIXED iter 3 · verified** | hero glyphs via `questIconFor(audience: kid)` |
| K04-BUG-4 | was Minor | **FIXED iter 3 · verified** | over-cap title ellipsis |
| K04-BUG-5 | was Minor | **CLOSED AS ACCEPTED (16:38)** | hero bed glyph stroke width |

`app/test/features/kid_home/k04_bugs_test.dart` now has **15 live tests and
zero skips** — no K04 proof is parked any more. The new ICONS audience
regression test requested by the 16:38 ruling lives in
`quest_detail_view_icon_audience_test.dart` (4 live cases), also green.

Commands (iteration 4):

```
$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:01 +15: All tests passed!          # BUG-5 acceptance pin is live

$ flutter test --timeout 120s \
    test/features/kid_home/quest_detail_view_icon_audience_test.dart
00:01 +4: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:14 +552 ~3: All tests passed!      # the 3 skips are pre-existing, not K04

$ flutter analyze
No issues found! (ran in 3.4s)
```

---

## K04-BUG-5 — closed as ACCEPTED (orchestrator ruling 16:38)

**Ruling.** “K04-BUG-5 (stroke 2 vs 1.8): ORCHESTRATOR DECISION, ACCEPT the
shared kid glyph at 2 (one consistent kid set; invisible at 64 px). Close the
proof as accepted. Do not ship a variant.”

**What the proof now does** (`K04-BUG-5: the hero bed glyph pins the accepted
shared kid stroke`, live, passing): the skipped 1.8 expectation is gone. The
test records the design fact (K04's tile is the corpus's only
`stroke-width="1.8"`), pins the four K04 tile paths, and asserts the shipped
`ic_quest_bed_kid.svg` is the one shared kid glyph at `stroke-width="2"` and
explicitly **not** a mixed 1.8 file. Changing the stroke again would fail the
test and require a new ruling — the acceptance is recorded rather than
silently re-litigated.

## ICONS audience regression guard — verified

`quest_detail_view_icon_audience_test.dart` (added for the 16:38 ruling), 4
cases, all passing:

1. **Every DB-seeded quest renders its kid-audience glyph** — iterates the
   real repository's rows (DATA OVER MOCKS, no hard-coded asset list), asserts
   the on-screen 64 px `NestIcon` equals
   `questIconFor(item.icon, audience: NestAudience.kid)`, and for every
   divergent key also asserts it is **not** the parent asset. Guards the
   premise that the seed actually covers `bed`/`dishwasher`/`book`.
2. **The glyph is column-driven, not id-driven** — two fake quests with the
   same id shape but different `icon` columns must swap the hero glyph.
3. **The hero bed glyph is the K04 tile drawing, on the accepted stroke** —
   the BUG-5 acceptance pin (paths + stroke 2 + parent asset is not the hero).
4. **The kid and parent glyph sets really diverge** — asserts the shared
   table's divergent set (`bed`, `dishwasher`, `book`, `reading`) and that
   `bins`/`hoover`/`plate`/`paw`/`bag` are shared.

I re-ran all four independently; they pass. No weaknesses that could mask a
regression were found: the first case fails if `_iconFor` reverts to the
parent glyph, and the K04-BUG-3 proof remains as the id-level guard.

## Earlier findings — fixed and verified (unchanged this iteration)

- **K04-BUG-1** (was Major): `NestBalancedText` probes natural line counts and
  renders full width above the cap. Unit + widget proofs live.
- **K04-BUG-2** (was Minor): `_resolveQuest` returns null (“Pick a quest”) for
  an explicit `questId` that does not resolve for the playing child. Proof
  live; the delete-mid-view probe still passes.
- **K04-BUG-3** (was Major, mandated): `_iconFor` delegates to the shared
  `questIconFor(key, audience: NestAudience.kid)`. Proof live.
- **K04-BUG-4** (was Minor): the K04 title passes
  `overflow: TextOverflow.ellipsis`. Proof live.

No product code changed in iteration 4, so the iteration-1/2/3 clean probes
still stand.

## Checked clean (running un-skipped)

- **Over-cap titles**: full content width with ellipsis at 390 px and at
  320 px / 1.3× text, no overflow exception.
- **Navigation**: double-tapping either Back pops exactly one route; a
  `Seed.empty` deep link offers the picker; quest deleted mid-view falls to
  “Pick a quest”.
- **Persistence**: a completed quest stays disabled after a fresh app pump on
  the same Drift database.
- **Data edges**: 9999 coins fit the pill at 320/1.3; a 30 h-old daily
  completion reads “to do” again (London period ruling); enum-ish values
  (unknown icon key, out-of-range Pip stage/style) fall back safely.
- **Dark mode / owner rules**: the dark bar surface reaches the physical edge
  under a 34 px inset; every K04 token pair ≥ 4.5:1 in both themes.
- **Async gaps**: completion and gate latches are `mounted`-checked; bloc
  9.2.1 drops emits after close.
- **Hygiene**: no `DateTime.now()`, no `google_fonts`, no stubbed screen
  state left on K04.

## Not findings

- The three remaining suite skips belong to foundation/K03 tests, not K04.
- Completing and pressing Back in the same frame ends on `/quest-complete`
  with the row saved and no exception (celebration wins; acceptable).
- A staggered second tap during a slow write dispatches a second event, but
  `completeQuest`'s transaction is idempotent: one row, one celebration.
- The BUG-5 acceptance conversion landed with the iteration-4 build; this
  stage verified it and updated only this report. The screen was not
  modified. No simulator used.

VERDICT: PASS
