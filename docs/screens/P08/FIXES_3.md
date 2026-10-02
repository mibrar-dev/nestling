# Fix list after iteration 3

## From 2_build.md
# P08 · Today (home) — build notes (Stage 2, iteration 3)

Built per `1_plan.md` + every item in `FIXES_2.md` + the stage brief's
PERIODS ruling. The 4 skipped proofs (P08-B11 ×3, P08-B12) are unskipped and
pass; the 2 unskipped regression pins still pass.

## Files changed (all RULES §1-legal)

Lib (`app/lib/features/today/**`):

- `data/today_repository_impl.dart` — **P08-B11**: `_statusOf` now takes the
  `Quest` + a single `now` and applies `countsForCurrentPeriod(repeatRule,
  latest.createdAt, now)` (daily → London day, weekly → London week, once →
  forever); stale completions read `to_do`, and `done`/progress derive from
  the scoped statuses. `rows()` gained an optional `now` (one clock read per
  call so sort and rows agree). New clock seam:
  `TodayRepositoryImpl({required this._db, DateTime Function()? clock})`
  defaulting to `Seed.anchorOverride ?? DateTime.now().toUtc()` — tests pin
  the anchor (story "today"), production uses the wall clock, so demo
  assertions ("4 of 6", banner 3) are date-independent. No DI change needed.
- `presentation/bloc/today_state.dart` — m4: `pendingCount` doc now says
  family-wide DB count, not "items with done_pending".
- `presentation/widgets/today_loaded_body.dart` —
  - **P08-B12**: new `_PushOnce` StatefulWidget (per-push-site `_busy` flag,
    cleared when the pushed page pops) wrapping Review, `+`, quest rows and
    P08b `Add a quest`. `go` destinations need no guard. (A
    `ModalRoute.isCurrent` check would not work: both taps run before the
    Navigator rebuilds.)
  - m10: `sofa` tint arm documented as unreachable-by-construction.
- `today_view.dart` / `today_empty_view.dart` — untouched this iteration.

Tests (`app/test/features/today/**`):

- `p08_bugs_test.dart` — 4 skips removed; all 11 + 4 + 2 green.
- `today_view_test.dart` — m5: the three-children test now also asserts
  Sam's card is ≈170 px wide (measured after scrolling it into view;
  `NestCard.at(2)` only exists once built).
- Expectations updated for the ruling (Leo `done 1` / `1 of 4 quests` —
  see below; scroll loops already follow render order).

## Fix-item ledger (FIXES_2 refs)

- **P08-B11 (major)** — fixed as above. Consequence worth stating: Leo now
  renders **1 of 4 quests** (was "2 of 4"): `q-bag` repeats `daily` and its
  approval is from the previous London day, so per the ruling it is "to do"
  again. The design mock's "2 of 4" predates the ruling; the brief's
  ORCHESTRATOR RULES + PERIODS section explicitly override design PNGs, and
  DATA OVER MOCKS says the DB is right — the expectation (not the code) was
  updated, in P08's tests and filed for the shared contract test
  (`SHARED_REQUEST.md` §8, blocking).
- **P08-B12 (minor)** — fixed as above; proof also asserts one system-back
  returns to `Today's quests`.
- **m4** (pendingCount doc) — fixed. **m5** (grid width assertion) — added.
  **m10** (sofa arm) — commented.
- **m6** ("Happy week: 0 days" for a childless family) — left: P08b header
  copy is that loop's scope. **m8** (liveRegion re-announce) — still
  deferred. **m9** (`happyDays` write-only) — kept as the seam (the ledger
  allows keep-or-drop). **m11** (watcher count) — unchanged, not
  user-visible. **B16/C9** (balance wrap) — accepted platform limit, note
  only. **B21/C11/m7** (P08b) — that loop's scope.
- **M1** (Bolt placeholder under Reduce Motion) — resolved on main
  (`f6b02d8`); the regression pin passes; no filing needed. **M2/M3** —
  process items per the brief ("handled by the loop and the orchestrator"),
  not reported as findings.
- **B11.5** (should the banner be period-scoped?) — kept family-wide so the
  banner ≡ the P11 list; filed as `SHARED_REQUEST.md` §9 for a ruling.

