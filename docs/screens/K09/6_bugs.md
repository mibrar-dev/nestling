# K09 · My jar — bug hunt (Stage 6, iteration 2)

Adversarial pass over the **iteration-2 build** (`a44ad42`, +802/−403 over
`532ba70`), which landed the three fixes from iteration 1 plus the
ORCHESTRATOR_NOTES (18:47) glyph work. Every iteration-1 finding was
re-verified against the new code first: **K09-BUG-4, 5 and 6 are genuinely
fixed** and their proofs now run live and green (un-skipped). This pass then
hunted the *new* code for fresh defects and found **four** — `K09-BUG-7`
(parked in iteration 1, still latent), `K09-BUG-8`, `K09-BUG-9`,
`K09-BUG-10`.

**No screen code was changed in this stage.** **No simulator was booted,
installed on, screenshot or driven** — only stage 5 may, and only
`E7D5555E…`. No image was attached or uploaded; the design PNGs were not
needed (every finding below is proven against the seeded database or the
HTML/CSS source).

- New proofs: `app/test/features/kid_jar/k09_bugs_test.dart` — now **17 green,
  6 skipped** (`K09-BUG-7`, `7b`, `8`, `8b`, `9`, `10`). Run them red with:
  `cd app && flutter test --timeout 120s --run-skipped \
  test/features/kid_jar/k09_bugs_test.dart`
