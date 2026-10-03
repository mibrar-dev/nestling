# P11 · Approvals — Stage 3 TEST (iteration 1)

Job: prove the screen, not just its happy path. Two new test files in
`app/test/features/approvals/` (53 tests) on top of the 57 the build stage
left behind. No `lib/` file was touched, no simulator was booted, and
`analysis_options` was not weakened.

## 1. Tests added

### `approvals_bloc_paths_test.dart` — 12 tests (new file)

The build stage's `approvals_bloc_test.dart` covers load → sorted loaded, one
approve, one not-yet, approve-all and each write's failure, one at a time.
This file pins the rest of the event/state surface:

| test | what it pins |
|---|---|
| two approvals in flight hold both busy ids | `busyIds` is a SET and bloc's default transformer (`_FlatMapStreamTransformer`) subscribes to every event, so same-type handlers really do run **concurrently**: gated writes end at `{1,2}` → `{2}` → `{}` |
| a stream re-emission re-sorts without clearing an in-flight write | the newest-first sort in `onData` rebuilds state from the current one — a stream emission must NOT re-enable a button mid-write |
| a stream re-emission keeps approveAllBusy set | the bottom CTA stays locked for the whole approve-all write |
| the stream draining to empty lands on an empty loaded inbox | empty is `loaded`, never `failure` |
| a failed stream can be retried and recovers into the inbox | the "Try again" path at bloc level: loading → failure → loading → loaded(3) |
| a not-yet failure sets actionError and clears the busy id | the one write whose error path was unproven (`verifyNever(approve)`) |
| consuming an action error that was never set emits nothing | `ApprovalsActionErrorConsumed` is a no-op; no repository call |
| 5 × `ApprovalsState` unit tests | `copyWith()` no-op equality, `clearActionError` keeps every other field, "only the fields you pass", every field in `props`, idle defaults |

### `approvals_view_states_test.dart` — 41 tests (new file)

Pattern copied from `test/features/pocket_money/money_ledger_states_test.dart`:
the real in-memory Drift DB (`Seed.demo` / `Seed.empty`), with only the stream
or the write swapped through a `_DelegatingApprovalsRepository`, so a scripted
state still reads and writes real tables.

| group | tests |
|---|---|
| loading | spinner only — no helper, no cards, no CTA, title `(0)`, back chevron still tappable (1) |
| empty | `Seed.empty` (onboarded parent, no children) → "All caught up" + message, no helper, no CTA, no "Approve all (0)" (1); inbox drained through the real repo → no `ListView` at all (1) |
| failure | stream error → message + 52 px Try again + tap action, no inbox chrome behind it (1); Try again re-subscribes and recovers the **real** seeded inbox, `attempts == 2` (1) |
| writes → DB | Approve → 1 `quest_bonus` row (maya / 15p / "Empty the dishwasher") + `status = approved`; Not yet → `status = not_yet`, **zero** new ledger rows, no SnackBar; Approve all → 0 pending, 3 rows totalling 30p, empty landing (3) |
| write safety | a second tap on the same Approve writes only once (gated repo holds the card busy; the pill is `loading` + `onPressed == null` and the call count stays 1) (1); two cards busy at once, both writes land (1); the last row is lazily unbuilt on a 320×600 screen, scrolls into view and still approves (1) |
| action errors | rejected approve keeps the card, shows one SnackBar (`danger` fill, `onLeaf` text) and the bloc has consumed the error (1); the **next** identical failure surfaces again — proof the first was really cleared, since `listenWhen` would otherwise dedupe it (1) |
| sizes | matrix 3 widths × 2 text scales × 3 `ThemeMode` = 18 tests: no overflow exception, title and CTA present, and the **20 px gutter** held on banner + card + CTA at 300/310/410-wide, plus the 44 px floor on the row button and the CTA |
| dark | `ThemeMode.dark` really resolves the dark scheme (`paper`/`surface`/`leafTint` all differ from light), `Scaffold.backgroundColor == tokens.paper`, 3 × 24-radius surface cards, leaf-tint helper, and the CTA surface still runs to the physical edge |
| tap targets | back 44 × 44, all six row pills and the CTA ≥ 44 × 44 (1); no `KidScope` on the screen, so the 56 px kid floor is documented as N/A (1) |
| navigation | cold `INITIAL_ROUTE=/approvals` launch: `GoRouter.canPop()` is **false**, so back takes the `go('/today')` branch (1); pushed from Today's "Review": `canPop()` is **true**, back pops to `/today` (1); approve / not-yet / approve all never leave `/approvals` (1) |
| semantics | `performAction(tap)` on "Approve all (3)" drains the inbox **and** writes 3 ledger rows (1); each seeded card announces exactly one summary label ("Maya, Empty the dishwasher, Today 8:12am, 15 coins") while its two buttons stay separately tappable (1); a busy card's two buttons report `enabled == false` and expose **no** tap action, while the other card's stay live (1) |
| copy | rune-level: helper copy carries U+201C/U+201D/U+2014 and no ASCII quote, the card lines use U+00B7 with single spaces (not a bullet, no typographic rewrite), counts in ASCII parens |

