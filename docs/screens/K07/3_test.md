# K07 · 3 TEST (iteration 3) — the `/pip-evolution` suite

Job: write and extend the K07 tests in `app/test/features/pip/`, run the gates,
and record any real bug the tests expose. **No product code was changed by this
stage** — RULES §1 lets a test stage touch `app/test/features/pip/**` and
`docs/screens/K07/**` only, and `git status app/lib` is empty at the end of it.
No simulator was booted, installed on or driven: only `5_ui` may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`. No `flutter clean`, no
`analysis_options` change, no `google_fonts`, no `DateTime.now()` in any test,
no `pkill` of any kind (the 23:00 rule: other loops share this machine).

Base for this stage: `2_build.md` (what iteration 3 landed),
`2a_build_logic.md` (`toLoading(restartingNest/restartingEvolution)`),
`2b_build_ui.md` (K07-BUG-5 / the D4 palette fix),
`ORCHESTRATOR_NOTES.md` 23:55 (**mandatory**), `6_bugs.md` (iteration 2's hunt)
and this stage's brief.

## Verdict summary

- **Tests added: 4**, in three existing files (one new test each). **Bugs found:
  none.**
- The feature's own directory: **+423, ZERO skips** (419 at the checkpoint +
  my 4). Every bug proof from iterations 1 and 2 is live and green, including
  iteration 2's **K07-BUG-5**, whose `skip` the build dropped.
- Whole app: `+4477 ~10` with **one** failure, and it is not a test result —
  `router_push_test.dart` died on the `libsqlite3.dylib` native-asset race with
  the concurrent stage in this worktree, and passes alone (see **Gates**). The
  only other red in the tree is **another stage's three scratch probe files** in
  `test/features/pip/`, which are not mine.
- **Iteration 3 closed everything iteration 2 left open**: `K07-BUG-5`
  (orchestrator-mandatory D4) and `4_review.md` finding 1
  (`toLoading` dropping both arrival flags). What is left is `5_ui` re-measuring
  the dark sparkles, one orchestrator copy ruling (`evolutionSub(0)`), and the
  non-blocking `SHARED_REQUEST.md` items.

## Files

| file | change | tests |
|---|---|---|
| `pip_evolution_sparks_test.dart` | **+1** — the design's own hexes vs the rasterised canvas, both themes | 9 |
| `pip_evolution_stream_contract_test.dart` | **+2** — a mid-session hiccup is not a failure card; *Try again* re-listens only the dead stream | 16 |
| `pip_evolution_data_test.dart` | **+1** — the zero-count case, measured for the orchestrator | 9 |

## What the new tests prove, and why

Iteration 3 made two product changes — `toLoading(restartingNest/restartingEvolution)`
in the state, and the D4 theme-invariant palette in the sparks painter — and
un-skipped iteration 2's K07-BUG-5 proof. `2a` covered the state machine well
(four new proofs, verified to bite) and `2b` covered the palette well. These four
close the remaining joins; two of them are joins the suite did not have at all.

### 1. The design's hexes vs the pixels — `ORCHESTRATOR_NOTES` 23:55's own words

The 23:55 ruling says: *"Verify each fill hex equals the HTML's literal"*, and
adds *"Add a widget/painter test under dark theme asserting the stroke colour is
`0xFF1E1B3A`"*. `k07_bugs_test.dart`'s K07-BUG-5 does the second half (a dark
raster probed at the design's own `viewBox` coordinates), and
`pip_evolution_sparks_test.dart` compares the canvas with the **palette**. But
nothing compared the canvas with the **design source**: one test read the HTML
and checked the app's transcription constants, another rasterised the app and
checked tokens. A palette token that drifted off its hex, or a new literal
added to the SVG and quietly never painted, would have passed both.

The new test reads the SVG's `<g stroke="#…">` and every `fill="#…"` from
`design/html-source/screens/K07-evolution.html`, asserts that set is exactly
`{1E1B3A, 7C6CF2, 1F9D63, F4B400, FF8A5B}` plus the documented non-token
`3D7FF0` (excluded here, asserted absent by the neighbouring test), and then
requires **every one of them as an exact opaque pixel** in the screen's own
painter — in light **and** dark. The dark run is the point: it must contain
`0xFF1E1B3A` (the design's dark stroke) and, per the test above it, must not
contain the dark theme's ink. Those two assertions are the two sides of
K07-BUG-5, and they now hang on the design's bytes rather than on the app's own
constants.

### 2. The surviving stream, observed from K07's own screen (`4_review.md` finding 1)

The fix makes `toLoading()` explicit about which stream is restarting, and 2a
proved it at the state and bloc level. K07's screen can now be watched too:
with a healthy nest and a failing evolution, the failure card's **Try again**
must re-listen **only** the evolution. A counting fake makes that an observation
rather than an inference — `evolutionCalls == 2` while `nestCalls == 1`. Under
the pre-fix `toLoading()` the tap would have re-listened both (2/2) and dropped
the nest's arrival flag, which is the review's "spinner with no retry
affordance" scenario, latent today only because each route builds a fresh bloc.
The same test pins the card's last-known Pip (the nest's row: Mochi, sunny,
stage 3) and that the route never changed.

### 3. A hiccup is not a failure card (K07's share of the keep-loaded rule)

The evolution stream answers, and *then* errors. `evolutionSettled` stays true,
so `evolutionStatus` stays `loaded`: the celebration must remain on screen — no
`Oh no! Pip got lost.`, no spinner, no raw stream text — and the CTA must still
navigate to `/pip`. This was pinned at the state level only; a child being
thrown out of a celebration by an unrelated hiccup is the kind of defect that
only a widget test would have caught.

### 4. The zero case, measured for the orchestrator (`4_review.md` finding 2)

`evolutionSub(0)` has no zero branch, so a child with **no** counted completions
would read `Because you helped 0 times` under `Pip grew into a Fledgling!`. The
review filed it as a reachable kid-facing string, `2_build.md` filed it as
`SHARED_REQUEST.md` item 5 for a wording ruling, and `2b` pinned today's wording
with a copy-level control.

The new test turns "reachable" into a measurement: Maya's four counting rows are
flipped to `to_do` (a write **before** any pump — this harness deadlocks on a DB
write while the app is pumping, see Observations), the database is then read back
to prove **zero** rows actually count, and the screen is pumped and asserted to
render the celebration with `0` on the card and `Because you helped 0 times` in
the sub. No copy is invented and no ruling is pre-empted: the test pins today's
behaviour so whoever rules on item 5 has a reproducible starting point.

## Coverage against this stage's brief

| required | where it is pinned |
|---|---|
| bloc_test for every event/state path | `pip_evolution_bloc_test.dart` (29: every `PipState` helper, both stream-failure shapes, per-stream statuses, the sibling-slot carry, the `toLoading(restarting*)` reset in both directions, the surviving-stream bloc proof, retry, double-load guard, `close()`, `Seed.demo` end to end) |
| light + dark | every state in the view / widget / a11y / copy / sparks files, plus the new bar, nest-failure and palette tests |
| widths 320 / 390 / 430 | `pip_evolution_widget_test.dart` fit matrix (12 combinations) + the slot tests at 430 and 320 in `pip_evolution_stream_contract_test.dart` |
| text scale 1.0 and 1.3 | the fit matrix + the a11y file's 320 px / 1.3 target check |
| empty / loading / error states | `pip_evolution_view_test.dart` (gated loading, flaky failure, `Seed.empty`, nest-healthy/evolution-failing) and `pip_evolution_stream_contract_test.dart` (both streams failing, gated loading with a failed sibling, mid-session failure) |
| every tap navigates to the right route | CTA → `/pip`, lock → `/parental-gate` (pushed), *Try again* → a real, scoped reload, *Choose* → `/who-is-playing`; each through the **pointer** and through `performAction(SemanticsAction.tap)` |
| semantics labels on icon buttons | `pip_evolution_a11y_test.dart`: the lock speaks the design's `aria-label` `Grown-ups`, the whole semantics tree is swept, no informative node advertises a tap |
| tap targets ≥ 44 parent / ≥ 56 kid | `pip_evolution_a11y_test.dart` uses the **kid** bound (`NestDevice.tapKid` = 56) for lock / CTA / retry / choose, at 390 px and at 320 px with text scale 1.3 |
| in-memory Drift with `Seed.demo` / `Seed.empty` | `setUpTestScope` in every file; the no-child paths re-seed `Seed.empty` |

## Bugs found

**None.** The four new tests are green against the screen as `f4174f9` left it,
and none of them exposed a defect in `app/lib/features/pip/**`. Nothing was
patched — a test stage does not fix screens.

### Iteration 2's open items, now closed and proven by live tests

| id | was | proof, now live |
|---|---|---|
| **K07-BUG-5** (major, `ORCHESTRATOR_NOTES` 23:55 **mandatory**) | in DARK the whole `svg.sparks` layer was stroked and filled from the dark theme's tokens, so every sparkle and dot got a `#F3F0FA` white ring on the night sky | `k07_bugs_test.dart` → *K07-BUG-5* (real app shell at `ThemeMode.dark`, palette sampled off the painter's own raster, dark map == light map) + `pip_evolution_sparks_test.dart` (light palette in both themes, dark ink absent) + the new design-hex test |
| **`4_review.md` finding 1** (minor) | `toLoading()` dropped **both** arrival flags while a retry re-subscribed only the stream that died, so the surviving stream reported `loading` and its screen sat on a spinner with **no retry affordance** | `pip_evolution_bloc_test.dart` (state reset in both directions + two bloc proofs, verified to bite) + the new *Try again re-subscribes ONLY the stream that died* widget test |
| **`4_review.md` finding 3** (minor) | a test header pointed at `pip_evolution_sparks_bug_test.dart`, a file that does not exist | corrected in the build (comment only) |
| K07-BUG-1 … K07-BUG-4 | iteration 1's findings | still live and green (`+423`, zero skips) |

### Still open, and why it is not a test-stage item

- **`5_ui`: re-measure the dark sparkles** (`5_ui.md` **D4**). Everything else on
  the screen is byte-identical to iteration 2's accepted shots, so the band table
  should not move. Only that stage may boot a simulator.
- **`evolutionSub(0)`** — `4_review.md` finding 2 / `SHARED_REQUEST.md` item 5:
  the orchestrator's copy ruling. My new test makes the case reproducible; it does
  not choose the words.
- **`SHARED_REQUEST.md`** items 1-4: the K07 background deviation (no
  `KidScope`, no `.meadow`), the screen-scoped load event (item 2 — why
  `PipLoadRequested` still opens K06's stream on K07), and the non-token
  `#3D7FF0` sky dot (item 4). All non-blocking notes for the orchestrator.
- **No in-app entry point for `/pip-evolution`** (`6_bugs.md` observation 1) — a
  K06/flow-owner decision, not a test-stage one.

## Observations (documented, not findings)

1. **Another stage's scratch probes are what makes the whole-app gate red.** Three
   files appeared in `test/features/pip/` during this stage's run —
   `zz_probe_iter3_k07_test.dart` (01:15), `zz_probe2_iter3_k07_test.dart`
   (01:16) and `zz_probe3_iter3_k07_test.dart` (01:29) — all from a concurrent
   stage, none of them mine (they reference none of this stage's tests). They
   carry all three of the repo's analyze issues, `dart format` wants to reformat
   them, and **two of them fail or hang**:
   ```
   zz_probe2_iter3_k07_test.dart: PROBE A2 card alignment vs distinct-quest count (did not complete)
   zz_probe_iter3_k07_test.dart:  PROBE 4 retry twice then recover
   ```
   They must go before the next gate. Measured without them: the feature's own 26
   files are `+423: All tests passed!`.
2. **My own mistake, recorded because it cost two gate runs.** I ran three
   per-file `flutter test` commands *while* a background whole-app run was in
   flight. That is exactly the condition that makes
   `build/native_assets/macos/libsqlite3.dylib` disappear mid-run, and it
   produced five bogus failures in P09/P13:
   ```
   Invalid argument(s): Couldn't resolve native function 'sqlite3_initialize' …
   dlopen(…/app/build/native_assets/macos/libsqlite3.dylib …): no such file
   ```
   The identical tree, run alone, is green. One `flutter` process per worktree at
   a time — this is now the third time that race has cost a run (iteration 2
   noted the first), so it is worth a line in the loop's own notes.
3. **A zsh trap worth remembering for multi-file runs.** `flutter test $FILES`
   does not word-split an unquoted parameter expansion in zsh, so 26 files arrive
   as one path and the run dies with `Failed to load … Does not exist`. Use
   `ls … | xargs flutter test …` (or `${=FILES}`).
4. **The device-inset detail still matters** (carried from iteration 2): the bar's
   `SafeArea` only sees the 34 px home reserve on a real device and
   `NestHomeIndicator` shrinks outside the gallery, so a test that does not fake
   `view.padding` measures the no-CTA bar as 16 px instead of 50. The comment in
   `pip_evolution_stream_contract_test.dart` records the measurement so the next
   author does not have to rediscover it.
5. **Carried forward (both pinned in the suite, not just noted):** the design's
   inline `#3D7FF0` sparkle dot is not a token (`tokens.css` defines
   `--sky: #2563D6`), so the screen paints `tokens.sky` — now pinned from both
   sides (absent from the canvas, present in the design-source set); and every
   shared control (`NestKidButton`, `NestLockButton`) exposes an extra
   **unlabelled** tap node inside its labelled parent, a design-system
   characteristic measured identically on `/pip` and `/today`, which is why
   `tappableLabels` counts button-flagged nodes only.

## Gates

No simulator; `--timeout 120s` on every run. **The whole-app line excludes the
other stage's three probes** (see Observations 1); with them the run is red.

```
# 1. The feature's own 26 files (probes excluded)
$ ls test/features/pip/*.dart | grep -v zz_probe | \
      xargs flutter test --timeout 120s --reporter compact
00:11 +423: All tests passed!          # zero skips

$ flutter test --timeout 120s test/features/pip/pip_evolution_sparks_test.dart
00:01 +9: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_stream_contract_test.dart
00:01 +16: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_data_test.dart
00:01 +9: All tests passed!

# 2. The whole app (244 files, probes excluded)
$ find test -name "*_test.dart" | grep -v zz_probe | sort | \
      xargs flutter test --timeout 120s --reporter compact
01:46 +4477 ~10 -1: Some tests failed.

#    The ONE failure is the native-asset race again, not a test result:
#    test/app/router_push_test.dart — "push P09 quest editor from /today" died with
#    Couldn't resolve native function 'sqlite3_initialize' … libsqlite3.dylib: no
#    such file. Re-run alone, immediately after:
$ flutter test --timeout 120s test/app/router_push_test.dart
00:02 +7: All tests passed!

#    This time the concurrent process was the OTHER STAGE in this worktree
#    (the one writing zz_probe*_k07_test.dart), which rebuilds
#    build/native_assets while a suite is loading it — the dylib is back now
#    (01:36), which is exactly why the re-run passes.

# 3. Analyze / format
$ flutter analyze | grep '•' | grep -v zz_probe | wc -l
0
$ dart format --output=none --set-exit-if-changed <the three files this stage edited>
(0 changed)
```

The three files this stage owns are clean: `flutter analyze` over each reports
**No issues found!**, and `dart format --output=none --set-exit-if-changed`
changes nothing. The repo's only three analyze issues and its only unformatted
file are the other stage's probes named above.

VERDICT: PASS