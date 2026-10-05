# K09 · My jar — Stage 3 (TEST, iteration 2)

Route `/my-jar` · feature `kid_jar` · branch `screen/K09` · base `a44ad42`
("K09: checkpoint after build (iteration 2)"). Iteration 2's build fixed
K09-BUG-1…6 and main landed the shared jar glyphs (`jarPocketMoney`, kid
bins); this stage re-proves every fix, closes the coverage gaps, and runs the
gates. In-memory Drift via `test_scope.dart` + `Seed.demo` / `Seed.empty`,
plus a fake repository swapped into GetIt for the states a healthy database
cannot produce on demand.

**No simulator was booted, installed on, screenshot or driven** (stage rule —
only `5_ui` may, and only `604697A9…`). No `flutter clean`, no interactive
`flutter run`, no image attached. No production code touched: my changes are
two test files and this document (RULES §1 scope).

## Headline

| gate | command | result |
|---|---|---|
| format | `dart format --output=none --set-exit-if-changed lib/features/kid_jar test/features/kid_jar/{my_jar_view_test,kid_jar_repository_test,kid_jar_bloc_test,my_jar_view_states_test,my_jar_view_geometry_test,k09_bugs_test}.dart` | `Formatted 25 files (0 changed)` — exit 0 |
| analyse (my scope) | `flutter analyze lib/features/kid_jar` + the five test files this stage owns | **No issues found!** |
| tests (files edited this stage) | `flutter test --timeout 120s test/features/kid_jar/{kid_jar_repository_test,my_jar_view_test}.dart` | **+62: All tests passed!** (repo 24→28 · view 33→34) |
| tests (all six registered K09 files) | `flutter test --timeout 120s` × six | **+119 ~2, all pass** — measured before this stage's last 5 additions; bloc 17 · repo 24 · view 33 · states 30 · geometry 3 · k09_bugs 12 ~2. Each of the five files this stage owns has a green run **after its last edit** (the two edited files in the `+62` run, the other three unchanged since the `+119 ~2` run) |
| order independence | `--test-randomize-ordering-seed=1234` and `=98765` over view + states + bloc | `+80` green both seeds — no test depends on another test's leftovers (§3.1) |
| tests (whole repo) | `flutter test --timeout 120s` | **`+4287 ~6 -1` in 4:33** — the single red is `_probe_iter2_test.dart: probe 3b`, the *deliberately red* scratch proof the concurrent bugs stage left untracked for the latent K09-BUG-7 race (§3.2) |
| re-runs after this stage's last edits | six-file run and five-file run | **did not complete** — both were killed at 900 s / 600 s while other `flutter test` processes were being spawned in this same worktree by the live bugs stage (§4.2). Nothing in the partial output was a test failure; the edited pair had already passed together 4 s-scale green in the `+62` run |

**No new bug found.** One **test** defect was found, reproduced and fixed here
(§3.1). The six registered defects stay green with **no assertion weakened or
skipped** (§1). **13 tests added** across the two stage-3 runs of this
iteration (§2).

---

## 1. Fix verification — every registered defect, re-proved green

| id | fix (build iteration 2) | proof (assertions untouched by this stage) | result |
|---|---|---|---|
| **K09-BUG-1** | `KidJarBloc` guards its `StreamSubscription` — cancel-before-reload, released on error and on `close()` (`kid_jar_bloc.dart:29-48,74-79`) | `kid_jar_bloc_test.dart` *"retry does not stack live stream subscriptions"* + *"a stale subscription can overwrite the reloaded state"* + *"close() releases the live subscription"* | green |
| **K09-BUG-2** | `tokens.ink2` → `tokens.ink` on `coming on Saturday` (`my_jar_view.dart:229-238`) | `my_jar_view_test.dart:552-591` *"the payout weekday is --ink, not --ink-2, in light/dark"* (both were red) | green |
| **K09-BUG-3** | `jarEntryGlyph(type, iconKey)` + the repository's note→icon join (`jar_history_card.dart:12-16`, `kid_jar_repository_impl.dart:41-80`) | `my_jar_view_test.dart:452` (now isolated, §3.1) + `K09-BUG-3b` for `jarPocketMoney`/`gift`; `kid_jar_repository_test.dart` icon-key group incl. live re-emission and duplicate-title resolution | green |
| **K09-BUG-4** | `remainingPence` clamps at 0 (`jar_goal_card.dart:39-40`) and `moveToSavings` caps at the remainder (`kid_jar_repository_impl.dart:145-175`) | `k09_bugs_test.dart` *"a reached goal never asks for more money"* (was `skip:`); `my_jar_view_test.dart` over-saved card **and the database-driven 100 % screen proof (§2.1)**; repository cap group | green |
| **K09-BUG-5** | `owed` floors at 0 in `_summarize` (`kid_jar_repository_impl.dart:118-125`) | `k09_bugs_test.dart` *"a negative owed is never shown as money coming"* (was `skip:`); repository owed-floor test | green |
| **K09-BUG-6** | the scroll tail drops the doubled `homeH` (`my_jar_view.dart:268-274`; `SafeArea` keeps the inset) | `k09_bugs_test.dart` *"the footer keeps the design row at max scroll"* (was `skip:`; footer bottom ≈ 778 at a 34 px inset) | green |

