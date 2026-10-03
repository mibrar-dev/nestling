# P09 — stage 2 · INTEGRATE (iteration 4)

A **FIXES_3** round: 2a (logic) and 2b (UI) split the loop's
`test=FAIL / review=FAIL / ui=FAIL / bugs=FAIL` findings and fixed them in
parallel. Their halves met on the same contract and needed **no** integration
repair from me — but the **whole-app gate is red on one shared core test**
that no screen agent may fix, so this stage is a FAIL on the evidence, not on
the work (§4, §5).

## 1. What 2a handed over (logic half)

One behaviour change at the bloc boundary:

- **`QuestsBloc.saveFailedMessage`** (`'Could not save the quest. Try
  again.'`) — all three editor handlers now emit
  `editorError: _editorError(error)`; an `ArgumentError` (only the coins-range
  guard, unreachable from the clamped editor) maps to the parent-safe copy with
  the technical detail going to `dart:developer log(name: 'quests')`, and every
  other failure (offline, disk full) still surfaces the repository message, so
  the states suite's toast pins stay untouched.
- `quests_repository.dart` doc correction (finding 8): the create/update
  contract now promises `AssertionError` in debug / `ArgumentError` in release
  — the behaviour already did; only the comment lied.
- Docs in this screen's own dir: `SHARED_REQUEST.md` §2/§4/§5/§6 retitled
  `— RESOLVED on main (shared/shared_batch5)`, and the stale
  `FIXES_2.md:77` `NestIcons.basket` pointer corrected.
- Feature scope: 384 pass, `~7` skips (the BUG-P09-6/7/8 proofs 2b then
  un-skipped, plus P12-BUG-05 elsewhere).

## 2. What 2b handed over (UI half)

Every P09-local item from `FIXES_3.md` plus the mandatory 20:09 switch:

- **BUG-P09-9 + review 2** — both stale batch-5 compensations deleted: the
  approval card's bottom padding is back to `NestSpacing.s4` (16) and the
  `Transform.translate(toggleTrackOffset)` is gone (the constant itself is
  deleted; only doc references remain). The card renders 72 again and the
  51×31 track lands on the design rect 303 / 620.5 / 51 / 31.
- **BUG-P09-10** — the toggle is no longer a child of the 40-high approval row:
  the card padding moved into a `Stack` and the toggle is a
  `Positioned(top: 20.5, right: s4)` sibling of the padded row, so every
  ancestor render box is at least as tall as the 59×44 hit slop and taps 5 px
  above/below the track land on it.
- **BUG-P09-11** — the first step in the direction of the valid band jumps to
  the boundary (`−` from 9999 → 100), so repairing a corrupt stored value is
  one tap instead of 9899; Save stays blocked until it is in range.
- **BUG-P09-12 + review 3** — the picker runs on the batch-5 design paths
  `NestIcons.questBed / questDishes / questHoover / questBins` in the design's
  order (Bed, Dishes, Hoover, Book, Bins, Paw), stored `quests.icon` keys
  untouched.
- Seven more proofs un-skipped (BUG-P09-9 ×2, -10 ×3, -11, -12); the
  BUG-P09-4 stepper test rewritten around the new jump brace (the only assertion
  change, forced by BUG-P09-11).
- Feature scope: **394 pass, 0 skipped**.

## 3. Mandatory orchestrator items — done