## Verification tails

- `dart format .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app).
- `flutter test test/features/today` → `All tests passed!` (+86).
- `flutter test` (full) → `+458 −1`; the single failure is the **shared**
  `test/core/data/repositories_test.dart` (`leo.done == 2`, pre-ruling
  number) — screen agents may not touch shared files (RULES §1), filed as
  `SHARED_REQUEST.md` §8 (blocking).
- `shot.sh` light + dark + empty from final sources (all newer; all three
  read back). Every run warns `frame never stabilised in 25 s` — shared §6
  (`DISABLE_ANIMATIONS=1` parses to false, Rive idle loop runs); captures
  are complete. Two dark captures in a row showed another screen entirely
  (K03 kid-home, then springboard) — parallel-loop contention on the shared
  simulator; a third run captured the correct screen.
- `compare.py`: light mean **5.20 %**, dark **4.84 %**. Residual is
  data-driven: live date (`Fri 2 Oct` vs mock `Sat 4 Oct`), ruling-driven
  Leo count/repeat labels, all 10 real rows vs the mock's 5, banner
  balance-wrap. Dark: zero theme branches, everything flips.


## From 4_review.md
# P08 · Today (home) — QA code review (Stage 4, **iteration 3**)

Route `/today` (+ `/today-empty`), feature `today`, mode parent, seed `demo`/`empty`.
Reviewed: the working tree, `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P08, `docs/design/SPACING_SPEC.md`, `app/lib/core/design_system/**`,
the design PNGs, `P08-today.html`, `ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`, and the
iteration-1/2 ledgers below. No code was edited.

Per this iteration's rules I did **not** raise uncommitted work, branch staleness or merge
order (the loop owns those); they are noted once at the end and are not findings.

## Verification I ran myself

| Check | Result |
|---|---|
| `flutter test` (full) | **468 passed, 1 failed** — see B1 |
| `flutter analyze` | `No issues found!` |
| `dart format --set-exit-if-changed .` | `350 files (0 changed)` |
| `flutter test test/features/today` | 96 passed, 0 failed, 0 skipped (12 bloc · 20 repo · 47 view · 17 bug proofs) |
| **BOTTOM EDGE** — column x=195 from y=764 to the physical bottom edge (844) | light `rgb(255,255,255)` and dark `rgb(31,28,46)` **continuously to the edge**; only the home pill itself differs. No strip, no tint, in either theme ✓ |
| **ALIGNMENT** — horizontal extents | banner, kid cards, quest cards all span **x 20.00 → 369.67** in light *and* dark ✓ (the "27.33→362.33" row is the rounded-corner tail below the kid cards, not an element) |
| **PERIODS** — demo recomputed by hand against the seed | Maya 4/6 ✓, Leo 1/4 ✓ (q-bag is `daily`, approved `utc(10,2,7,30)` = yesterday → out of period; q-bed pending today → counts; q-bins/q-hoover are `weekly`, same London week → count) — matches both PNGs |
| Quest-row gap vs design | 21.33 vs design 21.33, card height 68.67 vs 68.67 (unchanged, still exact) |
| Screenshot freshness | light 03:21, empty 03:23, dark 03:31 — all newer than the 03:13 source |
| Dark capture identity | I opened `today-dark.png` myself: it is the P08 screen (greeting, banner, 2-up cards, `MAYA · 9`, tab bar) — **not** the K03/springboard frames `2_build.md` reports from the contended-simulator run |
| v1 `pip_stage_*.svg` in the feature | none ✓ |
| `git diff main...HEAD` scope | only `features/today/**`, `test/features/today/**`, `docs/screens/P08/**` ✓ |

## Mandatory-rule status

| Rule | Result |
|---|---|
| PERIODS (`countsForCurrentPeriod`) | **implemented and correct in the rows** — `today_repository_impl.dart:186-192`, injected clock at `:140`; boundary tests include "23:30 London yesterday does not count", "weekly Monday 00:30 London counts", and the BST→GMT switch. One gap: the banner count (B2) |
| BOTTOM EDGE | **pass** in both themes |
| ALIGNMENT | **pass** — every element on the 20px gutter, same edges, both themes |
| ORCH notes 1–4 | 1 ✓ per-child `PipAvatar` (verified in both PNGs and by `[P08-B02]`), 2 ✓, 3 ✓, 4 ✓ |
| Data over mocks | ✓ Leo's 1/4 is the seeded value, not hard-coded |

