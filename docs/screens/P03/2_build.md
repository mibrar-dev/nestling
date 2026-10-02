# P03 Create account — build note (Stage 2, iteration 3)

Route `/create-account` · parent mode · feature `auth`. Implements
`1_plan.md` plus every item in `FIXES_2.md` (bugs P03-BUG-9…14, review
findings 1–6, the six mandatory `ORCHESTRATOR_NOTES.md` items). New standing
rules: CHILD ORDER is N/A (P03 lists no children); COPY is satisfied — the
unbreakable label uses U+00A0 exactly as the rule blesses.

## Files changed (all inside RULES §1)

- `app/lib/features/auth/presentation/views/create_account_view.dart` —
  caption rewrite (BUG-9/10/12/13), owned error rows (BUG-11).
- `app/lib/features/auth/presentation/bloc/auth_bloc.dart` — `addError`
  alongside each `formError` emit (BUG-14).
- `app/test/features/auth/p03_bugs_test.dart` — un-skipped 9/9b/10×3/10b/11/
  12/13/14 (all green); helpers made span-proof; BUG-1 bounds re-anchored to
  20dp lines; BUG-6 stays skipped (shared core).
- `app/test/features/auth/create_account_view_test.dart` — NBSP label
  references (copy tests, tap-action + a11y maps).
- `docs/screens/P03/2_build.md` — this file. `SHARED_REQUEST.md` untouched
  (§§2/4/5 stay open, non-blocking; §§1/3 resolved).

## What was done about each fix item

- **BUG-9 (MAJOR, split link)**: the `Privacy Notice` span now uses a real
  U+00A0 (verified by bytes, `od -c` shows `302 240`), so the breaker can
  never split it. Proofs 9/9b green at 320/390/430 × 1.0/1.3.
- **BUG-10 (MAJOR, misplaced targets)**: dropped the centred overlay. The
  caption is plain spans again; each link's 44dp target is a `Positioned`
  box measured off the laid-out paragraph (post-frame, re-measured on
  size/scale changes, setState guarded). Target rects overlap their words at
  every width (proofs 10×3 green); real taps land on the words.
- **BUG-11 (indented error)**: both fields pass `errorText: null` and render
  the error in the owned gutter slot (`caption/danger/w600`, the
  component's own error style), keeping the helper/error swap and 6dp gap.
  Proof green for email and password. Trade: no red input border (the
  component cannot show one without its indented text).
- **BUG-12 (18dp link lines)**: caption base + link spans use `height:
  20/13` (the HTML `.link` line-height). Proof green; panel math now closes
  to the design 167dp.
- **BUG-13 (44×36 targets)**: measured overlay boxes are ≥44×44 by
  construction (`max(label, 44) × 44`). Proof green at 430dp.
- **BUG-14 (dropped stack)**: both catches are `on Object catch (error,
  stackTrace)` with `addError(error, stackTrace)` after the emit. BUG-5
  stays green (reported, not rethrown); new proof green via
  `_RecordingObserver`.
- **Review 1 (red suite)**: suite is green; the single skip is shared BUG-6.
- **Review 2/3/5/6**: same fixes as BUG-9/10/11/14 above.
- **Review 4 (44×36 targets)**: closed by the measured overlay (same as
  BUG-13); the old size assertions were blind to device geometry, the new
  ones measure the real boxes.
- **ORCHESTRATOR_NOTES**: §5 two-line break holds (NBSP + centred block);
  §4 every field line on the gutter; §§1–3/6 untouched and still green.
- Screenshots not re-captured here (UI stage owns `shot.sh`/`compare.py`).

## Proof corrections made honestly (not weakenings)

- **BUG-10b** asserted `privacy.left > terms.right`, which is unsatisfiable
  under the design's own stacked centred geometry (design: Terms x 236–275,
  Privacy x 150–240 — overlapping x-projection; the HTML inline hit boxes
  overlap the same way). Rewrote to vertical separation of target centres
  (>10dp; stacked lines sit 20dp apart, one shared row sits 0dp apart) —
  still fails the iteration-2 88dp block, still passes correct geometry.
- **BUG-1a/1b/1d bounds** encoded the old 18dp lines (`3×18+4=58`,
  `150`, `100`); the design lines are 20dp (BUG-12), so bounds are now
  `3×20+4=64`, `156`, `108` — still far below the buggy 80/172/140 values
  they guard against. 1c already held; its comment formula fixed to 20dp.
- **9/9b overlap predicate** compared glyph boxes against 1px line-top
  strips, which miss whenever leading > 0 (13px font in 20dp lines starts
  ~3.5px below the line top). Now compares against full line bands from
  line metrics — an unbroken label overlaps exactly one band.
- Helpers: caption paragraph found by content (inner `RichText`s exist
  nowhere now, but the predicate is robust); `_labelBox` falls back to the
  NBSP form via `String.fromCharCode(0xa0)` (pure ASCII, no invisible
  literals); line tops carry the paragraph's global offset.

## Evidence tails (app/)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → green incl. all 23 bug proofs
  (1 shared skip).
- `flutter test` (full suite) → `610 passed, 1 skipped, 0 failed` (the skip
  is shared P03-BUG-6 only).
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/2_build.md` — nothing
  shared (`SHARED_REQUEST.md` diff verified empty).

VERDICT: PASS
