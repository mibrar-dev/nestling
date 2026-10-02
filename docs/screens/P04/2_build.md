# P04 · Privacy consent — build notes (STAGE 2, iteration 4)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built per `docs/screens/P04/1_plan.md`, fixing every item in
`docs/screens/P04/FIXES_3.md` that is fixable inside RULES §1, and
un-skipping the bug proofs the fixes turn green. `ORCHESTRATOR_NOTES.md`
(with the 12:03 and 13:42 UPDATEs) is honoured: the trash glyph stays
deferred to the shared batch, and "everything else" is fixed below.

## Files changed (all inside RULES §1)

Production (`app/lib/features/privacy_consent/**`):

- `data/privacy_consent_repository_impl.dart` — the first-run upsert now
  runs inside `_db.transaction` (FIXES_3 finding 2 / P04-9): the
  UPDATE-then-conditional-INSERT pair is atomic, so two overlapping writes
  serialise and the last one wins instead of the first INSERT winning.
  Single-write behaviour is unchanged (UPDATE fast path, insert fallback
  with table defaults, `watchSetting` re-emit).
- `presentation/views/privacy_consent_view.dart` — the four `_PromiseRow`s
  are now a single `Column` child of `NestList` (with `MainAxisSize.min`
  for the unbounded scroll height), so shared `NestList` injects no real
  dividers; `_PromiseRow` gained a `showDivider` flag (rows 2–4) that wraps
  its content in a `Stack` with a zero-layout-height `Positioned(top: 0,
  left: 72, right: 0, height: 1, Divider(height: 1, thickness: 1, line))`
  overlay — the same reference point the design's `::before` uses
  (FIXES_3 finding 1 / P04-4). Card chrome (surface, r16, shadow),
  semantics, 56 px rows, 40/r12 tiles and copy are untouched.

Tests (`app/test/features/privacy_consent/**`):

- `p04_bugs_test.dart` — un-skipped `[P04-4]` (list height == row-height
  sum, now green) and `[P04-9]` (overlapping first-run writes keep the last
  value, now green); header index marks both `[FIXED]` and the stale
  iteration-3 comments updated. `[P04-2]` and `[P04-7]` stay skipped
  (shared batch: trash asset, themed shield).
- `privacy_consent_view_contract_test.dart` — the geometry test now asserts
  the overlay structure: exactly three 1×1 `Divider`s, each inside a
  `Positioned(top: 0, left: 72, right: 0, height: 1)`.

Docs (`docs/screens/P04/**`): new screenshots `ui/app_{light,dark}_4.png` +
`ui/cmp_{light,dark}_4.png`. `SHARED_REQUEST.md` §6 stays filed for the
shared component (every other `NestList` screen still inherits the drift).

## What happened to each FIXES_3 item

- Finding 1 (MAJOR, +3 px divider drift; orchestrator item 3, assigned to
  P04) — FIXED as described above; `[P04-4]` un-skipped and green. The
  shared `NestList` is untouched (still wrong for other screens — §6 stays
  filed) but no longer blocks P04: list is exactly 4 × 56 = 224 px.
- Finding 2 (MINOR, non-atomic upsert / P04-9) — FIXED via the transaction
  (the review's preferred home; also shareable with P16's `_write` later);
  `[P04-9]` un-skipped and green (5/5 deterministic), and the iteration-2
  first-run double-tap guard still passes.
- Finding 3 (MINOR, quoted test tail) — this note quotes the tool's real
  strings verbatim below; "All other tests passed!" is what `flutter test`
  prints when skips exist (0 failures, N skipped), not a failure.
- P04-2 (MAJOR, empty row-4 tile) — NOT fixable in scope: `ic_trash.svg` /
  `NestIcons.trash` still absent from this worktree (verified), deferred
  to the shared batch by the 13:42 UPDATE. Tile reserved + `TODO(P04)` kept;
  `[P04-2]` stays skipped with flip instructions.
- P04-7 (MINOR, dark shield) — NOT fixable in scope (baked shared asset,
  §2, in the shared batch). `[P04-7]` stays skipped.

## Analyze tail (app/)

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent test/features/privacy_consent
→ Formatted 17 files (0 changed)
flutter analyze → No issues found! (ran in 3.6s)
```

## Test tail (app/, `flutter test`)

P04 scope: `00:04 +107 ~2: All other tests passed!` — 107 passed,
2 skipped (the shared-blocked `[P04-2]`/`[P04-7]` proofs), 0 failed,
including the newly un-skipped `[P04-4]` and `[P04-9]`.
Whole app: `00:22 +594 ~2: All other tests passed!` — 594 passed,
2 skipped, 0 failed.

## UI check (iteration 4)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e) +
`compare.py` vs the design PNGs:

- Light mean diff **4.10%** (was 4.49%) — bands: 0: 1.59% · 1: 6.02% ·
  2: 1.98% · 3: 7.94% · 4: 5.78% · 5: 4.19% · 6: 0.40% · 7: 4.84%
- Dark mean diff **5.15%** (was 5.61%) — bands: 0: 1.56% · 1: 8.50% ·
  2: 9.14% · 3: 7.87% · 4: 5.75% · 5: 4.44% · 6: 0.39% · 7: 3.55%

Bands 4–5 drop in both themes as the 3 px recovery propagates past the
list; the heat-map shows the same divider hairlines at the same indent,
and the iteration-4 shot is otherwise identical (header Δ0, gutters 20 px,
CTA surface to the physical edge both themes — the strip difference vs
the PNG is the intended OWNER-rule behaviour). Remaining drift is the two
filed shared causes — empty row-4 tile (§1) and light-baked dark shield
disc (§2, dark band 2) — plus simulator font edges and the ignored
status-bar clock.

VERDICT: PASS
