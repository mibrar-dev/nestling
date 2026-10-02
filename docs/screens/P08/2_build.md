# P08 · Today (home) — build notes (Stage 2, iteration 4)

Built per `1_plan.md` + every item in `FIXES_3.md` + the stage brief's
PERIODS ruling. The 3 skipped proofs (P08-B13 ×2, P08-B14) are unskipped and
pass; all prior proofs stay green.

## Files changed (all RULES §1-legal)

Lib (`app/lib/features/today/**`):

- `data/today_repository_impl.dart` —
  - **P08-B13**: `watchPendingCount()` is now period-scoped like the rows:
    combines `watchAllCompletions` + `watchActiveQuests`, keeps only
    `done_pending` completions with `countsForCurrentPeriod(rule ?? 'once',
    createdAt, now)` (unknown quests default to `once` so a pending on a
    removed quest is not silently dropped). A stale pending no longer
    inflates the banner, closing the double-payout path. (Dropped the now
    unused `drift` import.) NOTE filed for P11: its list must apply the same
    scoping or the Review list will disagree with the banner
    (`SHARED_REQUEST.md` §9).
  - `rows()` doc comment records the ruling (statuses re-evaluated per call).
- `presentation/widgets/today_loaded_body.dart` —
  - **P08-B14**: `_PushOnce` rewritten from clear-on-pop to a **per-frame
    guard** (push at most once per frame, re-arm on next frame). The old
    latch was structural: `go('/today')` re-selects the shell branch and
    preserves the subtree, so the push future never completes and `_busy`
    stuck true (a `ModalRoute.isCurrent` check could not help either — both
    taps run before the Navigator rebuilds). The frame guard cannot latch
    by construction: same-frame double-taps share one push; anything later
    (pop, `go`-replace, or a throw) works again.
- `presentation/bloc/today_state.dart` — untouched (m4 doc already fixed).

Tests (`app/test/features/today/**`):

- `p08_bugs_test.dart` — 3 skips removed.
- `today_repository_test.dart` — B5: the periods group now takes boundaries
  as offsets from one local `storyDay` (mirrors the pinned anchor; kept
  local because screen agents may not add shared helpers) — only the 25 Oct
  BST→GMT edge keeps real calendar literals. The `summary counts` test pins
  bag's approval to the previous London day itself instead of relying on
  seed stamps (it broke when the seed moved bag's approval onto the story
  day, `e972b46`).
- Expectations reverted for the seed fix: Leo is **2 of 4** again
  (`e972b46` approves `q-bag` on the story day, so it counts under the
  ruling; the iteration-3 `done 1` / `1 of 4` expectations were updated
  back). `SHARED_REQUEST.md` §8 marked resolved — no action needed.

## Fix-item ledger (FIXES_3 refs)

- **B1** (shared `leo.done == 2` red) — resolved on main by `e972b46`;
  full suite green, §8 closed.
- **B2/B13** (banner not period-scoped, major) — fixed as above; both
  proofs green. Cross-screen coordinate in §9.
- **B14** (push-guard latch, minor) — fixed as above; proof green
  (tap → editor, `go('/today')`, tap → editor again).
- **B3** (rollover re-eval) — shared pattern needed; filed as §11 (new).
- **B5** (literal drift) — fixed as above. **B6** (still-art coverage) —
  filed as §10 (shared test file). **B7** (§6) — still open (prioritise per
  review). **B8/B9** — P08b loop scope, untouched. **B10/B11** — still
  deferred seam/notes. **B12** (grid-width assert) — already present in
  `today_view_test.dart` from iteration 3 (verified: `NestCard.at(2)` ≈
  170 px); the finding looked at the copy test only.
- Carried m6/m8 — still deferred (P08b scope / minor).

## Verification tails

- `dart format .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app).
- `flutter test test/features/today` → `All tests passed!` (+99).
- `flutter test` (full) → `All tests passed!` (+472).
- `shot.sh` light + dark + empty from final sources (all newer; all three
  read back). Every run warns `frame never stabilised in 25 s` (shared §6,
  still open); captures are complete and correct.
- `compare.py`: light mean **5.21 %**, dark **4.85 %**. Residual is
  data-driven: live date, all 10 real rows vs the mock's 5, banner
  balance-wrap.
- Owner rules re-verified on the fresh shots: **BOTTOM EDGE** — sampled the
  centre column to the physical edge: white `(255,255,255)` light /
  `(31,28,46)` dark continuously (home pill only interruption) ✓;
  **ALIGNMENT** — no horizontal geometry changed this iteration; gutters
  visually consistent, review's numeric check (cards `20.00 → 369.67`) stands.

VERDICT: PASS