## Ledger

**Iteration 2 — closed.** M1 (Reduce-Motion placeholder) is genuinely fixed *and* the
cause is gone: `assets/illustrations/pip_v2/{bolt,storybook}/s1..s4_idle_1.svg` now ship
and `PipAvatar.fallbackAsset` was generalised to
`'.../${style.dir}/s${stage}_idle_1.svg'` (the mochi special-case and the
`placeholder.svg` files are gone; the bolt SVG is real art — `aria-label="Pip v2 B Bolt ·
hatchling · idle 1"`). So Leo's still frame is now correct, and my "§6 and this must land
together" coupling note is resolved — freezing the flag will no longer degrade P08's
screenshots. Also closed: m4 (`pendingCount` doc), m10 (`sofa` comment).

**Carried minors from iteration 2** (re-raised by number below, all still open):
m5 3-child geometry, m6 `Happy week: 0 days`, m7 P08b inset, m8 `liveRegion`, m9
`happyDays` write-only, m11 watcher count.

---

## Findings

### B1 — blocker (external, already escalated) — `flutter test` is red on a shared test the ruling invalidated

`app/test/core/data/repositories_test.dart:53` — `expect(leo.done, 2)` in
`'today Maya 4 of 6, Leo 2 of 4'`.

The mandatory periods ruling makes the seed's pre-ruling number wrong: `q-bag` ("Pack
school bag") repeats **daily** (`seed.dart:240`, no explicit repeat) and its approval is
stamped `utc(10, 2, 7, 30)` — the previous London day — so it no longer counts and Leo
renders **1 of 4**. The shared test still asserts the old number. P08's own
`today_repository_test.dart:228` asserts `leo.done == 1` and is green, so the two suites
now disagree by design.

This is **not P08's code** — RULES §1 forbids the screen agent from touching
`app/test/core/**`, and it is correctly filed as `SHARED_REQUEST.md` §8 (blocking). I am
reporting it as a blocker because RULES §7.1 requires a green `flutter test` before the
screen is done, and one red test blocks the landing regardless of who can fix it.

**Fix (orchestrator, one line):** `app/test/core/data/repositories_test.dart:53` →
`expect(leo.done, 1);` and rename the test to `'today Maya 4 of 6, Leo 1 of 4'`. Do **not**
"fix" it by re-stamping `q-bag`'s approval onto the anchor day: a daily quest approved
yesterday showing as done today is exactly what the ruling forbids. (Alternatively, if the
mock's "2 of 4" is what the product wants, the *seed* needs a weekly `q-bag` — also a
shared change, and a decision for the orchestrator, not the screen.)

### B2 — major — the approvals banner count is not period-scoped while the rows are

`app/lib/features/today/data/today_repository_impl.dart:118-126` (`watchPendingCount`)
counts **every** family-wide `done_pending` completion:

```dart
return (_db.select(_db.questCompletions)..where(
      (c) => c.familyId.equals(Seed.familyId) & c.status.equals('done_pending'),
    )).watch().map((rows) => rows.length);
```

no `countsForCurrentPeriod` filter, while every quest row at `:186-192` is period-scoped.
The demo happens to be self-consistent (all three seeded pendings are from the anchor day,
so banner 3 ↔ three "Needs a look" rows ✓), which is why no test catches it. It stops
being consistent on the first day rollover:

- A child does a **daily** quest, the parent does not approve, and the next day arrives.
  The row correctly resets to "to do" (period expired) but the banner still counts the
  stale completion — so the screen contradicts itself: *"3 quests waiting for your
  thumbs-up"* above a list with two "Needs a look" rows. Same for weekly quests at a week
  boundary.
