# P08 · Today (home) — test notes (Stage 3, iteration 3)

Screen: `P08` · route `/today` (+ `P08b` `/today-empty`) · feature `today` ·
mode parent · seeds `Seed.demo()` / `Seed.empty()`.
Scope of this stage: tests only — **no screen code was changed**.

## 1. Focus of this iteration — the PERIODS ruling

The repository now scopes a quest's latest completion with
`countsForCurrentPeriod(repeatRule, completedAt, nowUtc)`
(`daily` → current Europe/London day, `weekly` → current London week
Mon 00:00–Sun 24:00, `once` → forever) through the new clock seam
(`TodayRepositoryImpl({db, clock})`, default `Seed.anchorOverride ?? wall
clock`), so stale completions read `to_do` again and the kid-card `done`
counts follow (`today_repository_impl.dart:134-192`).

Verified independently, with **fixed UTC instants** (not values derived from
the helper under test) so a UTC-day implementation would fail:

| Case | Completion | Now | Expected | Why |
|---|---|---|---|---|
| daily, after London midnight | 2 Oct 23:30Z | 3 Oct 00:00Z | counts | 00:30 BST on 3 Oct — same London day although the UTC date is 2 Oct |
| daily, before London midnight | 2 Oct 22:30Z | 3 Oct 00:00Z | `to_do` | 23:30 BST on 2 Oct — yesterday |
| weekly, Monday 00:30 London | 27 Sep 23:30Z | 3 Oct | counts | the London week starts Mon 28 Sep 00:00 BST = 27 Sep 23:00Z |
| weekly, Sunday night | 27 Sep 22:30Z | 3 Oct | `to_do` | previous London week |
| daily, BST→GMT switch day | 24 Oct 23:30Z / 22:30Z | 25 Oct 12:00Z | counts / `to_do` | 25 Oct is GMT; the day start is 24 Oct 23:00Z |
| summary `done` moves with the clock | seed `q-bag` daily approval 2 Oct | 3 Oct vs 2 Oct | Leo 1/4 vs 2/4 | the same data, two "now"s |

The 4 proofs un-skipped by the iteration-3 build (P08-B11 ×3, P08-B12
double-tap `_PushOnce` guard) pass unskipped; **no `skip:` remains anywhere
in `app/test/features/today/`**.

## 2. Tests added this iteration — 10 new (feature suite 86 → 96)

`today_repository_test.dart` (+6, group
`TodayRepository periods (Europe/London ruling)`): the six boundary/summary
cases above, each with an explicit `clock`.

`today_view_test.dart` (+4):

- `P08 Today alignment (owner rule)` — at 390 px: greeting text and section
  title flush to the 20 px left gutter; avatar flush to 370; `+` exactly
  8 + 44 px left of it; banner (live-region wrapper), kid cards (Maya left /
  Leo right), `See all`, every quest row and the hand-off button all share
  the same gutters.
- `P08 Today bottom edge (owner rule)` ×2 (light + dark) — the tab bar's
  own surface `Container` spans the full width and its bottom edge **is** the
  physical screen bottom (`rect.bottom == 844`, height `NestDevice.tabH`), in
  both themes: no coloured strip under the bar or around the home indicator.
- `P08 Today period scoping in the view` — a stale daily approval
  (2 Oct 22:30Z) renders its row as `To do`, not `Approved ✓`.

Also fixed a stale test *name* (`demo seed cards: … Leo 1/4 + 45`) and
re-reviewed the build's test edits: no assertion was weakened; the shared
`repositories_test.dart` expectation it could not touch is the only red (§6).

## 3. Coverage vs the stage checklist (unchanged parts re-run green)

- **bloc_test every event/state path**: load → loading/loaded, error →
  failure, retry, re-emission without events, family-wide pending count
  (12 tests).
- **Widget tests light + dark, widths 320/390/430, scale 1.0/1.3**: 12-case
  matrix, no `RenderFlex overflowed`, plus the dark content and dark failure
  tests and the 6-children/320 px/1.3× stress case.
- **empty / loading / error**: `/today` + `/today-empty` with
  `Seed.demo`/`Seed.empty`; loading/error drive `TodayView` over a mock
  repository (a healthy in-memory DB cannot fail).
- **every tap → right route**: Review, `+`, quest row (±`questId`), See all,
  avatar, kid card (`childId`), Hand, `Add a quest`, `Browse ideas`; pushed
  pages also prove system-back returns to Today.
- **semantics labels on icon buttons** and the banner announcing exactly
  once; tap targets ≥ 44 px parent (≥ 56 px kid is N/A — parent mode; the
  route is gated to P17 in kid mode, P08-B01).
- **Pip rule**: each card renders the child's own `PipAvatar` from the DB,
  no v1 `pip_stage_*.svg`; P08b egg `mochi`/stage 1 at 140; non-default
  style/skin/accessory travels unchanged; Reduce-Motion art pinned
  (P08 M1 proof).

## 4. Results

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | `350 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test test/features/today` | **96 passed, 0 failed, 0 skipped** (12 bloc · 20 repo · 47 view · 17 bug proofs) |
| `flutter test` (full app) | **+468 −1** — the single failure is the shared test in §5 below |

## 5. Bugs found this iteration

**None in the screen.** The period ruling, the alignment rule and the
bottom-edge rule are all implemented, tested and green.

One red remains in the full suite and it is **not a screen bug**:

- `app/test/core/data/repositories_test.dart:53` (`today Maya 4 of 6, Leo 2
  of 4`) still expects `leo.done == 2`; the ruling makes `q-bag`'s daily
  approval from the previous London day stale, so Leo is `1 of 4`.
  The file is shared (`app/test/core/**`) and RULES §1 forbids the screen
  agent from editing it; it is filed **blocking** as `SHARED_REQUEST.md` §8
  with the one-line fix. The build stage flagged the same item (its verdict
  is FAIL for this reason), so the loop will hand it to the orchestrator
  before the next build.

Still awaiting an orchestrator ruling (`SHARED_REQUEST.md` §9, non-blocking):
whether the approvals banner should also be period-scoped — it deliberately
counts every family-wide `done_pending` completion so it matches P11. The
current unscoped behaviour is pinned by the P08-B06 proof; no test was added
either way so the ruling stays free to land.

Notes / limits (unchanged from iteration 2): P08b visual polish beyond
DESIGN_SPEC §5 belongs to the P08b loop; the Rive still-frame contract is
owned by the shared `test/pip_avatar_test.dart` (the runtime never binds
under `flutter test`); stale `errorMessage` after a retry is cosmetic only.

VERDICT: PASS