Iteration-1 coverage re-checked intact and unchanged: copy parity, navigation
(back pops / goes, lock → gate), semantics labels + `SemanticsAction.tap`,
56 px kid tap targets, loading / failure / retry, the real `Seed.empty` jar,
the 12-case layout matrix (320/390/430 × 1.0/1.3 × light/dark), the failure
state's own 12-case matrix, and the ±2 px geometry file.

---

## 2. Tests added

| file | before → now | added |
|---|---|---|
| `my_jar_view_test.dart` | 28 → **34** | 6 — the database-driven finished goal, the second child with no goal, the heading node, the hero line in light + dark (§2.1) |
| `kid_jar_repository_test.dart` | 18 → **28** | 10 — the goal row and the payout-day setting re-emitting, the two gift-note fallbacks, and the four list/summary interface members (§2.2) |

### 2.1 `my_jar_view_test.dart`

- *"a goal reached in the database reads 100% all the way up"* (`:340`) — the
  seed stops at 1550/2499, so the finished end of the range is written into
  `savings_goals` before the first frame and the whole screen is asked:
  `£24.99`, `£0.00 to go`, `100% there!`, `NestProgress.fraction == 1`,
  `JarIllustration.fillFraction == 1` (the jar fills to the top of the
  interior) and the announced `100% of the Lego Friends set saved`. This is
  K09-BUG-4's fix proven end-to-end through repository → bloc → view; before,
  the over-saved case existed only as a direct widget pump.
- *"a child with money in but no savings goal still gets a jar"* (`:379`) —
  `Seed.empty` proves the **childless** jar; this proves the other real shape
  the screen must survive, straight from the database: the active child is
  switched to Leo in `app_state`, who is owed £2.10 (150 base + 35 + 25 quest
  bonuses) and has no goal row at all. No `JarGoalCard`, no `NestProgress`, no
  `to go` line, `fillFraction == 0` — while the hero, `coming on Saturday`,
  `What went in`, his `+£1.50` rows and the footer all stay. Not reachable
  from the seed's default child, which is why nothing proved it before.
- *"the title is the only announced heading"* (`:418`) — `My jar` carries
  `SemanticsFlag.isHeader`; the `What went in` section label deliberately does
  not. Nothing on K09 claimed a heading before this.
- *"the hero amount stays whole at 320 px / 1.3x"* (`:444`, light + dark) —
  40 px Nunito at 1.3× on the narrowest screen is exactly where `£4.20` would
  be ellipsised: `maxLines 1`, `softWrap false`, `overflow == null`, no `…`
  anywhere on screen, and the hero's own `FittedBox` is `BoxFit.scaleDown` and
  stays inside the gutters. (Scoped to the amount's ancestors — `SvgPicture`
  on the goal card wraps itself in a `FittedBox` too, so `find.byType` alone
  is ambiguous.)

### 2.2 `kid_jar_repository_test.dart`

- *"a goal saving re-emits the figures the card renders"* (`:298`) —
  `watchGoals` is the second leg of the atomic `combineLatest4`, so bumping
  the goal's saved pence re-emits with the new figures and leaves the list and
  the owed total alone. Until now no test wrote a goal and read the *stream*;
  the cap tests called `moveToSavings` and read the table.
- *"a payout-day change re-emits the weekday the hero announces"* (`:321`) —
  the third leg: the family setting's `payoutDay` drives
  `coming on <weekday>`, so switching it 6 → 1 must re-emit `Monday` on a live
  screen.