- Worse, it is a **money** bug, not just a copy one: the stale `done_pending` still reaches
  P11's approval list, so the parent can approve and pay (P13 payout pays per approved
  completion) for a quest the child is now free to do — and complete — again today. The
  child is paid twice for the same chore.

`2_build.md` flagged rather than guessed, which was the right call, and filed it as
`SHARED_REQUEST.md` §9 for a ruling. My review is that the ruling should go the other way
from the current behaviour — the count is a *quest status* count, and the ruling says a
quest's status counts only for its current period.

**Fix (P08-local, RULES-legal):** scope the count the same way the rows are scoped — join
completions to their quest and keep only current-period ones:

```dart
Stream<int> watchPendingCount() {
  return combineLatest2(
    _db.watchAllCompletions(Seed.familyId),
    _db.watchActiveQuests(Seed.familyId),
  ).map((parts) {
    final rule = {
      for (final q in parts[1] as List<Quest>) q.id: q.repeatRule,
    };
    final now = _clock();
    return (parts[0] as List<QuestCompletion>)
        .where((c) =>
            c.status == 'done_pending' &&
            countsForCurrentPeriod(rule[c.questId] ?? 'once', c.createdAt, now))
        .length;
  });
}
```

and add a test: insert a `done_pending` completion dated before the London day start for a
`daily` quest, then assert the banner disappears while the row reads "To do". **Coordinate
with the P11 loop** — if P11 keeps listing the stale row, the two screens will disagree, so
the ruling needs to land on both (add that to §9 rather than fixing P08 unilaterally).

### B3 — minor — statuses are never re-evaluated when the period rolls over while the app is open

`watchItems()` re-emits only when the quests/completions/children tables change, and
`rows()` resolves `at = now ?? _clock()` at emission time (`:140`). Nothing re-runs the
query when the clock crosses midnight or Monday 00:00 London, so a parent who leaves the
app open overnight sees yesterday's "Approved ✓" / "Needs a look" until some write happens
to land. Cheap mitigation that stays inside this feature: re-add the single legal event
(`TodayLoadRequested`) on app resume (`AppLifecycleListener`) or set `TodayState`'s
timestamp and re-evaluate in the view. Needs the same treatment in every screen that
shows per-period status, so it is worth a `SHARED_REQUEST` note rather than a
P08-only patch.

### B4 — minor — `_PushOnce` can latch `_busy` and permanently disable a button

`today_loaded_body.dart:252-268`:

```dart
void _push() {
  if (_busy) return;
  _busy = true;
  unawaited(_pushAndClear());
}

Future<void> _pushAndClear() async {
  await context.push(widget.location);
  _busy = false;
}
```

The guard itself is a good call (a rapid double-tap really would stack two pushed pages),
and it is applied to all four `push` sites while the `go` destinations are correctly left
unguarded. But `_busy` is only cleared when the pushed future completes, so:

- if `context.push` throws (a bad location, a redirect race), `unawaited` leaves an
  unhandled async error and `_busy` stays `true` **forever** — Review/+ dead for the life
  of the screen;
- if the pushed page is discarded without being popped (a `go` from the pushed screen
  replaces the stack), the future never completes and the same latch happens.

**Fix:** `try { await context.push(...); } finally { _busy = false; }`, plus reset `_busy`
in `didUpdateWidget` when `location` changes. Also fix the comment at `:257-258` — "the
flag is plain state, so a disposed widget cannot throw" is true but is not a reason to
skip the `finally`; as written the comment reads as a justification for the latch.

### B5 — minor — the period boundary tests duplicate the seed's clock pin as literals

`test/features/today/today_repository_test.dart` hard-codes
`DateTime.utc(2026, 10, 2, 22, 30)`, `DateTime.utc(2026, 10, 3)` and
`DateTime.utc(2026, 10, 24, 23, 30)` / `(2026, 10, 25, 12)`, while
`test/flutter_test_config.dart` pins `Seed.anchorOverride = DateTime.utc(2026, 10, 3)`.
The literals are the right instinct for an absolute boundary (a BST switch can only be
tested on a real date), but the duplicated pin can drift: move the override in
`flutter_test_config.dart` and these tests keep passing while quietly testing the wrong
day. **Fix:** export the pin (e.g. `const testAnchor = DateTime.utc(2026, 10, 3)` from a
shared test helper) and build the boundaries as offsets from it, keeping the literal only
for the genuine calendar edge (25 Oct 2026).

