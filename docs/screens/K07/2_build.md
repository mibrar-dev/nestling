# K07 · 2 BUILD (integrate, iteration 4) — 2a logic + 2b UI combined

Job: make the two parallel halves compile and pass together. No simulator was
booted (only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`), no
design was redesigned, no shared file touched (RULES §1: `features/pip/**` +
`test/features/pip/**` + this folder only), no `pkill`, no `flutter clean`.

**No integration repair was needed.** 2a shipped **no `lib/` change at all** and
2b's diff is the two `FIXES_3.md` fixes plus their knock-ons, so there was no
contract seam to reconcile. The work below is verification — including checking
both fixes against the design source myself rather than against the builders'
reading of it — plus the loop hygiene the merge could have left behind.

## What landed

### 2a — non-UI layer (`2a_build_logic.md`, iteration 4)

CONTRACT CHANGES: **none**; the public surface is byte-identical to iteration 3
(`PipState` members and `props`, every `PipEvent`, `PipEvolution`,
`PipRepository`/`PipRepositoryImpl`, DI and routes).

- **No `lib/` file changed.** `1_plan.md` §(b) was audited item by item and is
  complete: the two-number `PipEvolution`, `watchEvolution`'s `switchMap` ×
  `combineLatest2`, the `done_pending | approved` all-time count with no clock
  read (the PERIODS ruling correctly does not apply), the two guarded
  subscriptions, and iteration 3's `toLoading(restartingNest:,
  restartingEvolution:)` retry semantics. No `TODO(<ID>)` in the layer.
- **+5 tests in `pip_evolution_repository_test.dart`** — the production
  status-**UPDATE** paths the suite never pinned (it only pinned INSERTs): K05
  re-does a quest by flipping the current period's newest `to_do`/`not_yet` row
  to `done_pending`, and P11 then flips *that row* to `approved` or back to
  `not_yet`. Each is pinned against `Seed.demo()`: re-done ⇒ 4 → 5/5; approving
  ⇒ 4/4 (never double-counted); declining ⇒ 4 → 3/3 (the milestone is derived
  live, never accumulated); declining one of two rows for the same quest keeps it
  a quest done (the two numbers move independently); plus a control showing a
  `to_do → not_yet` change re-emits yet is `==` the first emission, which is what
  lets the Equatable dedupe keep the celebration still.
- Probed the `_switchMap` stale-emission window (three scratch probes: awaited
  switch then write, switch + old-child write in one turn, rapid
  maya → leo → maya) — **no** stale emission, so no code change; touching a
  helper K06's `watchNest()`/`watchItems()` also use would need a failing proof.

### 2b — presentation layer (`2b_build_ui.md`, iteration 4)

- **K07-BUG-6 (MAJOR)** — `pip_evolution_stats.dart`: `IntrinsicHeight` +
  `CrossAxisAlignment.stretch` around the stats `Row`, so the three `.k7-stats`
  cards are one height. `IntrinsicHeight` is required *because* the row lives in
  a `SingleChildScrollView` (a bare `stretch` throws "forces an infinite
  height"), and deliberately **not** a pinned card height, so the cards can
  still grow at large text scales and on 320 px.
- **K07-BUG-7 (minor)** — `pip_evolution_view.dart`: dropped the hero's
  `maxLines: 4` and the sub's `maxLines: 2` + ellipsis. Both caps were *app-only*
  and the sub's ellipsis swallowed the number that explains why Pip grew.
- Both parked proofs un-skipped (`k07_bugs_test.dart`), and the single
  `pip_evolution_copy_test.dart` assertion that pinned the plan's `maxLines == 4`
  now pins `isNull`.
- Layout, copy, a11y actions, tokens and both palettes untouched — correct, this
  iteration's brief was a bug list.

## FIXES

### Done — 1. Both fixes verified against the design source (not against the note)

I re-read `design/html-source/screens/K07-evolution.html` rather than trusting
the builders' reading:

- **K07-BUG-7**: line 24 `.k7-hero { text-align: center; overflow-wrap: anywhere; }`
  and line 25 `.k7-sub { text-align: center; }` — the file contains **no**
  `-webkit-line-clamp`, no `max-height`, no `overflow` on either (the only
  `overflow` is `html, body`, line 6). In the browser both simply grow and
  `.scroll` scrolls, so dropping the caps matches the design. Confirmed.
- **K07-BUG-6**: line 27 `.k7-stats { display: flex; gap: 10px; }` with **no**
  `align-items`, i.e. the CSS default `stretch`, so the three
  `.k7-stats > div` boxes are all the height of the tallest. The shipped
  `IntrinsicHeight` + `stretch` is that same instruction. Confirmed.
- **The ±2 px risk is covered by the existing design-width proof**: the 390 px
  geometry suite (cards 110 wide at x 20/140/260, 84 tall, top 545) is still
  green in `pip_evolution_widget_test.dart`, i.e. at the design width the three
  cards were already one height, so `stretch` moves nothing and `5_ui`'s band
  table should not shift. What changes is only what the UI check never measured
  — 320 px, where the labels wrap (2.40 px spread with the demo seed, 11.67 px
  with a large coin total).

### Done — 2. Cross-half sequencing of the un-skips, and no scratch left behind

2a deliberately left both `skip: true` lines in place rather than half-opening a
proof it could not make green, and left `pip_evolution_copy_test.dart` alone;
2b dropped them in the same commit as the fixes. Verified in the tree: **zero**
actual skips in `test/features/pip` (the two `skip: true` hits in
`k07_bugs_test.dart` are lines 13 and 20 of the file's own convention comment,
and the directory run reports no `~` marker).

2b also reported seeing 2a's untracked scratch probe
`test/features/pip/zz_probe_2a_iter4_test.dart`. It is gone: `git status`
(including untracked) shows nothing under `app/`, and
`dart format --set-exit-if-changed .` over the app reports **0 changed**, so no
other stage's in-flight artefact is being carried into this iteration's commit.

### Done — 3. The mandatory orchestrator items still hold

`ORCHESTRATOR_NOTES.md` has no iteration-4 update, so the standing mandatory
items are the iteration-2 D1/D2/D3 and the iteration-3 D4. All are satisfied and
still proven by the live suite: D1 (DB-truth wrap accepted), D2 (sparkle path
fixed, iteration 2), D3 (bubble tail accepted), D4 (dark sparkles stroked and
filled from `NestColors.light` in both themes, `shouldRepaint` false, proven by
the real-raster dark probe that samples `0x1E1B3A`). `pip_evolution_sparks.dart`
is not in this iteration's diff, and `pip_orchestrator_notes_test.dart` +
`k07_sparkles_bug_test.dart` pass.

### Verified, no change needed

- **Contract**: 2a says none; the tree matches. Both views still switch on their
  own stream (`state.evolutionStatus` / `state.nestStatus`) and
  `pip_evolution_stats.dart` is still fed `evolution.questsFinishedCount`.
- **The plan knock-on**: `pip_evolution_copy_test.dart`'s one assertion now pins
  `maxLines` is `isNull`, with the style and `textAlign == center` assertions
  around it unchanged.
- **Regression guard for the dropped caps**: re-adding a cap would fail
  immediately and visibly — `k07_bugs_test.dart`'s K07-BUG-7 measures real line
  counts at an accessibility text scale (5 hero / 3 sub lines before the fix) and
  `pip_evolution_copy_test.dart` pins `isNull`. So the tests, not this note, are
  what keep the caps out.
- Nothing outside RULES §1 was edited by me; no `analysis_options` change, no
  `google_fonts`, no `DateTime.now()`, no hard-coded colour or size.

### Left

- **`1_plan.md` §(a).3 / §(a).4 re-ratification (orchestrator).** The plan still
  documents `maxLines: 4` (hero) and `maxLines: 2, overflow: ellipsis` (sub),
  which the design does not have, and its §(a).6 diagram line reads
  `Row(spacing: 10) stats` where the shipped tree is
  `IntrinsicHeight > Row(spacing: 10, stretch: true)`. **I did not edit the
  plan**: it is the build stage's contract, and re-ratifying its copy values is
  the orchestrator's call — 2b asked for exactly that. Documentation only; no
  code is blocked, and the tests above pin the shipped behaviour.
- **`evolutionSub(0)`** = "Because you helped 0 times" under "Pip grew into a
  Hatchling!" — the missing zero branch needs a wording ruling
  (`SHARED_REQUEST.md` item 5, no ruling in `ORCHESTRATOR_NOTES.md`). No copy
  invented; `k07_bugs_test.dart`'s `0 and 999999999 coins…` control pins today's
  wording and must move on purpose when it lands.
- **`SHARED_REQUEST.md` §1-§5**, all non-blocking notes for the orchestrator:
  the K07 background deviation (no `KidScope`, no `.meadow`), the screen-scoped
  load event (§2 — the reason `PipLoadRequested` still opens K06's stream on
  K07), the no-entry-point note, the `shot.sh` pre-first-frame save, and the
  off-token `#3D7FF0` sky dot (§4, ruled by D4 to stay on the light sky token).
- **`5_ui`**: re-verify the dark sparkles and the stat-card band (expected
  unmoved at 390 px, per Done 1).
- **No in-app entry point for `/pip-evolution`** — the CTA leaves to `/pip`;
  whether K06 should open K07 on a stage-up is the K06/flow owner's call.
- **`6_bugs.md` observation 3** (`pip_buy_result_test.dart` stalling when the
  whole feature directory runs at once) did **not** reproduce here: the
  directory completed in 10 s. Recorded as unreproduced, not fixed — nobody
  changed it.

## Gates

```
$ dart format .
Formatted 642 files (0 changed) in 1.92 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test --timeout 120s test/features/pip
00:10 +434: All tests passed!      (no `~`: zero skips in the feature)

$ flutter test --timeout 120s
01:40 +4489 ~10: All tests passed!
```

`~10` are the suite's own skips and **none is K07's**: `k01_bugs` (1),
`k03_bugs` (2), `k09_bugs` (6), `p12_bugs` (1).

Files changed by this stage: **none** under `app/` — iteration 4's integration
needed no code change — plus this `docs/screens/K07/2_build.md`.

VERDICT: PASS