# P11 · Approvals — Stage 3 TEST (iteration 1)

Job: prove the screen, not just its happy path. Three new test files in
`app/test/features/approvals/` (57 tests) plus updates to the three existing
ones after the iteration-2 build landed. No `lib/` file was touched, no
simulator was booted, and `analysis_options` was not weakened.

> **Tree under test.** This stage ran while the loop's *build* stage worked in
> the same worktree, so the screen changed under it: `shared/completion_note`
> (schema v6, `quest_completions.kid_note`) arrived on `main`, and the build
> then landed the four `6_bugs.md` fixes plus the quote and the CTA rework.
> Every number below was re-measured on the final tree; where a test had to
> follow a deliberate behaviour change, the change is named.

## 1. Tests added

### `approvals_bloc_paths_test.dart` — 12 tests (new)

The build stage's `approvals_bloc_test.dart` covers load → sorted loaded, one
approve, one not-yet, approve-all and each write's failure, one at a time. This
file pins the rest of the event/state surface:

| test | what it pins |
|---|---|
| two approvals in flight hold both busy ids | `busyIds` is a SET and bloc's default transformer (`_FlatMapStreamTransformer`) subscribes to every event, so same-type handlers really do run **concurrently**: gated writes end at `{1,2}` → `{2}` → `{}`, with `busyActions` naming the decision on each |
| a stream re-emission re-sorts without clearing an in-flight write | the newest-first sort in `onData` rebuilds state from the current one — a stream emission must NOT re-enable a button mid-write |
| a stream re-emission keeps approveAllBusy set | the bottom CTA stays locked for the whole approve-all write |
| the stream draining to empty lands on an empty loaded inbox | empty is `loaded`, never `failure` |
| a failed stream can be retried and recovers into the inbox | the "Try again" path at bloc level: loading → failure → loading → loaded(3) |
| a not-yet failure sets actionError and clears the busy id | the one write whose error path was unproven (`verifyNever(approve)`) |
| consuming an action error that was never set emits nothing | `ApprovalsActionErrorConsumed` is a no-op; no repository call |
| 5 × `ApprovalsState` unit tests | `copyWith()` no-op equality, `clearActionError` keeps every other field, "only the fields you pass", every field in `props` (incl. `busyActions`), idle defaults |

### `approvals_view_states_test.dart` — 41 tests (new)

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
| write safety | a second tap on the same Approve writes only once (gated repo holds the card busy; the pill is inert and the call count stays 1) (1); two cards busy at once, both writes land (1); the last row is lazily unbuilt on a 320×600 screen, scrolls into view and still approves (1) |
| busy state | only the tapped pill spins; the same card's other pill is inert and exposes no tap action; the other cards stay live (1) — this is the BUG-P11-4 contract, end to end |
| action errors | rejected approve keeps the card, shows one SnackBar (`danger` fill, `onLeaf` text) and the bloc has consumed the error (1); the **next** identical failure surfaces again — proof the first was really cleared, since `listenWhen` would otherwise dedupe it (1) |
| sizes | matrix 3 widths × 2 text scales × 3 `ThemeMode` = 18 tests: no overflow exception, title and CTA present, and the **20 px gutter** held on banner + card + CTA at 300/310/410-wide, plus the 44 px floor on the row button and the CTA |
| dark | `ThemeMode.dark` really resolves the dark scheme (`paper`/`surface`/`leafTint` all differ from light), `Scaffold.backgroundColor == tokens.paper`, 3 × 24-radius surface cards, leaf-tint helper, and the CTA surface still runs to the physical edge |
| tap targets | back 44 × 44, all six row pills and the CTA ≥ 44 × 44 (1); no `KidScope` on the screen, so the 56 px kid floor is documented as N/A (1) |
| navigation | cold `INITIAL_ROUTE=/approvals` launch: `GoRouter.canPop()` is **false**, so back takes the `go('/today')` branch (1); pushed from Today's "Review": `canPop()` is **true**, back pops to `/today` (1); approve / not-yet / approve all never leave `/approvals` (1) |
| semantics | `performAction(tap)` on "Approve all (3)" drains the inbox **and** writes 3 ledger rows (1); each seeded card announces exactly one summary label ("Maya, Empty the dishwasher, Today 8:12am, 15 coins") while its two buttons stay separately tappable (1) |
| copy | rune-level: helper copy carries U+201C/U+201D/U+2014 and no ASCII quote, the card lines use U+00B7 with single spaces (not a bullet, no typographic rewrite), counts in ASCII parens (1) |

### `approvals_quote_test.dart` — 4 tests (new, `ORCHESTRATOR_NOTES.md` items 1 + 4)

The gate for the mandate the UI stage was overruled for: the child's note must
render from `quest_completions.kid_note`, and both card heights must be pinned.
Written against the seeded DATABASE and the rendered screen only (no
compile-time dependency on the `Approval.kidNote` field), and it carries the
real faces so a wrapped line cannot silently shift every y.

1. the seeded notes render as `“$kidNote”` with U+201C/U+201D — dishwasher and
   bed;
2. a NULL note renders no quote line **and no gap** (q-table: `.row` 14 px under
   `.hd`, button at `card.top + 74`);