### B6 — minor — the new non-Mochi still art is untested

`app/test/pip_avatar_test.dart:84-91` asserts `fallbackAsset` for **Mochi only**, and the
reduced-motion test (`:187`) pumps a Mochi avatar, so nothing exercises
`bolt/s2_idle_1.svg` or the storybook files. The code is now total by construction
(`${style.dir}/s${stage}_idle_1.svg` for all three styles) and the files exist, so this is
coverage, not a defect — but it is exactly the gap that let iteration 2's M1 hide. **Fix:**
loop the reduced-motion assertion over `PipStyle.values` × stages 1..4 and assert an
`SvgPicture` is present. Shared file → `SHARED_REQUEST.md` §10.

### B7 — minor — `shot.sh` still cannot produce a stable frame (shared §6, unchanged)

`app/lib/core/data/env_flags.dart:9` is still
`bool.fromEnvironment('DISABLE_ANIMATIONS')`, which Dart parses as `false` for the `=1`
that `tools/screens/shot.sh:74` always passes, so every run warns
`frame never stabilised in 25 s` and the Rive idle loop runs during capture. The captures
are correct (I verified the dark one), but RULES §5's stable-frame guarantee is not met.
Not P08's to fix, already filed as §6 — noting only because the owner rules added this
iteration make screenshot determinism load-bearing for the bottom-edge/alignment checks,
so §6 should be prioritised rather than treated as cosmetic. One useful side effect of
fixing it: it will also make B6's still-frame path exercised on every screen.

### B8 — minor — "Happy week: 0 days" for a family with no children

`today_bloc.dart:64` builds the date line unconditionally, so `Seed.empty()` renders
*"Fri 2 Oct · Happy week: 0 days"* above a nest with no children (visible in
`ui/today-empty.png`). The clause is meaningless before the first child exists. **Fix:**
omit the clause when `summaries.isEmpty` (P08b's own header copy is that loop's scope).

### B9 — minor — P08b content is still inset 36 px

`today_loaded_body.dart:722-727` unchanged: `NestCard` 20 + `NestEmptyState`'s own
`horizontal: NestSpacing.s4` = 36 px, where the design's `.empty-card` wants 20. Measured
again in the new `ui/today-empty.png` (the card itself sits correctly at 20.00→369.67, so
alignment is fine — this is the inner inset). Iteration-1 B21, correctly deferred to the
P08b loop; re-check there.

### B10 — minor — the banner is still a `liveRegion` on a five-stream rebuild

`today_loaded_body.dart:458-461`. Cheaper to fix than it was (the duplicated label is
gone), but any coin change, child edit or completion insert re-announces the same
sentence. **Fix:** a `StatefulWidget` that sets `liveRegion` only when `pendingCount`
differs from the previous build.

### B11 — minor — `TodayState.happyDays` is still write-only

Set by the bloc (`today_bloc.dart:65`), never read by any widget — the label is composed
in `happyWeekLabel`. It is a seam for a future per-child breakdown, but as shipped it is a
field that invites a second, inconsistent "happy week" somewhere. Keep it with a comment
saying so, or drop it.

### B12 — minor — the three-children test still asserts copy, not the grid

`today_view_test.dart:864` proves *"Maya, Leo and Sam did brilliantly yesterday"* and
*"Hand to Maya and 2 others"* but nothing about the 2-up chunking fixed in iteration 1
(B6), so a refactor back to one-row-per-child would pass. **Fix:** assert
`tester.getSize(find.byType(NestCard).at(2)).width` ≈ 170 (half of 350 − 10), not ≈110.

### B13 — minor — ~10 Drift watchers per screen (carried)

`watchSummaries()` re-subscribes `watchItems()` internally (`:40`) and the bloc subscribes
both, with `watchChildren` watched twice plus `watchParentName`/`watchPayoutDay`/
`watchPendingCount`. No rebuild storm (Equatable props dedupe the `emit`) and the dataset
is tiny, so nothing user-visible — but one `Stream<TodayDay> watchTodayDay()` would
collapse it to a single subscription set and remove the nested `as List<dynamic>` casts
at `today_bloc.dart:46-51`.

