# P03 Create account — build note (Stage 2, iteration 5)

Route `/create-account` · parent mode · feature `auth`. Implements
`1_plan.md` plus every item in `FIXES_4.md` (bugs P03-BUG-15…21, review
findings 1–7, iteration-3 `ORCHESTRATOR_NOTES` items, standing COPY and
CHILD ORDER rules — CHILD ORDER is N/A, P03 lists no children).

## Files changed (all inside RULES §1)

- `app/lib/features/auth/presentation/views/create_account_view.dart` —
  labelled live regions (BUG-21), CTA-level hit-test expansion without dead
  fields (review finding 3), `_verifyTotal` re-arm (finding 5), token line
  heights (finding 7), overlap note on the link TODO.
- `app/test/features/auth/p03_bugs_test.dart` — un-skipped 18/19/20/21,
  BUG-16 to skip-with-reason, label assertions added to BUG-20, strip-proof
  attempt documented as harness-impossible.
- `app/test/features/auth/copy_audit_test.dart` — no change needed
  (subtitle proof already un-skipped and green).
- `docs/screens/P03/2_build.md` — this file. `SHARED_REQUEST.md` §5
  disposition reworded to the agreed skip-with-reason (no semantic change).

## What was done about each fix item

- **BUG-21 (MAJOR, empty live region)**: both owned error rows are now
  `Semantics(liveRegion: true, label: <message>, child:
  ExcludeSemantics(child: Text(<message>)))` — announced once, labelled
  once. Proof green; BUG-20 extended with label + `bySemanticsLabel`
  assertions so the hole that hid the regression is closed.
- **BUG-16 (shared-blocked)**: per review finding 1 the proof stays
  **skip-marked with an explicit reason** (a `skip:` string does not
  compile — the parameter is `bool?` — so the reason lives in the comment
  above `skip: true`). No code change: passing `errorText` would re-open
  P03-BUG-11, and the shared row has no live region (§8), so switching
  would trade BUG-16 for BUG-20.
- **BUG-17 (shared font pipeline)**: no local change, correctly — any width
  or size hack would violate tokens-only. Shared §6 owns it; no local test
  can pin a break the harness font does not produce.
- **BUG-18 (overhang reachability)**: kept (proof green). Debugging showed
  the wrapper must sit above the CTA column and that delegating first can
  never fall through (the bar background claims every in-panel tap), so the
  caption-Stack walk runs for outside-stack points — with no duplicates for
  inside-stack taps, and submit-guarded controls where geometries overlap.
- **BUG-19 (first frame / staleness)**: kept; the mirror was verified
  against the SDK's `Text.build` resolution (ambient merge, scaler, locale,
  alignment) after a phantom-drift infinite loop broke `pumpAndSettle` —
  fixed by the exact merge plus a hard cap on total verifications.
- **BUG-20 (live region)**: fixed by the BUG-21 change above; proof now
  asserts flag *and* label for both fields.
- **Review 1 (red suite)**: green — BUG-21 fixed, BUG-16 skip-with-reason,
  only shared BUG-6 skipped.
- **Review 2 (apostrophe)**: already U+2019 and green; untouched.
- **Review 3 (subtitle break)**: shared §6, untouched by design.
- **Review 4 (fallback fires after a hit)**: the fallback is now scoped to
  outside-stack points only (see BUG-18 above). The suggested `!hit` gate
  would re-break BUG-18 — the bar background always claims in-panel taps —
  so it is documented as considered-and-rejected. The `tapAt` strip proof
  could not be written: the overlap strip never exists in the harness (its
  wide font pushes Terms off line 1 at every width), so the attempt was
  removed with a note; the decision (submit wins functionally, inert links)
  stands on the documented geometry instead.
- **Review 5 (`_verifyTotal` lifetime cap)**: reset in
  `didChangeDependencies` alongside `_verifyLeft` — the cap now bounds a
  chain, never the widget's lifetime.
- **Review 6 (§5 disposition)**: reworded to state skip-with-reason
  explicitly; no semantic change (it already described that outcome).
- **Review 7 (token debt)**: `height: 20 / 13` → `NestSpacing.s5 / 13` at
  both sites (was already done in iteration 4's tree); §7 stays open.
- **ORCHESTRATOR_NOTES iter-3**: apostrophe done; break stays shared §6;
  filled simulator capture stays UI-stage/host-blocked.

## Evidence tails (app/)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → all pass (1 shared skip: BUG-6).
- `flutter test` (full suite) → `789 passed, 1 skipped, 0 failed` (the skip
  is shared P03-BUG-6 only).
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/2_build.md` (+ the loop's
  own `.brief_build.md`, not mine) — nothing shared.

VERDICT: PASS
