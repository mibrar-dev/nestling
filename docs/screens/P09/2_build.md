# P09 — stage 2 · INTEGRATE (iteration 6)

A **FIXES_5** round. 2a made no code edit (every routed item belonged to
another layer); 2b fixed one UI item; and the mandatory
`ORCHESTRATOR_NOTES` 09:27 item — BUG-P09-14 — was blocked for both of them
because `shared/unique_ids` was not on `main` while they worked. The loop's
merge brought it in (`182af0b Merge shared/unique_ids`), so the integrator
completed it here as one coordinated change: mint, the test that pinned the old
id shape, and the parked proof (§3).

## 1. What 2a handed over (logic half)

**No files changed.** The builder's job was to route three items away from its
own layer, which it did with reasoning I checked against the tree:

- **BUG-P09-14** — the mint is the view's line (`quest_editor_view.dart`),
  nothing in `domain/`/`data/`/`bloc/` can mint it (events carry complete
  entities; a repository must not rewrite primary keys), and
  `git grep newId origin/main -- app/lib/core` was empty at the time.
- **P09-TEST-8** (a verbatim non-`ArgumentError` such as `SqliteException`
  could reach the toast) — **no safe change exists without breaking other
  stages' pinned assertions**: mapping everything-unknown to generic copy would
  break `quest_editor_states_test.dart`'s offline/disk-full passthrough pins,
  and mapping one more concrete type is drift-leaking whack-a-mole. Its
  conclusion is also now partly moot: the only *reachable* producer of a raw-SQL
  toast was the id collision, which dies with BUG-P09-14 (§3).
- **CLOCK / KID-BACKGROUND** — its layer has no `DateTime.now()` and no meadow.