## Checks that passed (no findings)

- **RULES §1 scope** — three-dot diff is exactly `features/today/**`,
  `test/features/today/**`, `docs/screens/P08/**`. No `core/`, no `app/`, no other
  feature, no `tools/screens/`; `analysis_options.yaml` untouched; no `skip`/`ignore` in
  the suite (96 feature tests, 0 skipped).
- **ARCHITECTURE** — `domain/` is entities + an abstract `TodayRepository` (six members,
  no concrete types, no use-case classes); `data/` is model + Drift impl; one bloc, one
  `TodayLoadRequested`, `initial/loading/loaded/failure`; the bloc is still a GetIt
  **factory**; the injected `clock` seam is a constructor parameter, not a global; DI and
  routes untouched.
- **No schema/migration/seed fork** — P08 adapted to the ruling through its own
  repository; the seed and schema changes landed on `main` (`e94d063`), correctly.
- **Design-system usage** — no colour literals, no magic numbers where a token exists, no
  hard-coded font family; `NestCard`, `NestQuestCard`, `NestButton`, `NestIconButton`,
  `NestAvatar`, `NestIcon`, `NestProgress`, `NestCoinPill`, `NestEmptyState`,
  `NestSectionLabel`, `PipAvatar` all reused. `_PushOnce` is a navigation guard, not a
  visual component, and there is no design-system equivalent to reuse.
- **DESIGN_SPEC §5 P08** — every element present and copy exact and en-GB; the one
  deviation (the "floating pill" line) is a stale spec line, filed as §5.
- **Accessibility** — 44px targets throughout; `header: true` on the greeting and group
  labels; per-child Pip/progress labels; the banner announces once; nothing under 12px; no
  red, no nagging; the two shared exceptions remain filed (§2 semantics, §6 determinism).
- **Performance** — Equatable props mean identical states never rebuild; const separators
  and const subtrees; `_PushOnce` deliberately avoids `setState`; no per-frame work; the
  failure path cannot stack subscriptions (`_closeOnError`). See B13.
- **Error handling** — `_closeOnError` makes the error terminal, a fixed kind message
  replaces the raw `toString()`, and "Try again" is covered by a test whose stream stays
  open.
- **Children's Code** — no analytics, ads, tracking or network calls; on-device Drift only;
  no child identifier, nickname, DOB or photo leaves the app; `/today` and `/today-empty`
  are both in the router's `parentOnly` set so kid mode is redirected to the parental gate;
  coins only, never `£`; no urgency or loss-framing copy.

## Before this screen passes

1. **B1** — the orchestrator lands the one-line shared-test fix (already §8). Until then
   RULES §7.1 cannot be met.
2. **B2** — a ruling on §9, then scope `watchPendingCount` to the current period and
   coordinate it with the P11 loop. The double-payout consequence is the reason to rule
   period-scoped.

B3-B13 are polish; B5, B6 and B12 are cheap and protect correctness that was just landed.