`performAction(SemanticsAction.tap)` now drives a real effect for **every**
control on the screen: back (→ `/today`, twice: cold + pushed), both row
buttons (→ ledger write / `not_yet` status), Approve all (→ 3 ledger rows) and
Try again (→ 2 subscriptions, inbox back).

## 2. Results

```
$ dart format .                                    # clean, no changes needed
$ flutter analyze <all 464 tracked .dart files> test/features/approvals/approvals_bloc_paths_test.dart \
                   test/features/approvals/approvals_view_states_test.dart
Analyzing 466 items...
No issues found! (ran in 4.6s)

$ flutter test <the 7 P11-owned approvals files>
00:04 +112: All tests passed!

$ flutter test                                      # whole repository
00:39 +2239 ~1: All tests passed!                   # 1 pre-existing skip
```

* No new lints, no ignores, no skipped tests. No `google_fonts` import or
  `GoogleFonts.*` call anywhere in the feature or its tests (0 hits).
* The `~1` skip is pre-existing and belongs to another feature
  (`test/features/pocket_money/p12_bugs_test.dart`).

**Concurrent-agent note (not a finding, not mine to fix).** While this stage
ran, the loop's *bugs* stage was working in this same worktree and had left its
scratch file `test/features/approvals/p11_probe_test.dart` in the tree (its own
header: "SCRATCH probe file — deleted before the final bugs suite lands"). It is
untracked, so it is excluded from the analyze run above (which uses
`git ls-files`) and from the 7-file approvals run; a bare `flutter test
test/features/approvals` and a bare `flutter analyze` do pick it up and report
10 issues / 9 failures that belong to that in-flight file, not to P11. Left
alone on purpose.

## 3. Bugs found

**None.** No test exposed a defect in the screen, and nothing in
`app/lib/features/approvals/**` was changed by this stage.

Two of my own tests failed while being written and each turned out to be a
wrong assumption in the test, not a screen defect — recorded so the next
iteration does not re-derive them:

1. The demo seed already carries **9** historical `quest_bonus` ledger rows
   (quests approved before the inbox opened), so the wallet assertion is a
   delta, not `isEmpty`. Fixed by pinning the delta (and it doubles as proof
   that approving adds exactly one row for the right child and amount).
2. The busy window against the real database is **sub-frame**: the Drift write
   and the stream re-emission both land inside the first `pump()`, so the card
   is already gone when the next assertion runs. The double-tap and
   two-cards-at-once tests therefore use a gated repository
   (`_GatedWritesRepository`) to hold the write open; the repository-level
   guard (`status != 'done_pending'` → no-op) is covered in
   `approvals_repository_test.dart`.

## 4. Observations (not defects, no action)

* **`errorMessage` survives a retry.** `ApprovalsState.copyWith` cannot null a
  field, so after a failure → retry the loaded state still carries the old
  message. It is invisible: the view only reads `errorMessage` in the
  `failure` branch, and `approvals_bloc_paths_test.dart` pins the retry's
  user-visible outcome (back on the inbox) rather than the stale string.
* **The title reads `Waiting for you (0)` while loading.** It follows
  `state.items.length`, which is 0 until the first stream emission — DATA OVER
  MOCKS, transient, no design conflict.
* **The failure branch shows the raw exception text** (`Bad state: …`). Error
  path only, no design for it, out of scope for this screen.
* **A synchronous throw from `watchItems()`** would propagate out of the event
  handler (bloc `onError` + rethrow) instead of becoming a `failure` state.
  Unreachable with the Drift-backed repository (its streams report errors
  asynchronously), so it is not covered by a test — pinning it would mean
  encoding a hang as expected behaviour.
* **Stage 5 inputs unchanged:** the quote-less cards (no `note` column) are
  still the accepted −34 px per card, and `NestBottomCta` still runs the
  surface to the physical edge per the OWNER bottom-edge rule. Both are
  asserted in the geometry and dark-mode tests so a future change to either
  shows up here first.

## 5. Verification the new assertions are live

Two temporary negative controls (both reverted, `git diff` clean afterwards):

| mutation | result |
|---|---|
| `busyIds: const <int>{}` in the busy-card test | fails `Expected: true / Actual: <false>` on `p11_not_yet_1` |
| right gutter expectation shifted by 1 px | fails `Actual: <300.0> / Which: differs by <1.0>` in all 18 matrix tests |

The SnackBar "shows again" test is live by construction: without
`ApprovalsActionErrorConsumed` the second, identical error would be deduped by
the view's `listenWhen` and no SnackBar would appear.

VERDICT: PASS