3. quoted cards are 172 tall, the NULL card 138, tops 187 / 375 / 529;
4. the quote sits between `.hd` and the button row: 24 high, 10 px under `.hd`,
   button row at `card.top + 108`.

**These four were red before the build landed the quote** (`Found 0 widgets with
text "“I stacked everything neatly!”"`, `Actual: <138.0>` vs `near(172)`) and
are green after it — recorded because the loop's next stage should know the
gate exists and what it enforces.

## 2. Existing P11 tests updated to follow deliberate changes

| file | change |
|---|---|
| `approvals_view_geometry_test.dart` | card heights 138/138/138 → **172/138/172** and tops 187/341/495 → **187/375/529** (the quote block is `10 + 24`); `.row` anchor `card.top + 74` → `+108` on a quoted card with the NULL case still `+74`; the CTA test no longer treats its position as a deviation — it now pins **24 px above the physical edge** at zero inset and a **new** test pins the design position **734–786 (centre 760)** at the design's 34 px home inset, with the surface still running to the edge |
| `approvals_view_states_test.dart` | `NestBottomCta` → `ApprovalsBottomCta` (the screen-local panel that honours `ORCHESTRATOR_NOTES` item 3); row taps go through `ensureVisible` first, because the quoted list is taller than the scroll viewport and a lazily built row whose centre sits below the clip would swallow the tap |
| `approval_card_widget_test.dart` | `busy disables both buttons` pinned the pre-fix behaviour (both pills spinning). Replaced by two tests: a busy card swallows taps and spins **nothing** it was not told to, and **only the pressed pill spins** while the card is busy (BUG-P11-4) |

`p11_bugs_test.dart`'s nine proofs (stage 6) now all pass with
`--run-skipped`, and the skip markers are gone, so they are live regression
tests.

## 3. Results

```
$ dart format .
Formatted N files (0 changed).

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.4s)

$ flutter test test/features/approvals
00:05 +131: All tests passed!          # 0 failed, 0 skipped

$ flutter test                          # whole repository
01:20 +2267 ~1: All tests passed!       # the 1 skip is pre-existing, P12's
```

* No new lints, no ignores, no skipped tests. No `google_fonts` import or
  `GoogleFonts.*` call anywhere in the feature or its tests (0 hits).
* `performAction(SemanticsAction.tap)` drives a real effect for **every**
  control: back (→ `/today`, twice: cold + pushed), both row buttons (→ ledger
  write / `not_yet` status), Approve all (→ 3 ledger rows), Try again (→ 2
  subscriptions, inbox back).

## 4. Bugs found

**None found by this stage, and none left open.**

The four bugs in `6_bugs.md` (BUG-P11-1 double credit, BUG-P11-2 "Not yet"
overwriting an approval, BUG-P11-3 BST day labels, BUG-P11-4 both pills
spinning) were filed by the bug stage on the iteration-1 tree and fixed by the
build while this stage ran; their proofs are green and live, and my own tests
now pin the fixed contracts (per-button busy state end to end, one ledger row
per tap, two concurrent cards).

The one real defect this stage's own tests exposed is **not** in the screen: a
third of my file's tests failed against the mid-build tree because the quote
made the third card's button centre fall below the scroll clip in the
fallback-font test surface. That is a test-environment artefact — the geometry
test loads the bundled faces and pins the real position (card 3 buttons at
637–685, inside a 645 px viewport) — so the fix was `ensureVisible` in the tap
helper, not a screen change.

## 5. Observations (not defects, no action)

* **`errorMessage` survives a retry.** `ApprovalsState.copyWith` cannot null a
  field, so after a failure → retry the loaded state still carries the old
  message. Invisible (the view reads it only in the `failure` branch) and pinned
  by the retry test's user-visible outcome rather than the stale string.
* **The title reads `Waiting for you (0)` while loading** — `state.items.length`
  until the first emission. DATA OVER MOCKS, transient, no design conflict.
* **The failure branch shows the raw exception text.** Error path only, no
  design for it.
* **A synchronous throw from `watchItems()`** would propagate out of the event
  handler instead of becoming a `failure` state. Unreachable with the
  Drift-backed repository, so deliberately untested — pinning it would encode a
  hang as expected behaviour.
* **Stage 5 has nothing left to reconcile on this screen:** the cards are now
  the design's 172/138/172 and the "Approve all" pill sits on the design's
  734–786 at the design's home inset. Both are asserted, so a regression in
  either fails here first.

## 6. Verification the new assertions are live

Three temporary negative controls, all reverted:

| mutation | result |
|---|---|
| `busyIds: const <int>{}` in the busy-card test | fails `Expected: true / Actual: <false>` on `p11_not_yet_1` |
| right-gutter expectation shifted by 1 px | fails `Actual: <300.0> / Which: differs by <1.0>` in all 18 matrix tests |
| `ApprovalsBottomCta` removed from the zero-inset CTA assertion | fails on `screen.bottom - button.bottom` |

The SnackBar "shows again" test is live by construction: without
`ApprovalsActionErrorConsumed` the second, identical error would be deduped by
the view's `listenWhen` and no SnackBar would appear. The quote gate was
demonstrably red before the build and green after it.

VERDICT: PASS