Its one reported failure (BUG-P09-10's right-overhang tap) turned out to be
pre-2b's-final-shape; the shipped shape passes it, confirmed by the full suite
below.

## 2. What 2b handed over (UI half)

- **P09-TEST-9 fixed (the switch rode high whenever the text wrapped).** The
  hard-coded `approvalTrackTopInCard = 20.5` — a measurement of one metric, not
  the CSS rule — is deleted. The card's own height now drives the offset
  (`(constraints.maxHeight - approvalTrackHeight) / 2`), so the track is centred
  by layout (`.switchrow { align-items: center }`) at 390/320 × scale 1.0/1.3.
  The design rect is unchanged at 390: track `303 / 620.5 / 51 / 31`, card
  `20 / 600 / 350 / 72` — `(72 − 31) / 2 = 20.5` card-local, inside ±2 px, no
  uniform shift.
- **The hard part, recorded in code comments:** `RenderBox.hitTest`
  bounds-checks *every* ancestor box, so centring the toggle while keeping
  BUG-P09-10's 5 px-above / 5 px-below / 2 px-right hit slop took six attempts
  and a documented table of which shape broke which probe. The shipped shape is
  a loose-slot `Positioned` child of a `Stack` spanning the whole slop
  (`Positioned.fill` + `LayoutBuilder` + `Stack`), with centring moved into the
  offset.
- Four new centring tests in the real-font geometry file; the two hard-coded
  assertions in the widget-test file (`toggle.center.dy == approval.top + 36`,
  `toggle.top == approval.top + 20.5`) replaced by the centring contract, which
  is the stricter property.
- Re-measured every element against the design: all inside ±2 px, gutters 20,
  paper to the physical bottom edge, dark identical, copy unchanged.
- Feature scope for 2b: `+413 ~1` (the single skip was the parked BUG-14).

## 3. FIXES in this stage

**F1 — BUG-P09-14 (mandatory, 09:27): new-quest ids from the clock → `newId`.**
Three coordinated edits, all inside RULES §1:

1. **The mint** (`quest_editor_view.dart`): `'q-${appNowUtc().millisecondsSinceEpoch}'`
   → `newId('q')`, with the `app_clock.dart` import swapped for `ids.dart`.
   The reason is recorded at the call site: a millisecond stamp collides
   whenever two creates land in the same millisecond — *always* under the pinned
   story instant — and the duplicate primary key left the editor open with a raw
   SQL error toast instead of a second quest.
2. **`quest_editor_states_test.dart`** — the CLOCK test asserted the stored id
   *equals* `q-<appNowUtc ms>` exactly, which a uuid breaks by design (2a and
   2b both flagged this as required in the same commit). Rewritten to pin the
   **shape** instead: the id must match `^q-<uuid v4>$`, and both former shapes
   are rejected explicitly so a revert names itself:
   ```dart
   expect(created.id, matches(RegExp(r'^q-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
   expect(created.id, isNot('q-${DateTime.now().millisecondsSinceEpoch}'));
   expect(created.id, isNot('q-${appNowUtc().millisecondsSinceEpoch}'));
   ```
   This is a **strengthening**: the old test could not tell a uuid from a
   timestamp.
3. **`p09_bugs_test.dart`** — the parked proof is un-skipped, retitled
   ("two creates in one session both persist"), and its assertions *added to*
   rather than merely re-run: the second save must not strand the editor
   (`New quest` findsNothing), **no raw SQL text may reach the parent**
   (`find.textContaining('UNIQUE constraint failed')` findsNothing — the 09:27
   note's second sentence), both titles exist, and the two ids are genuinely
   distinct (`created.toSet()` has length 2, not merely both rows present).

**No other FIXES were needed.** `dart format .` reported 0 changed apart from
my own edits, and 2a/2b needed no reconciliation — 2a changed no file, and 2b's
only interface dependency (`approvalTrackHeight`) is its own screen-local
constant.

## 4. Mandatory orchestrator items — all satisfied

- **09:27 BUG-P09-14** — done, all three parts, with the proof un-skipped and
  green (`--plain-name "BUG-P09-14"` → 1/1 pass).
- **09:27 "Raw SQL/exception text must never reach the toast"** — the reachable
  path was the id collision, now dead, and the proof pins the absence of SQL
  text in the UI. A generic taxonomy for *every* unknown failure type remains
  unimplemented on purpose (§1, P09-TEST-8): it would break other stages'
  pinned offline/disk-full assertions and needs orchestrator copy.
- **IDS rule (new this iteration)** — the feature's only id mint now uses
  `newId(prefix)`; `rg 'DateTime\.now\(\)|appNowUtc'` over
  `lib/features/quests/` returns **no** call sites, only the explanatory comment.
- **23:03 `toggleTrackOffset`**, **00:25 P09-TEST-6**, **17:57/19:19 shared
  batch items** — all closed in earlier iterations and re-verified unchanged.
- **CLOCK / KID-BACKGROUND** — satisfied (the clock line is gone from the
  feature now, not merely migrated); P09 is a parent screen, no meadow.
- **`family_time_test`** — still green, fixed upstream.
- The repo's remaining `~2` skips are P12's and K01's; `test/features/quests`
  has **zero**.

## 5. FIXES left open

- **P09-TEST-8** — a parent-safe taxonomy for non-`ArgumentError` failures.
  Deliberately not done (§1): every candidate mapping breaks another stage's
  pinned assertions or whack-a-moles Drift's error types. Needs orchestrator
  copy plus a cross-stage test change.
- **Review finding 9** — `GetIt.instance` without graceful degradation; optional.
- **Review finding 7** — `docs/DESIGN_SPEC.md:168` says 48 px tiles, the design
  is 44; shared `docs/`, orchestrator's pass.
- **Optional DS note (2b)** — a `NestToggle` variant that keeps its track inset
  inside its own 59×44 bounds would remove the whole class of `Positioned`
  compensation from every screen that overlays a switch. Not filed as a
  blocking request; noted for the DS backlog.

## 6. Verification (tails)

```
$ dart format .
Formatted 538 files (1 changed) in 1.57 seconds.     # quest_editor_states_test.dart re-quoted

$ dart format --set-exit-if-changed .   # after every edit
Formatted 538 files (0 changed) in 1.77 seconds.   (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.6s)

$ flutter test test/features/quests/p09_bugs_test.dart --plain-name "BUG-P09-14"
00:01 +1: All tests passed!

$ flutter test test/features/quests
00:14 +414: All tests passed!

$ flutter test
01:20 +3125 ~2: All tests passed!
```

`~2` are the repo's two pre-existing skips, both other features' and neither
introduced here: `test/features/pocket_money/p12_bugs_test.dart:321` and
`test/features/kid_home/k01_bugs_test.dart:566`. `test/features/quests` has
**zero** skipped tests — every BUG-P09-* proof now runs. The
`WARNING (drift): AppDatabase created multiple times` notices are the
repo-wide debug-build notice from `test_scope.dart`, not failures.

No simulator was booted, installed on, screenshotted or driven. `flutter clean`
was never run; no `// ignore:` was added; `analysis_options.yaml` untouched; no
test was skipped, weakened or deleted to reach green;
`git status --short -- app/lib/core app/lib/app tools/` is empty.

## 7. Handover

The gate is green and the screen has no parked proofs left: analyze clean,
3125 tests pass, the IDS rule satisfied at the only id mint, and 2b's
centring fix keeps the design rect at `303 / 620.5 / 51 / 31` with the hit slop
intact at every metric. Stage 5 can re-shoot; stage 3 has 414 P09 tests with
nothing skipped. P09-TEST-8 is the only substantive item left on this screen,
and it is deliberately parked with a written reason rather than half-fixed.

VERDICT: PASS