- `dart format` clean; `flutter analyze lib/features/kid_jar
  test/features/kid_jar` → **No issues found!** (the two
  `cascade_invocations` infos stage 4 flagged at the old lines 330/348 are
  fixed — the `KidJarBloc(repository: repo)..add(…)` cascades now satisfy
  the lint, so RULES §7's "No issues found" gate holds again).
- Whole feature suite: `flutter test --timeout 120s --concurrency=1
  test/features/kid_jar/` → **129 green, 6 skipped**.
- Scope: only `app/test/features/kid_jar/k09_bugs_test.dart` and this file.
  No `app/lib/**`, no core, no another feature, no `tools/screens/**`. The
  scratch `_probe_*` files left by the concurrent stage-6 pass and by this
  stage were deleted (see *Process items*).
- Numbering continues the registry: stages 3–5 own `K09-BUG-1`…`3`; iteration
  1 of this stage owned `4`…`6` (now fixed); the concurrent iteration-2 probe
  parked `7`; this pass adds `8`, `9`, `10`.

## Iteration-1 bugs, re-verified against the new build — all three fixed

| id | iteration-1 symptom | iteration-2 evidence | status |
|---|---|---|---|
| `K09-BUG-4` | a goal saved past its target still asked for money (`£6.51 to go` at `£31.50` of `£24.99`) | `jar_goal_card.dart:39-40` now clamps `remainingPence` at 0; `kid_jar_repository_impl.dart:141-175` caps the move at the remainder. Proof `K09-BUG-4` **green and un-skipped**; a second clean probe proves the cap lands exactly on 2499 and that a further move on a reached goal writes no row at all | **fixed** |
| `K09-BUG-5` | a negative owed rendered as positive hero money (`£0.80 coming on Saturday` at −80p) | `kid_jar_repository_impl.dart:121-125` floors owed at 0 before the hero sees it. Proof `K09-BUG-5` **green and un-skipped** | **fixed** |
| `K09-BUG-6` | the scroll tail reserved the 34 px home inset twice (footer 744.0 vs the design's 778) | the tail is now `NestSpacing.s8` alone (`my_jar_view.dart:268-274`) with `SafeArea` keeping the inset. Proof `K09-BUG-6` **green and un-skipped** — measures 778 ±2 with a real inset | **fixed** |

The iteration-2 build also implemented all three ORCHESTRATOR_NOTES (18:47)
items (kid quest glyphs via `questIconFor(…, audience: kid)`, the shared
`jarPocketMoney`/`gift` marks, full `--ink` on "coming on Saturday"); stage 5
re-measured all three as fixed. `K09-BUG-1` (stacked subscriptions) and
`K09-BUG-2` (the colour) are likewise green per stage 4.

## Bugs found by this stage

### K09-BUG-8 — `moveToSavings` writes a `savings_move` row even when the goal does not exist, so the money leaves the jar and lands nowhere (Minor, latent — but the K09-BUG-4 fix's blind spot)

**Where:** `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:141-175`
(`moveToSavings`).

**What.** The K09-BUG-4 cap was added to the *right* method but left the
missing-goal branch permissive. With `goal == null` the code sets
`remainder = requested` (line 149-151), so `remainder > 0`, so it takes the
`move` and then **unconditionally inserts the `savings_move` ledger row**
(line 154-166) — while the `savedPence` write is correctly skipped by the
`if (goal != null)` guard (line 167). The result: money is debited from the
jar and credited to nothing.

It is silent, and the DB self-hides it: a `savings_move` row is in neither
`_moneyInTypes` (line 250-254, so it never appears in the K09 list) nor in
`_summarize`'s totals (lines 111-117). Nothing on screen moves, no error is
raised, and `owedPence` is unchanged. A test that reads the ledger sees one
extra orphan row; a test that reads the screen sees nothing at all.

The same lookup resolves the goal by **id alone** (line 142-144), with no
`childId` check — so a goalId belonging to a *different* child is credited
with this child's pence. That is the cross-child half of the same defect and
is proven separately below.

**Repro (the proof):** demo seed; `moveToSavings(childId: 'maya', goalId:
'goal-does-not-exist', amountPence: 500)`.

| | expected | app |
|---|---|---|
| ledger rows | 19 (unchanged) | **20** — a new `savings_move` / 500 row |
| `goal-lego.savedPence` | 1550 | 1550 |
| screen (hero / list) | unchanged | unchanged — the row is invisible by design |

**Latent:** `moveToSavings` has **no caller anywhere in `lib/`** (grep:
declaration + interface only). It is the K10 (`/payout-day`) handover — the
next screen in this feature — so this is a landmine for that screen rather
than a flow the demo reaches, which is why it is minor and not major. Stage 4
flagged `watchItems`' contract change for K10 in the same area; this is the
money-side equivalent.

**Failing tests:** `K09-BUG-8: an unknown goal moves the money nowhere`
(`Expected: empty / Actual: WhereIterable<LedgerEntry>[…]`) and
`K09-BUG-8b: a move cannot credit another child's goal`
(`Expected: <0> / Actual: <500>` — Leo's goal credited with Maya's 500p).

**Suggested fix:** reject before any write, and match the child:
```dart
final goal = await (…).getSingleOrNull();
if (goal == null || goal.childId != childId) return;   // nothing to move into
final remainder = goal.targetPence - goal.savedPence;
if (remainder <= 0) return;
```
(then `move = min(requested, remainder)`, unchanged). One line plus dropping
the `goal == null` ternary.

### K09-BUG-9 — a large history-row amount overflows the card at 320 px × 1.3 (Minor)

**Where:** `app/lib/features/kid_jar/presentation/widgets/jar_history_card.dart:224-230`.

**What.** The amount is a non-flexible `Text` with `softWrap: false` inside a
`Row` whose middle child is `Expanded`. Flutter gives non-flexible `Row`
children **unbounded** main-axis width, so the value never shrinks and the row
paints past the card's inner edge instead of ellipsising. The goal card gets
this right with `Flexible` (three call sites), and so does every other long
value on the screen — this one call site does not.

**Repro (the proof):** a `gift` row of `19999`p at 320 px with a 1.3 text
scale.

| amount | 390 × 1.0 | 320 × 1.0 | **320 × 1.3** |
|---|---|---|---|
| £49.99 | clean | clean | clean |
| £99.99 | clean | clean | clean |
| **£199.99** | clean | clean | **overflow 1.2 px** |
| £499.99 | clean | clean | **overflow 1.2 px** |
| £999.99 | clean | clean | **overflow 1.2 px** |
| £1,234,567.89 | clean | — | **overflow 95 px** |

So the threshold is far lower than stage 4's finding 6 assumed: **~£100–£200
at 320 px with a large accessibility text size**, not "seven digits".
£199.99 is a plausible `PocketMoneyRepository.addMoney` top-up from P12, so
this is reachable — but only on a narrow screen with a 1.3 scale, which is why
it is minor. At the design's 390 × 1.0 nothing up to £1.2 M overflows, so no
screenshot shows it.

**Failing test:** `K09-BUG-9: a large row amount never overflows the card`
(`Expected: null / Actual: FlutterError:<A RenderFlex overflowed by 1.2
pixels on the right.>`).

**Suggested fix:** wrap it exactly as the goal card does —
`Flexible(child: Text(formatJarAmount(entry.amountPence), overflow:
TextOverflow.ellipsis, maxLines: 1, …))`, dropping `softWrap: false`. One
line; no geometry change at the design's own amounts.

### K09-BUG-10 — a money-in row older than the previous week is labelled with the wrong day (Minor)

**Where:** `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:230-233`
(`_relativeDay`).

**What.** The function has exactly two states: `This {weekday}` when
`!date.isBefore(weekStart)` (the current London week), else
`Last {weekday}` using **the row's own weekday**. Applied to unbounded ages
that names a day the row is not on: the demo seed's 20 Sep pocket-money row
(a Sunday), viewed on the pinned Sat 3 Oct, renders **`Last Sunday`** — but the
last Sunday before that Saturday is **27 September**.

**Repro (the proof), measured under the pinned Sat 3 Oct 2026 anchor:**

| row date | actual day | label |
|---|---|---|
| 2026-09-20 (Sun) | Sunday 20 Sep | **`Last Sunday`** → names 27 Sep ✗ |
| 2026-10-06 / 13 / 20 / 27 (Tue) | four *different* Tuesdays | **`This Tuesday`** ✗ |
| 2026-10-22 / 23 / 26 / 27 | future dates | **`This Thursday` / `This Friday` / …** ✗ |

A **future**-dated row is the worse half: `isBefore(weekStart)` is false for
it, so it claims `This {weekday}` for a day that has not happened yet. Only
`watchLedger` guards against that in practice, and it does not (it orders by
`date` desc with no upper bound).

**Severity minor**, and deliberately *not* filed as a copy-parity failure: the
design's own example row is exactly one week old and reads `Last Saturday`
(`K09-jar.html:86`), so the two-state label is the design's — the defect is
applying it to unbounded ages in both directions.

**Failing test:** `K09-BUG-10: an old row never names a day it is not`.

**Suggested fix:** fall back to a dated label once a row is older than the
previous week, and handle the future:
```dart
String _relativeDay(DateTime date, DateTime weekStart) {
  final local = toLondon(date);
  final name = _weekday(local.weekday);
  final now = toLondon(weekStart);
  if (local.isAfter(now)) return formatDay(date, 'Europe/London'); // future
  return local.isBefore(weekStart) && weekStart.difference(local).inDays <= 7
      ? 'Last $name' : formatDay(date, 'Europe/London');
}
```
(`formatDay` is shared, `core/data/london_time.dart`, and already formats the
seed's own `Paid · Sat 26 Sep` notes.)

### K09-BUG-7 — a load dispatched and the bloc closed in the same tick leaks a live subscription (Minor, latent — still open)

Parked in iteration 1 and **re-confirmed, not re-filed**. The K09-BUG-1 fix
made `_onLoadRequested` release the previous subscription first
(`kid_jar_bloc.dart:35-47`), and that first `await previous?.cancel()`
suspends the handler. A `close()` landing inside that window finds `_jarSub`
null, cancels nothing, and the handler then subscribes to `watchJar()` **after
the bloc is closed** — never cancelled, and its first emission calls `add(…)`
on the closed bloc.

**Re-run red:** `Expected: <0> / Actual: <1>` (leaked subscription) and
`Bad state: Cannot add new events after calling close` from inside the stream
callback. Both proofs still reproduce on the iteration-2 build.

**Reachability — this pass settled the open question, and it is *not*
reachable.** Two new clean probes pin it:
- three `KidJarLoadRequested` events in one tick → **exactly one** live
  subscription, zero after `close()` (the guard works; the `concurrent`
  transformer does not stack listeners the way it might appear to);
- a mashed `Try again` on the real failure frame → **one** extra `watchJar()`
  and no net listener growth.

So the only way in is programmatic same-tick teardown (a future caller, or a
test harness), not a gesture. Keeping it **minor**.

**Suggested fix** (two lines, keeps the K09-BUG-1 behaviour):
```dart
await previous?.cancel();
if (isClosed) return;
final sub = _repository.watchJar().listen(…);
if (isClosed) { unawaited(sub.cancel()); return; }
_jarSub = sub;
```

## Recorded, not filed

**The `This`/`Last` week label is stale until the next ledger write.**
`londonWeekStartUtc(appNowUtc())` is evaluated inside the stream's `map`
(`kid_jar_repository_impl.dart:63`), so the label is correct on every
emission but nothing re-emits when only the clock moves. Measured: under the
3 Oct anchor the row reads `This Saturday`; move the anchor to Mon 5 Oct and
the label stays `This Saturday` until a DB write, after which it correctly
reads `Last Saturday` (clean probe `the week label follows the pinned clock,
not wall time`, which prints the state).

Not filed: the production path needs a tablet left open across Monday 00:00,
the label is a subtitle, and it self-heals on the next write — which every
payout and quest bonus produces. Worth knowing, not worth a bug id.

## Verified clean this stage (new probes)

| Category | Probe | Result |
|---|---|---|
| rapid double tap | back tapped twice in one frame, then again across frames | idempotent; after the first tap the jar's back button is gone (`findsNothing`), so a real double tap cannot navigate twice |
| rapid double tap | lock tapped twice in one frame | exactly one `/parental-gate` push; one pop returns to `/my-jar` |
| rapid double tap | **`Try again` mashed twice on the real failure frame** | one extra `watchJar()`, no listener growth — closes K09-BUG-7's reachability question |
| money move | `moveToSavings` for a huge amount | stops **exactly** at the target (2499); a further move on a reached goal writes **no** row |
| deep link | `/my-jar` as the app's initial route | renders; back falls through `canPop() == false` to `go('/kid-home')` |
| data edge | seeded ledger inspected: 13 Maya rows, no duplicate timestamps, owed 420 = 300 + 12 + 40 + 40 + 28 with the 26 Sep payout correctly breaking the period | the `break`-on-`payout` period logic is right (DATA OVER MOCKS) |
| money rounding | `jarPounds` 0…300,000p + thresholds | 0 mismatches (integer pence, no float drift) |
| data edge | `£49.99`…`£999.99` row amounts at 390 × 1.0 and 320 × 1.0 | clean at every size — BUG-9 is the 320 × 1.3 corner only |
| timezone / BST | London week boundary either side of the 25 Oct 2026 fall-back | `This Monday` / `Last Sunday` correct in BST and GMT |
| persistence | file DB: seed, `moveToSavings(100)`, close, reopen | owed 420, saved 1650, 9 rows intact |
| dark contrast | 11 K09 text pairs × light/dark, WCAG formula | all ≥ 4.5:1 |
| async gap | dispose the screen mid-load, then write to the DB | no emit-after-close, no exception |
| data edge | long UK goal title + £9,999,999.99 at **320 px × 1.3** | no overflow (the goal card's `Flexible` works) |
| mode guard | parent-mode and kid-mode `/my-jar` | parent-mode kid deep link is the accepted K02 convention; kid → parent-only stays router-guarded |
| clock | `_relativeDay` under a moved anchor | reads the pinned clock only, never the wall clock |

Not re-probed because stages 3–5 already own them with evidence: copy
parity, geometry (±1 px in both themes), semantics labels, tap-target sizes,
the loading / failure / retry frames, the empty seed, and the three
orchestrator-mandated glyph/colour fixes.

## Open registry

| id | severity | status |
|---|---|---|
| `K09-BUG-1` | minor | fixed in iteration 2 (retry guard) |
| `K09-BUG-2` | minor | fixed in iteration 2 (`--ink` on "coming on Saturday") |
| `K09-BUG-3` | major | fixed in iteration 2 (kid quest glyphs) — orchestrator-mandated |
| `K09-BUG-4` | major | **fixed in iteration 2** — proof live and green |
| `K09-BUG-5` | minor | **fixed in iteration 2** — proof live and green |
| `K09-BUG-6` | minor | **fixed in iteration 2** — proof live and green |
| `K09-BUG-7` | minor (latent) | **open** — 2 skipped proofs; not gesture-reachable |
| **`K09-BUG-8`** | **minor (latent)** | **open** — `moveToSavings` debits an unknown/foreign goal; 2 skipped proofs |
| **`K09-BUG-9`** | **minor** | **open** — row amount overflows at 320 × 1.3; 1 skipped proof |
| **`K09-BUG-10`** | **minor** | **open** — `Last {weekday}` names the wrong day, and future rows claim `This`; 1 skipped proof |
| `5_ui.md` iteration 2 | — | PASS, no deviation (glyphs, colour, geometry all re-measured) |
| `4_review.md` findings 1–4, 6 | minor | open, unaddressed in this build; finding 1 and 4 are pure refactors, finding 6 **is** K09-BUG-9 |
| `4_review.md` finding 5 / `SHARED_REQUEST.md` | minor | blocked on shared `NestProgress` (`core/design_system`, out of K09's scope) |

## Process items (loop-owned, explicitly NOT findings)

- The concurrent stage-4 review noted two `cascade_invocations` infos in this
  file that would keep `flutter analyze` from saying "No issues found". Fixed
  here (the bloc is now constructed with a cascade), so the RULES §7 gate
  passes: `flutter analyze lib/features/kid_jar test/features/kid_jar` →
  **No issues found!**
- The scratch `_probe_iter2_test.dart`, `_probe_iter2b_test.dart`,
  `_probe_iter2c_test.dart` (from the concurrent iteration-2 probe) and this
  stage's `_probe_h1`/`_probe_h4`/`_probe_h5`/`_probe_h6` are all **deleted**.
  Every surviving claim is now a permanent green or skipped proof in
  `k09_bugs_test.dart` — nothing in this stage's report depends on a scratch
  file.
- Other stage-6 tests are modified in the tree and the branch is behind
  `main`; the loop owns commit and merge order.

## Verdict

**No blocker, no major.** Every iteration-1 finding is fixed and proven live;
the three orchestrator-mandated items from ORCHESTRATOR_NOTES (18:47) landed
and stage 5 re-measured them. This pass found four new defects, all minor:
`K09-BUG-8` (a money-writing guard hole in the very method the iteration-2
fix touched — the one I would fix first, because K10 is the next screen and
it is the first caller of `moveToSavings`), `K09-BUG-9` (a one-line layout
bound), `K09-BUG-10` (an unbounded-age date label) and `K09-BUG-7` (latent,
and this pass proved no gesture reaches it).

None contradicts the design, the architecture, the owner rules or the
Children's Code, and none needs shared code, so the screen is fit to land
with the six skipped proofs as the fix list. The three quickest wins for the
next build are all one-liners: reject the move when the goal is missing or
belongs to another child, wrap the row amount in `Flexible`, and date rows
older than the previous week.

VERDICT: PASS