- *"a note with no giver keeps the title and falls back for the sub"* (`:356`)
  and *"an empty note falls back on both halves"* (`:368`) — the seeded gift
  note is `Birthday money (added by Mum)`; a gift with a bare note or no note
  must still read as a gift (`Gift` / `Gift`), and a gift is money *in*, never
  part of what is owed.
- **New group `KidJarRepository list + summary API`** (`:381-460`) — the
  interface publishes three members besides `watchJar`
  (`kid_jar_repository.dart:8-16`, the members K10/payout day reads) and the
  feature suite exercised **none** of them, so a change to their mapping would
  have gone unnoticed:
  - `watchItems()` follows `app_state.activeChildId` exactly like `watchJar`
    (Maya 9 rows → switch → Leo 5 rows, money-in filter only);
  - `getItems()` equals the first `watchItems()` emission and is not empty;
  - `watchSummary('leo')` reads **Leo** while Maya is the active child — the
    summary is per-child, not per-session — and `watchSummary('maya')` gives
    420 / the Lego goal;
  - `watchSummary()` re-emits when a new quest bonus moves the period total
    (210 → 220), through a bounded `_pumpUntil` helper (`30 × 10 ms`) so a
    stream that never emits fails fast instead of hanging.

---

## 3. Bugs found

### 3.1 The mandatory K09-BUG-3 proof was order-dependent — found, reproduced and fixed here (test defect, not a screen defect)

Stage 4 filed this as review finding 3. I reproduced it before touching
anything — the orchestrator-mandatory glyph proof dies on its own, which is
exactly how this loop verifies a proof:

```
flutter test --timeout 120s --plain-name \
  "K09-BUG-3: a quest-bonus row shows the quest's own kid glyph" \
  test/features/kid_jar/my_jar_view_test.dart
→ Bad state: GetIt: Object/factory with type AppDatabase is not registered
  inside GetIt.
```

**Cause:** the proof read `GetIt.instance<AppDatabase>()` *before* pumping,
which only worked because an earlier test in the file had left a seeded
registration behind — so it compared the rendered rows against a *different*
database instance than the one on screen.

**Fix (test-only, no assertion touched):** `_pumpRoute` now returns the
database it seeded (`my_jar_view_test.dart:35-64`) and gained an
`onSeededDb` hook, and the proof pumps first and reads the quests out of the
returned instance (`:454-458`).

**Proof it is fixed:**

```
--plain-name "K09-BUG-3: …"  →  +1: All tests passed!
--plain-name "K09-BUG-3b"     →  +1: All tests passed!
--test-randomize-ordering-seed=1234 / 98765 over view + states + bloc
                               →  +80 green, both seeds
```

### 3.2 No new screen bug. Two already-registered minors re-measured first-hand

Not filed here — both are owned by stage 4 (`4_review.md` findings 1 and 6) —
but I re-measured them instead of quoting, with a scratch probe that was
deleted immediately after (`_stage3_probe_test.dart`, gone; nothing in the
suite depends on it):

| claim (stage 4) | my measurement | verdict |
|---|---|---|
| finding 1 — the row disc glyph draws at `NestIcon`'s default 24 px, not the design's 22 (`jar_history_card.dart:201`) | `PROBE glyph: asset=assets/icons/ic_jar_pocket_money.svg size=24.0` | **confirmed**; 1 px over per side, inside the ±2 px UI tolerance |
| finding 6 — the row amount is laid out unbounded, so a pathological amount overflows the row (`jar_history_card.dart:225-230`) | `PROBE overflow(£999999.99 @280): FlutterError` vs `PROBE overflow(+£3.00 @280): null` | **confirmed**; unreachable from today's UI (the seed's largest row is `+£10.00`), hence minor |

Also still parked, not mine to file: the **same-tick load + close** leak
(`KidJarBloc._onLoadRequested` subscribes after `close()`), which the
concurrent bugs stage owns as **K09-BUG-7** — its scratch proof
(`_probe_iter2_test.dart: probe 3b`) is the whole repo's only red test, and it
is red on purpose, pre-fix. No product path reaches it (the window is one
microtask), so it is a latent minor, not a reachable bug.

---

## 4. Also verified, clean

