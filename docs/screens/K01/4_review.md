# K01 · Who's playing? — Stage 4 QA code review (iteration 3)

Reviewed the cumulative `git diff main...HEAD` after iteration 3
(K01-BUG-3 wired, K01-BUG-6 bloc gate, `profilesFailed` state flag,
1_plan.md copy correction). Analyzer: `No issues found!`.
`flutter test test/features/kid_home/`: 332 passed, 0 skipped,
0 failed — the previously parked BUG-2/BUG-3 proofs now run live and
pass.

## Findings

1. **minor** — `KidHomeState.profilesFailed` is write-only in product
   code. It is set on the profiles error path
   (kid_home_bloc.dart:145) and cleared by healthy rosters, but the
   K01 view no longer reads it — the iteration-2 heal branch that
   consumed it was removed (`profile_picker_view.dart`, failure case
   now always returns `_PickerFailure`). The bloc separately tracks the
   identical `_profilesFailed` bool (kid_home_bloc.dart:44). Keeping
   both is confusing; either surface the state flag in the UI or drop
   the state field and keep the bloc-local one.

2. **minor** — stale test-file comment: `k01_bugs_test.dart:405` still
   reads "K01-BUG-3 — STILL OPEN (iteration 2)… Fix: …" directly
   above a test that iteration 3 un-skipped and now passes with
   exactly that fix applied. Update the header to "FIXED (iteration
   3)" to match the surrounding FIXED/kept-green blocks.

3. **minor** — K01-BUG-6 bloc gate
   (`kid_home_bloc.dart:172-176`, `if (state.selectedProfileId !=
   null) return;`) drops a second in-flight selection silently. This
   is correct for the nav/DB pairing, but note the legitimate path:
   if a first tap's `setActiveChild` fails, the listener routes to the
   error toast, and a second tap in the same burst is then allowed —
   fine. No code change; flagging for awareness.

## Verified fixed since iteration 2

- **K01-BUG-3** — the picker's listener now dispatches
  `KidHomeSelectionHandled` immediately after `context.push`
  (profile_picker_view.dart:74-78); the one-shot is consumed instead of
  relying on a racy home-stream emission. The live proof test
  `K01-BUG-3: tapping the same tile after back does nothing` passes.
- **K01-BUG-6** — new bloc state-gate drops the second
  `KidHomeProfileSelected` of a burst; `_busy` is armed before
  dispatch (profile_picker_view.dart:33-44) so the first DB write and
  the pushed route always agree. Proof test passes.
- **Iteration-2 review finding 2** — `profilesFailed` is threaded
  through every `copyWith`/`withCompletion*` constructor and cleared on
  healthy roster/recovery; the failure case no longer leaks a stale
  roster over a dead home stream.
- **Iteration-2 finding 4** — `1_plan.md` §0 now documents ASCII
  U+0027 as the source-of-truth convention ("match your own HTML"),
  resolving the copy-record contradiction.

## Re-verified clean

- Feature-first layering, abstract repo, per-route bloc factory, DI +
  routes per feature — unchanged and intact.
- No hard-coded colours/sizes/fonts; token-only styling; components
  reused (`KidScope`, shared `kid_meadow`, `NestBalancedText`,
  `NestAvatar`, `PipAvatar`, `NestKidButton`).
- No `DateTime.now()`, no `google_fonts`/`GoogleFonts.*`, no
  `letterSpacing` additions in K01 code.
- Streams cancelled in `close()`; tile busy latch + single-flight nav;
  1632-byte row test anchors not regressed; Children's Code — no
  analytics/ads/child data exfiltration in kid mode.
- One formatter-only touch to
  `app/test/design_system/list_row_trailing_test.dart` remains on the
  branch; ride it on a merge rather than a K01 change if convenient.

VERDICT: PASS