*Non-findings (loop-owned, per this iteration's rules): the iteration-3 work is uncommitted
in `app/`, and the branch's relationship to `main` is the orchestrator's to manage.*


## From 6_bugs.md
# P08 · Today (home) — bug hunt (Stage 6, iteration 3)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seeds `Seed.demo()` / `Seed.empty()`. **No screen code was changed.** Re-hunted
the iteration-3 working tree (after the iteration-3 fix pass and `main`
merges `5eea2ad`, `dec0c28`, `1a279ff`).

`app/test/features/today/p08_bugs_test.dart` now has 20 tests: the 11
iteration-1 proofs and the 2 iteration-2 proofs (all unskipped, green) plus
the **3 new skipped proofs** below and 4 unskipped regression pins (once /
Reduce Motion / B11 / B12). Run the proofs with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 3
fail against the current screen, by design.

## Iteration-2 ledger — closed

| ID | Iteration-2 finding | Status / proof |
|---|---|---|
| P08-B11 | period scoping missing in `rows()` | fixed — `_statusOf` uses `countsForCurrentPeriod` + injected clock (`today_repository_impl.dart:171-192`); proofs green, clock-owned boundary tests in `today_repository_test.dart` |
| P08-B12 | rapid double-tap stacked two editors | fixed — `_PushOnce` guard; proof green (see P08-B14 for its one hole) |
| Reduce-Motion pin | Bolt fallback was a dashed placeholder | fixed on `main` (`f6b02d8`); regression pin green |

## New findings (this iteration)

### P08-B13 — the approvals banner count ignores the periods ruling — MAJOR

- **Where:** `app/lib/features/today/data/today_repository_impl.dart:116-126`
  — `watchPendingCount()` counts **every** family-wide `done_pending`
  completion with no `countsForCurrentPeriod` filter, while every quest row
  (`:186-192`) is period-scoped. Also raised by `4_review` iteration 3 as its
  B2 and filed as `SHARED_REQUEST.md` §9 (pending a ruling).
- **Why it is a bug, not a taste call:** the ruling repeated in this stage's
  brief is *"a quest's status counts only for its current period … a
  completion outside the period means the quest is 'to do' again."* A stale
  `done_pending` is therefore no longer a pending status, yet the banner
  counts it. The label claims *"N quests waiting for your thumbs-up"* above a
  list with fewer "Needs a look" rows, and the stale completion still reaches
  P11, so a parent can approve and pay (P13 pays per approved completion) for
  a quest the child may immediately do — and be paid for — again. The review
  classified it major for the same double-payout reason.
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B13]'`
  - repository: insert a `done_pending` for daily `q-reading` before today's
    London day start → row reads `to_do` (correct), but
    `watchPendingCount()` returns **4** where the 3 seeded current-period
    pendings remain → expected **3**;
  - widget: the same data renders *"4 quests waiting for your thumbs-up"*
    above three current "Needs a look" rows → expected *"3 quests waiting for
    your thumbs-up"*.
- **Failing tests:**
  `[P08-B13] a stale pending completion does not count in the banner total`,
  `[P08-B13] the banner count matches the current-period rows`.
- **Suggested fix (feature-local):** scope `watchPendingCount()` the same way
  the rows are scoped — combine `watchAllCompletions` with the quests, keep
  only `done_pending` completions where
  `countsForCurrentPeriod(rule[c.questId] ?? 'once', c.createdAt, _clock())`
  (default `'once'` so a pending on an inactive/removed quest is not silently
  dropped; those count forever), then `.length`. Add the two proofs to the
  suite and unskip. **Coordinate with the P11 loop** (`§9`): if P11 keeps
  listing stale pendings, the two screens will still disagree — the ruling
  should land on both, or the banner label must change.

### P08-B14 — `_PushOnce` latches when the pushed page is replaced by `go` — MINOR

