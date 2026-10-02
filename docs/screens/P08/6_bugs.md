# P08 · Today (home) — bug hunt (Stage 6, iteration 4)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seeds `Seed.demo()` / `Seed.empty()`. **No screen code was changed and no new
bugs were found.** Re-hunted the iteration-4 working tree (after the
iteration-4 fix pass and `main` merges `e972b46`, `74846a0`, `bcc9c41`,
`633dfd2`, `f813945`).

`app/test/features/today/p08_bugs_test.dart` has 21 proofs, **all unskipped
and green** (11 iteration-1 + B11×3 + B12 + B13×2 + B14 + 2 pins). No proof
needed to be re-skipped this iteration; no `skip` remains anywhere in
`app/test/features/today/`.

## Ledger — iteration 3 closed

| ID | Iteration-3 finding | Outcome / evidence |
|---|---|---|
| P08-B13 major | banner count ignored the periods ruling | fixed — `watchPendingCount()` joins completions to quests and filters with `countsForCurrentPeriod(rule ?? 'once')`; both proofs green; the screen-level "banner disappears when no pending is in period" test added |
| P08-B14 minor | `_PushOnce` latched when the pushed page left via `go` | fixed — guard is now per-frame (`_armed` + `addPostFrameCallback`) and cannot latch; proof green |
| shared §8 blocker | `repositories_test.dart` pinned pre-ruling Leo count | resolved on `main` by `e972b46`: `q-bag`'s approval moved onto the story day, so it is inside the current London day and counts; Leo is **2 of 4** again, mock number preserved, full suite green |
| review B5 | boundary tests duplicated the clock pin | fixed — boundaries are offsets from one local `storyDay`; only the genuine 25 Oct BST edge keeps a calendar literal |
| review B6/B7/B10/B11 | still-art coverage, `DISABLE_ANIMATIONS`, grid assertion, watchers | B10's width assertion is present in `today_view_test.dart` (verified); B6/B7/§6, §10, §11 remain filed shared items |

## Adversarial checks this iteration

**Push guard (the only structural change this iteration).** The new
`_PushOnce` re-arms on the next frame, so I tried to break it the way a real
device would:

- same-frame double-tap (the B12 proof) → one editor;
- second tap **50 ms later**, after the guard re-arms, on the default Android
  transition → one editor;
- the same with `TargetPlatform.iOS` (Cupertino slide) for both a quest row
  and `+` → one editor; the second tap is absorbed by the incoming page
  (`tester` reports it as a hit-test miss on the old row), so no second push
  can be stacked;
- pushed page replaced with `go('/today')` → the button works again
  (the B14 proof).
  No repro of either the old double-push or a latch. I did **not** add a
  cross-frame pin for this: the observed behaviour depends on route-transition
  hit-testing (harness-level), which would make the test brittle. The
  same-frame proof and the `go`-replace proof cover both failure modes.

**Banner scoping edges.** With the period-scoped `watchPendingCount()`:
stale daily and weekly `done_pending`s are excluded (the B13 proofs); a
pending on an **"Anyone"** quest still counts (the B06 proof); a pending on a
deactivated/removed quest defaults to `once` and counts forever (deliberate,
documented at `today_repository_impl.dart:117-119`) so nothing is silently
dropped. Re-emission on a new pending is covered by
`watchPendingCount re-emits when a new approval arrives`.

**Owner rules on the fresh iteration-4 shots.** Read `ui/app_light_4.png` and
`ui/app_dark_4.png` with the file reader: the tab-bar surface runs to the
physical bottom edge in both themes (white light / `#1F1C2E` dark, home pill
the only different element), and greeting, banner, kid cards, quest cards and
tab labels all sit on the same 20 px gutters. The review's numeric sweep
(x 20.00→369.67 at every card band, both themes) agrees. **Pass.**

**Standard hunt list — re-checked, no bug:** parent/kid guard and deep links
(`/today`, `/today-empty`, `/quest-editor` gated; B01 proof green); back
navigation from approvals and editor (B07/B14 proofs); restart persistence
(load path unchanged; period statuses recompute per load); dark-mode contrast
(tokens unchanged, shots read); 320 px / 1.3×, long UK names, 0/1/6 children,
empty lists, 9 999 coins (suites + B04/B05/B09 proofs); async gaps
(`_closeOnError` + bloc cancellation, B08 proof); Europe/London day/week and
BST boundaries (`london_period_test.dart` + repository boundary group);
money rounding N/A (P08 renders coins only, never `£`).

## Carried items (all non-blocking, none P08-local)

- **Cross-screen, ship condition:** P11's `watchPendingApprovals` is still
  unscoped, so `/approvals` can list a stale pending that P08's banner no
  longer counts — and a stale approval still routes into P13 payout. P08 is
  internally consistent; the P11 loop must apply
  `countsForCurrentPeriod(rule ?? 'once')` (or the orchestrator reverts/
  relabels the banner). Filed as `SHARED_REQUEST.md` §9.
- **§11 / review B3** — statuses are not re-evaluated when the day/week rolls
  over under an app left open; needs a shared refresh-on-resume pattern.
- **§6 / review B5** — `DISABLE_ANIMATIONS=1` still parses to false, so
  `shot.sh` frames never stabilise (captures verified correct; makes the
  owner-rule screenshot checks less deterministic).
- **§10 / review B4** — shared `pip_avatar_test.dart` still exercises only
  Mochi still art.
- **review B2** — `unawaited(context.push(...))` would surface a rejection as
  an unhandled async error; normal path is unaffected.
- **review B6/B7** — P08b childless header "Happy week: 0 days" and the 36 px
  empty-card inset belong to the P08b loop.
- **review B8/B9/B11** — `liveRegion` re-announce, write-only
  `TodayState.happyDays`, ~10 Drift watchers per screen; polish only.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `351 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test test/features/today` → **passing, 0 failed, 0 skipped**
  (verified myself; the review counted 106).
- `flutter test` (full) → **479 passed, 0 failed, 0 skipped**.

## Verdict

No blocker or major bugs: the iteration-3 findings are fixed with proofs, the
new push guard survives same-frame and cross-frame double-taps on both
platform transitions, the banner scoping holds at its edges, the demo numbers
match the seed (`Maya 4/6`, `Leo 2/4`, banner 3) and both owner rules pass on
the fresh light/dark shots. The remaining items are carried minors — one of
them (`§9`, the P11 list) is a cross-screen coordination condition, not a P08
defect.

VERDICT: PASS