**20:09** ("Integrator: switch the icon picker to `NestIcons.questBed /
questDishes / questHoover / questBins` (in the design order) and delete the
`toggleTrackOffset` Transform.translate, as in `shared_batch5_REPORT.md`
~87-90 / ~209") — 2b landed both and I verified them in the tree:

- `_questIcons` → `NestIcons.questBed` (line 301), `questDishes` (307),
  `questHoover` (313), `NestIcons.book` (315, byte-identical per the report),
  `questBins` (320), `NestIcons.paw` (322) — the report's mapping, design order;
- `toggleTrackOffset` no longer exists as a constant and no `Transform` wraps
  the toggle; the only remaining mentions are two explanatory doc comments.

`shared/shared_batch5` itself reached this tree in the loop's merge (`3f1b045`,
confirmed by `git merge-base --is-ancestor 9bbf65a HEAD`), so iteration 3's
four follow-ups are closed, not deferred. Batch-5 also closed 17:57 item 2
(`NestTextField` 12 px content padding) — `SHARED_REQUEST.md` §6 records the
measured text x 38.3 vs 37.7.

## 4. FIXES in this stage

**None were needed for the merge.** `dart format .` reported **0 changed**;
the halves met on the untouched bloc surface (`QuestEditorStatus`,
`editorStatus`, `editorError` — 2a added one constant, no shape change), and
2b's test updates were the mechanical ones its own string/harness changes
forced (toggle-rect pins, glyph expectations, the stepper-jump test). I made
**no code edit this stage**; the only files I touched are this doc set and the
SHARED_REQUEST entry below.

## 5. The one failing test — shared, clock-dependent, not P09

```
$ flutter test
01:39 +2608 ~1 -1: Some tests failed.
Failing tests:
  test/core/family_time_test.dart:
    seed + repository zone plumbing › kid_home completions are stamped with the family zone
  Bad state: Too many elements (dart:core List.single) at line 319
```

Everything else is green: `dart format --set-exit-if-changed .` → 0 changed,
`flutter analyze` → **No issues found!**, `flutter test test/features/quests`
→ **394/394**, whole suite **2608 pass, 1 fail, 1 skip** (the skip is P12's
`p12_bugs_test.dart:320`).

**Attribution, measured not guessed.** `Seed.demo()` stamps a `to_do`
completion for `q-plants`/`leo` at `2026-10-03T06:00Z` and `q-plants` repeats
**daily** (`seed.dart`'s `quest()` default). After `Seed.movedToDubai(db)` the
zone is `Asia/Dubai`, and `KidHomeRepositoryImpl.completeQuest` updates the
existing row only while it is still in the current period, else inserts a fresh
one (K03-BUG-4). A temporary probe (run, then deleted) printed:

| now | `countsForCurrentPeriod('daily', 2026-10-03T06:00Z, now, 'Asia/Dubai')` | path | rows for `q-plants` |
|---|---|---|---|
| 2026-10-03 19:00Z (when iterations 1–3 ran) | `true` | update | 1 → `.single` passes |
| 2026-10-03 22:17Z (now = 02:17 on **4 Oct** in Dubai) | `false` | **insert** | 2 → **throws** |

So the test went red when the machine clock crossed **Dubai midnight
(2026-10-03 20:00Z)**; the same trap arms for its London half at London
midnight (23:00Z). Nothing about P09 changed — `git diff main --
app/test/core app/lib/core app/lib/features/kid_home` is **empty**, so `main`
is red in exactly the same way right now, and this branch's own suite passed
the identical test 3 hours earlier. The file is `app/test/core/**`, which RULES
§1 puts off-limits to a screen agent, so I did not touch it; the request with
three one-line fix options is filed as **`SHARED_REQUEST.md` §7 (blocking,
shared, NOT P09)** for the core owner.

## 6. FIXES left open

- **§7 above** — the only red in the repo; needs the core owner (pin `now` in
  the test, assert the newest row, or move the story-day stamp).
- **Review finding 9** — `GetIt.instance` with no graceful degradation; optional,
  2b left it (P10's BUG-P10-8 is the precedent).
- **Review finding 7** — `docs/DESIGN_SPEC.md:168` says 48 px tiles, the design
  is 44; shared `docs/`, orchestrator's pass.

## 7. Verification (tails)

```
$ dart format .
Formatted 495 files (0 changed) in 2.22 seconds.

$ dart format --set-exit-if-changed .   # re-run
Formatted 495 files (0 changed) in 2.20 seconds.   (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.7s)

$ flutter test test/features/quests
00:15 +394: All tests passed!

$ flutter test
01:39 +2608 ~1 -1: Some tests failed.
  test/core/family_time_test.dart: seed + repository zone plumbing ›
    kid_home completions are stamped with the family zone
```

The stage's own rule is "PASS only if analyze is clean **and the full suite
passes**". Analyze is clean and every P09 test passes, but the full suite does
not, for a reason outside this screen's scope and outside RULES §1 — so the
verdict follows the evidence rather than the intent.

No simulator was booted, installed on, screenshotted or driven. `flutter clean`
was never run; no `// ignore:` was added; no test was skipped, weakened or
deleted to reach green; `git status --short -- app/lib/core app/lib/app tools/`
is empty.

## 8. Handover

P09 is code-complete for this iteration and its own suite is green. The loop
should route **`SHARED_REQUEST.md` §7** to the core owner; once that lands (or
the clock/seed makes the test self-consistent again) this tree passes the
whole suite unchanged, and stage 5 can re-take the icon-tile and toggle shots
now that the batch-5 paths and the 72-high approval card are in.

VERDICT: FAIL