# P11 · Approvals — Stage 3 TEST (iteration 2)

Tree under test: `f2eb632 P11: checkpoint after build (iteration 2)` — the
quote (`ORCHESTRATOR_NOTES.md` items 1 + 4), the `ApprovalsBottomCta` rework
(item 3) and the four `6_bugs.md` fixes all landed since iteration 1.

Job: extend the suite over the behaviour iteration 2 introduced, and re-certify
everything else. **15 new tests** across three files; no `lib/` file touched, no
simulator booted, `analysis_options` untouched, nothing skipped.

## 1. Tests added

### `approvals_bloc_paths_test.dart` +6 (12 → 18)

The iteration-2 build added the bloc half of BUG-P11-1: a card absorbs a repeat
decision while the write is in flight (`busyIds`) **and** after it finished
(`_decided`), because with an instant write the second tap can arrive after the
busy flag has cleared. New group `ApprovalsBloc decision absorb (BUG-P11-1)`:

| test | what it pins |
|---|---|
| a second approve while the write is in flight never reaches the repo | the guard emits **nothing at all** (`seen.length` unchanged) and the repository sees one call |
| a repeat approve AFTER the write finished is still absorbed | `_decided`: busy flag clear, button live, no second write; a *different* card still works |
| a not-yet decision is absorbed the same way | and a repeat **approve** on that card never reaches the repository either — one decision per card (BUG-P11-2's screen half) |
| a failed decision is NOT absorbed, so the parent can retry | failures never enter `_decided`: after the SnackBar the retry really hits the repository again |
| a decided id is released once the row leaves the inbox | `_decided` is pruned on every stream emission, so the set cannot grow for the life of a session |
| a second approve-all while the write is in flight is absorbed | the CTA absorbs its own double tap (one bulk write) |

Two test-infrastructure notes, both reusable:

* **`_StateRecorder`** — a handler that emits `busy → cleared` (or
  `error → cleared`) delivers both inside one microtask turn, so chaining
  `await bloc.stream.firstWhere(a); await bloc.stream.firstWhere(b);` hangs even
  though `b` was emitted. One listener + a recorded list cannot miss anything.
  It has two waits on purpose: `settled` polls `bloc.state` (cannot miss, but
  cannot see a transient state either) and `until` scans the recorded states
  (sees transients, so it matches history too).
* **`_CountingApprovalsRepository`** replaces mocktail in this group. The busy
  flag is emitted one microtask *before* the repository call, so verifying a
  mock at that instant races the handler; an explicit call list is both clearer
  and deterministic. (`_decide → approveCalls == [1, 1]` reads the contract
  directly.)

### `approvals_repository_test.dart` +3 (10 → 13)

The data half of `ORCHESTRATOR_NOTES` item 1 (`quest_completions.kid_note`,
schema v6):

1. the seeded notes arrive **raw**, without the curly quotes — dishwasher
   `I stacked everything neatly!`, bed `I did the pillows too.`, q-table `NULL`
   — and no note ever contains `“` (the quotes are the card's job);
2. a note written after the seed (the K05-style write path) still reaches the
   card;
3. `kidNote` round-trips through `ApprovalModel` and is part of equality.

### `approvals_view_states_test.dart` +4 (41 → 45)

| test | what it pins |
|---|---|
| Approve then Not yet on the same card keeps ONE decision | **BUG-P11-2 end to end**: two taps with no pump between them (both land on live controls — the default `warnIfMissed` fails if they do not), then the database ends `approved` with exactly one `quest_bonus` row and no error SnackBar |
| the child quote is announced next to the card summary | the merged `.hd` label still carries only child/quest/when/coins, and the quote is its **own** semantics node — the child's words are reachable by VoiceOver |
| the quote uses ink in dark mode too | `.qn` paints `tokens.ink` (not the caption's ink-2) at 17 px, letterSpacing 0 |
| a long child note wraps instead of overflowing at 320 × 1.3 | a 70-char note written straight to the DB wraps inside the card padding, the buttons stay ≥ 44, no exception |

## 2. Coverage carried forward from iteration 1 (re-certified, still green)

| file | tests | what it holds |
|---|---|---|
| `approvals_quote_test.dart` | 4 | copy (`“$kidNote”`, U+201C/U+201D), NULL note → no line **and no gap**, 172/138/172 card heights, tops 187/375/529, quote between `.hd` and the row |
| `approvals_view_geometry_test.dart` | 8 | status-bar reserve, compact nav, banner 107–171, card geometry (quoted + bare), the CTA 24 px above the edge at zero inset **and** on the design's 734–786 at a 34 px home inset, the 20 px gutter grid, dark anchors |
| `approvals_view_test.dart` | 16 | seeded inbox, helper copy, light/dark shapes, bottom-edge rule, approve / not-yet / approve-all, back → `/today`, CTA lock, five `performAction(tap)` proofs |
| `approval_card_widget_test.dart` | 19 | time helpers (incl. the zone day-boundary cases), avatar colours, card internals, BUG-P11-4 per-button busy, summary semantics |
| `approvals_bloc_test.dart` | 12 | the original load/write/failure/consume sequences |
| `p11_bugs_test.dart` | 9 | the four `6_bugs.md` proofs, now live (no skips) |

**144 approvals tests, 0 skipped.**

## 3. Results

```
$ dart format --output=none --set-exit-if-changed test/features/approvals
Formatted 9 files (0 changed) in 0.05 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.5s)

$ flutter test test/features/approvals
00:03 +144: All tests passed!

$ flutter test                          # whole repository
00:42 +2280 ~1: All tests passed!       # the 1 skip is pre-existing, P12's
```

Per file: bloc-paths 18 · repository 13 · view-states 45 · quote 4 · geometry 8
· card widget 19 · view 16 · bloc 12 · bugs 9 = **144**.

## 4. Bugs found

**None.** No test in this iteration exposed a defect in the screen, and the
four bugs from iteration 1 remain fixed (their proofs are green and unskipped).

Two things surfaced while writing these tests, both **test-side** and both worth
recording for the next iteration:

1. **The busy flag paints before the repository call** (one microtask earlier).
   Verifying a mock at the moment the busy state appears races the handler and
   fails intermittently. Fixed by counting calls in a hand-written repository
   (`_CountingApprovalsRepository`) instead of verifying a mock mid-flight.
2. **`bloc.stream` is a broadcast stream**, so a second `firstWhere` subscribed
   after the first emission has already been delivered can never see it. Fixed
   with `_StateRecorder`. Both patterns also affect any future P11 test, so the
   helpers live in the test file rather than in a scratch copy.

One observation for the record (no action, not a defect): `ORCHESTRATOR_NOTES`
item 1 says to render the quote in "Nunito", but the HTML sets no family on
`.qn` — it inherits the body font, which is Inter — and the iteration-2 build
renders `NestType.bodyStrong` (Inter, w700, 17/24, letterSpacing 0). The CSS
cascade supports the build's choice; the tests pin the style that shipped
(`tokens.ink`, 17 px, no tracking) rather than a family the design does not
specify.

## 5. Negative controls (both reverted)

| mutation | result |
|---|---|
| same-frame test asserting `not_yet` instead of `approved` | fails `Expected: 'not_yet' / Actual: 'approved'` — the money invariant is genuinely asserted |
| `_StateRecorder.until` replaced by a bare `firstWhere` | hangs (the missed-emission race the recorder exists to remove) |

VERDICT: PASS