- **Where:** `today_loaded_body.dart:252-266`. `_busy` is set on tap and
  cleared **only** when `context.push(...)` completes; a pushed page that
  navigates home with `go` (the pattern P09/P11 may legitimately use — §4 asks
  for `pop`, but the guard must not depend on another screen's contract)
  replaces the stack without ever completing the push future.
- **Repro:** `--run-skipped … --plain-name '[P08-B14]'`
  - tap `+` → editor pushed;
  - the pushed page calls `go('/today')` → back on Today;
  - tap `+` again → **nothing happens** (probe: second-push editor count 0).
  The guard never clears, so `+`, Review, every quest row and P08b's
  "Add a quest" stay dead for the life of the screen. Related: if
  `context.push` itself throws, `unawaited(_pushAndClear())` leaves an
  unhandled async error and the same latch.
- **Failing test:** `[P08-B14] a pushed page navigating with go() unlatches it`.
  (First raised by `4_review` iteration 3 as B4; this stage proved it.)
- **Suggested fix:** do not couple the guard's lifetime to the push future
  alone — clear `_busy` when the route is no longer current (a
  `NavigatorObserver`/`RouteObserver` `didPopNext`/`didRemove`, or listen to
  the router's delegate) and wrap the await in `try/finally`; alternatively
  replace the latch with a short time-window debounce (ignore re-taps within
  ~500-600 ms), which cannot latch by construction. Keep `push` semantics.

## External blocker (shared, not P08-editable)

- **`4_review` B1 / `SHARED_REQUEST.md` §8** — `flutter test` (full) is red on
  the shared contract test `test/core/data/repositories_test.dart`
  ("today Maya 4 of 6, Leo 2 of 4": expected `2`, actual `1`). The periods
  ruling invalidated the pre-ruling expectation (`q-bag` is daily and its
  approval is yesterday's), so the one-line fix is `expect(leo.done, 1)` in a
  file RULES §1 forbids this agent to touch. It blocks RULES §7.1's
  full-suite-green requirement for the screen until the orchestrator lands it.

## Carried minors from `4_review` iteration 3 (still open)

- **B3** statuses are not re-evaluated at a day/week rollover while the app
  stays open (needs the same treatment on every per-period screen → shared
  note).
- **B5** period boundary tests duplicate the `flutter_test_config.dart` pin as
  literals (drift risk).
- **B6** non-Mochi still art is only covered by P08's regression pin; the
  shared `pip_avatar_test.dart` still loops Mochi only (`§10`).
- **B7** `shot.sh` cannot produce a stable frame until shared `§6`
  (`DISABLE_ANIMATIONS=1` never parses) is fixed.
- **B8** childless family header still reads "Happy week: 0 days" (P08b
  header copy is that loop's scope).
- **B9** P08b content inset 36 px vs the design's 20 (P08b loop).
- **B10** `liveRegion` banner re-announces on unrelated emissions (deferred).
- **B11** `TodayState.happyDays` is write-only (kept as a seam).
- **B12** the three-child copy test in `today_view_test.dart` still lacks the
  grid-width assertion (P08's `p08_bugs_test.dart` B05 proof has it).
- **B13** ~10 Drift watchers per open (perf smell, not user-visible).

## Owner rules — re-verified on the iteration-3 shots

- **Bottom edge:** read `ui/app_light_3.png` and `ui/app_dark_3.png` with the
  file reader — the tab-bar surface runs to the physical bottom edge in both
  themes (`rgb(255,255,255)` light / `rgb(31,28,46)` dark; the home pill is
  the only different element). No meadow/tint strip. Pass.
- **Alignment:** header, banner, kid cards, quest cards and the tab labels all
  sit on the same 20 px gutters in both shots; the review's numeric check
  (every card `x 20.00 → 369.67`) matches. Pass.

## Checked, no bug found (this iteration)

- Parent/kid guard (`/today`, `/today-empty`, `/quest-editor`), deep links,
  back navigation from approvals/editor (`push` + `handlePopRoute` proofs
  green).
- Rapid double-taps on the four push sites are blocked by `_PushOnce` (B12
  proof green) — its latch hole is P08-B14 above.
- Restart persistence unchanged; period statuses recompute from the DB and
  the injected clock on every load.
- Single-double-tap on `go` destinations (`/settings`, `/child-profile`,
  `/who-is-playing`, `/quests`) is idempotent.
- Dark-mode contrast, 320 px / 1.3x, long UK names, 0/1/6 children, empty
  lists, 9999 coins all covered by the existing suites; P08 shows coins only,
  so £0.00/£999.99 and integer-pence rounding do not apply.
- Europe/London/BST maths: `countsForCurrentPeriod` + day/week starts are
  correct incl. the 25 Oct 2026 switch (`test/core/london_period_test.dart`
  and the repository's boundary group).
- Emit-after-close / failed-stream retry: `_closeOnError` + bloc cancellation;
  proof green.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test test/features/today` → **96 passed, 3 skipped, 0 failed**.
- `flutter test` (full) → **468 passed, 3 skipped, 1 failed** — the one
  failure is the shared `repositories_test.dart` expectation above (`§8`),
  not P08 code. The 3 skips are this stage's proofs.

## Verdict

One new **major** bug (P08-B13 — the banner contradicts the mandatory periods
ruling and can route a stale completion into a double payout) plus one minor
(P08-B14), and a shared blocker that keeps the full suite red. No PASS is
possible.

