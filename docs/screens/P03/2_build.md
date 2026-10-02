# P03 Create account — build note (Stage 2, iteration 4)

Route `/create-account` · parent mode · feature `auth`. Implements
`1_plan.md` plus every item in `FIXES_3.md` (bugs P03-BUG-15…20, review
findings 1–7, iteration-3 `ORCHESTRATOR_NOTES` items, standing COPY and
CHILD ORDER rules — CHILD ORDER is N/A, P03 lists no children).

## Files changed (all inside RULES §1)

- `app/lib/features/auth/presentation/views/create_account_view.dart` —
  curly subtitle (BUG-15), CTA-level hit-test expansion (BUG-18),
  layout-synchronous target measurement (BUG-19), live-region error rows
  (BUG-20), token line heights (finding 7).
- `app/test/features/auth/copy_audit_test.dart` — un-skipped "subtitle".
- `app/test/features/auth/create_account_view_test.dart` — subtitle constant
  to U+2019.
- `app/test/features/auth/p03_bugs_test.dart` — un-skipped 15/18/19/20,
  retired 16, header notes updated. BUG-6 stays skipped (shared core);
  BUG-17 never had a proof (shared §6, no local test possible).
- `docs/screens/P03/2_build.md` — this file. `SHARED_REQUEST.md` untouched
  (§§2/4/5/6/7 stay open, non-blocking; §§1/3 resolved).

## What was done about each fix item

- **BUG-15 (MAJOR, straight apostrophe)**: subtitle now ships U+2019
  (byte-verified `e2 80 99`), matching `You&rsquo;re`. Both proofs green.
- **BUG-16 (shared-blocked)**: the shared `hasError` flag did **not** land
  (`NestTextField` still couples border to `errorText`), so per review
  finding 1 the proof is **retired** (deleted with a pointer to
  `SHARED_REQUEST.md` §5) — passing `errorText` again would re-open
  P03-BUG-11. Gutter message still pinned by the helper/error view tests.
- **BUG-17 (shared font pipeline)**: no local change possible and none
  attempted, per the report (token violation to chase). Shared §6 owns it.
- **BUG-18 (overhang not hittable)**: a `_HitTestExpand` render object wraps
  the whole bottom bar. Taps its own box resolves normally (zero behaviour
  change); taps outside the caption Stack descend into its children
  directly, bypassing intermediate bounds-checks — full 44dp boxes are
  reachable, layout size untouched (hairline stays 678). Two subtleties
  found by debugging and documented in code: the wrapper must sit *above*
  the CTA column (nothing below it is ever reached for overhang taps), and
  taps inside the box delegate first (the bar background claims everything).
  Cost: a 4dp strip shared with the CTA button row; both fire there and the
  submit wins functionally — inert links, zero user impact today.
- **BUG-19 (first frame + stale measurement)**: targets are now measured
  **synchronously during layout** (`LayoutBuilder` + a `TextPainter` mirror
  of the exact span tree, including the ambient-`DefaultTextStyle` merge
  `Text.rich` resolves — verified against the SDK source; without it the
  mirror drifts and the chain never settles, which broke `pumpAndSettle`).
  A bounded post-frame chain (4 passes, 12 total — hard stop so settling is
  guaranteed) re-measures the real paragraph and rebuilds only on drift
  (font swaps). Proof green; resize/scale/theme relayout proofs still green.
- **BUG-20 (no live region)**: both owned error rows are now
  `Semantics(liveRegion: true, child: ExcludeSemantics(child: Text(...)))`
  — announced once, labelled once. `sendAnnouncement` stays for `formError`.
  Proof green for both fields; helper stays a plain node.
- **Review 1 (red suite)**: green — BUG-15 fixed, BUG-16 retired per the
  prescribed option, only shared BUG-6 skipped.
- **Review 2/3**: one-character fix each (apostrophe; no width hack —
  shared §6 owns the break).
- **Review 4/5/6**: same fixes as BUG-18/19/20 above.
- **Review 7 (token debt)**: `height: 20 / 13` → `NestSpacing.s5 / 13` at
  both sites; `SHARED_REQUEST.md` §7 (legal-caption token) already filed.
- **ORCHESTRATOR_NOTES iter-3**: item 2 apostrophe fixed (break remains
  shared §6, untouched by design); item 1 (nbsp) and filled-state widget pin
  untouched and green; filled simulator capture stays UI-stage/host-blocked.

## Evidence tails (app/)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → all pass (1 shared skip).
- `flutter test` (full suite) → `664 passed, 1 skipped, 0 failed` (the skip
  is shared P03-BUG-6 only; arithmetic: 659 + 6 un-skipped − 1 retired).
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/2_build.md` — nothing
  shared.

VERDICT: PASS
