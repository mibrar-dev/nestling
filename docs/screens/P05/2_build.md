# P05 · Add children — build notes (STAGE 2, iteration 4)

Route `/add-children` (feature `family`, parent mode). Iteration 3 record is
superseded below. Every item in `docs/screens/P05/FIXES_3.md` is addressed;
both skipped proofs (P05-BUG-9, P05-BUG-10) are un-skipped and green; zero
skips remain.

## Files changed (RULES §1 only)

- `app/lib/features/family/data/family_repository_impl.dart` — the roster
  query now orders by `rowid` (insertion proxy) instead of the core helper's
  nickname order (CHILD ORDER ruling, P05-BUG-9); interface untouched.
- `app/lib/features/family/presentation/widgets/kid_card_grid.dart` —
  `cardH` drops the 10 px pencil clearance and the name→age gap is 6
  (`gap6`), so cards render the design's 116 (P05-BUG-10); `TODO(P05)`
  deferral replaced by a comment stating the ruling is satisfied locally.
- `app/lib/features/family/presentation/widgets/add_child_form_card.dart` —
  the four now-redundant `IntrinsicWidth` wrappers removed (shared
  `NestChip` shrink-wraps since `7eaa1f7`); stale "until the shared fix
  lands" comment replaced.
- `app/test/features/family/add_children_test.dart` — order test flipped
  to creation order (`maya.left < leo.left`); 5-child grid height updated
  124 → 116; pencil containment now resolves Maya's own card (order-proof).
- `app/test/features/family/p05_bugs_test.dart` — BUG-9 + BUG-10 skips
  removed; header comment updated.
- `docs/screens/P05/3_test.md` — the two stale claims corrected (child
  order satisfied via interim; chip workaround removed).
- `docs/screens/P05/SHARED_REQUEST.md` — child-order request kept open as
  the DURABLE fix with the interim recorded; chip component request marked
  LANDED.
- `docs/screens/P05/2_build.md` — this file.

No files outside RULES §1 touched. No `domain/` interface changes, no core
changes, no signature changes to existing members.

## What was done about each fix item

- **Finding 1 (shared gate) — `router_push_test` asserts placeholder copy.**
  Still failing on main's file, still outside RULES §1, still filed as
  blocking. Verified below; not counted against this diff.
- **Finding 2 / P05-BUG-9 (major) — CHILD ORDER.** Implemented the
  review-verified interim exactly: `FamilyRepositoryImpl.watchChildren`
  runs its own `rowid`-ordered query (allowed `data/**` path, own DB
  handle) instead of the nickname-ordered core helper. Demo seed yields
  `[Maya, Leo]`; new children append by insertion. `TODO(P05)` dropped.
  Un-skipped proof (`maya.left < leo.left`) passes; the old
  nickname-order test was flipped, not deleted. Shared createdAt request
  stays as the durable fix.
- **Finding 3 — dead `IntrinsicWidth` wrappers.** Removed all four (group
  semantics kept); the BUG-1 geometry proofs (box < run, ≤2 rows, block
  height) still pass against the fixed component.
- **Finding 4 — order-pinning test.** Inverted to the ruling
  (`maya.left < leo.left`); it now proves the fix instead of the defect.
- **Finding 5 / P05-BUG-10 — 124 px cards.** `cardH` = 22 + 44 + 2 + 24 +
  6 + 18 = 116 at 1.0 (text-scaler-scaled beyond); the name→age gap uses
  the existing `gap6` token. Un-skipped proof (≤118) passes, as does the
  kept pencil-inside-card assertion (the 44 px pencil overlays a 116 card).
- **Finding 6 — wrong feasibility claims.** Corrected here and in
  `3_test.md` (interim feasible and landed; shared request durable-only).
- **Finding 7 — carried accepts (no action).** Dropped-Continue, `onSaved`
  deferral, `child_display` placement, raw error string, 1 px offsets —
  unchanged positions, listed so the delta is explicit.
- **COPY ruling.** Re-verified character-exact vs the HTML (no copy
  touched this iteration); the `’` fix from iteration 3 is pinned by the
  code-unit guard.
- **Orchestrator items.** All prior notes hold (chips, header, bottom
  edge, alignment, focus ring); item 2 (rowid meanwhile) now implemented.

## Verification tails

`dart format .` — clean (re-ran after every edit).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:11 +636 -1`: the single failure is
`app/test/app/router_push_test.dart` ("push between top-level onboarding
routes"), which asserts P05's pre-build placeholder title, arrived from
main, is outside RULES §1, and has been filed as BLOCKING since iteration
3. Every in-scope test passes (110/110 in `test/features/family/`, zero
skips — `grep -c "skip:"` returns 0 in both files). Every widget test that
pumps the app ends with `disposeApp(tester)`.

VERDICT: PASS