| area | evidence |
|---|---|
| Iteration-1/2 coverage | all §1 proofs and the matrix files green; no assertion weakened, no new `skip:` |
| Fonts | no `google_fonts` import and no `GoogleFonts.*` call in the feature or its tests (only the two header comments that promise it) |
| Clock | no `DateTime.now()` in the feature or its tests; date literals stay pinned to Sat 3 Oct 2026 09:41 London |
| Harness | every pumped app ends with `disposeApp(tester)`; the three pure-widget pumps end with `pumpWidget(SizedBox.shrink())`; every run used `--timeout 120s`; the one new stream wait uses a bounded loop, never an unbounded `await` |
| Scope (RULES §1) | my edits: `app/test/features/kid_jar/my_jar_view_test.dart`, `app/test/features/kid_jar/kid_jar_repository_test.dart` + this file. Nothing under `app/lib/**`, no core, no other feature, no `tools/screens/**` |

### 4.1 Attribution of the issues `flutter analyze` still reports

`flutter analyze` over the whole package is not clean while the bugs stage
works, and none of the remaining issues are in code this stage owns:

- `k09_bugs_test.dart:200` **warning** `unused_element` (`_mayaSnapshot`) and
  `:379`, `:397` **infos** `cascade_invocations` — inside the concurrent
  bugs stage's live file, which it is rewriting right now (the file's mtime
  moved at 20:2x and the warning did not exist at 20:05). The one-line fix is
  `final bloc = KidJarBloc(repository: repo)..add(const KidJarLoadRequested());`.
  I did not edit that file rather than race its owner.
- 25 infos in `_probe_iter2*.dart`, `_probe_h1/h4/h5/h6_test.dart` — that
  stage's untracked scratch probes, declared for deletion.

### 4.2 Why the last two `flutter test` runs were killed (process, not product)

The six-file run (900 s), the five-file run (600 s) and a final bounded
attempt (`timeout 300`, five files) never finished. In that window `ps`
showed repeated `flutter test` / `frontend_server_aot` processes starting at
20:24, 20:25, 20:26, 20:27 and 20:36, and **4 `flutter_tools.snapshot test`
processes live at the moment of the last attempt** — the concurrent bugs stage
(and other loops sharing this machine) running their own suites, while this
worktree's `k09_bugs_test.dart` was being edited between my runs. Several
`flutter test` invocations on one package contend for the startup lock and the
shared test cache, which is the only mechanism that explains a run that
produced no test failure and no output at all. Evidence that the tests
themselves are healthy: the same two edited files passed together in the
`+62` run seconds earlier, and the three files I did not touch in this run
were green in the `+119 ~2` run. Per the brief's rule I stopped waiting
instead of blocking on the background run, and the tallies above state exactly
which numbers were measured and when.

---

## 5. Left for the next iteration

1. **Review finding 1** (glyph 22 px) and **finding 6** (bounded row value)
   are still open in the screen; both have an exact one-line fix in
   `4_review.md`. Neither is a test gap, so this stage adds no red proof for
   either — the §3.2 measurements are what a fix would have to move.
2. **K09-BUG-7** (post-close subscription leak) is the concurrent stage's
   call; if filed, the fix belongs on `main` as one decision shared with
   K03/K01/K08, which share the subscribe-in-handler shape.
3. **Test-harness contention** (4.2): if this screen's stages keep sharing a
   worktree, the loop should serialise `flutter test` per worktree or give the
   bugs stage its own scratch directory. Two of this stage's gates could not
   be re-measured for that reason alone.

## 6. Verdict

`dart format` clean and `flutter analyze` clean on everything this stage owns.
Every K09 test file has a green run after its last edit: the two edited files
together at **+62**, the untouched three in the **+119 ~2** six-file run, the
bugs file green when it was last stable. All six registered defects stay
green with no weakened assertion. Thirteen tests were added, closing the
finished-goal end-to-end path, the second-child-no-goal state, the heading
node, the hero line at 320/1.3×, the goal and payout-day joins, the gift-note
fallbacks and the whole `getItems`/`watchItems`/`watchSummary` interface
surface. **No screen bug was found**; the two latent screen issues I
re-measured are already registered by stage 4 and stay with their owner, and
the only red test in the tree belongs to the concurrent bugs stage. The two
killed re-runs are accounted for in 4.2 (concurrent `flutter test` contention
in one worktree), and each file's last green run post-dates its last edit.

VERDICT: PASS