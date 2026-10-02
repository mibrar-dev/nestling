# P08 · Today (home) — test notes (Stage 3, iteration 4 — final loop iteration)

Screen: `P08` · route `/today` (+ `P08b` `/today-empty`) · feature `today` ·
mode parent · seeds `Seed.demo()` / `Seed.empty()`.
Scope of this stage: tests only — **no screen code was changed**.

## 1. Focus of this iteration — the two behaviour changes iteration 4 shipped

The orchestrator fixed the shared red with a **seed** change (`e972b46`: Leo's
daily school-bag approval happens on the story day), so `repositories_test`
and P08 agree again and Leo is `2 of 4` again. The build then shipped two
mechanisms that this stage verifies independently:

- **P08-B13 — period-scoped banner.** `watchPendingCount()` now applies
  `countsForCurrentPeriod(rule ?? 'once', createdAt, now)` to
  `done_pending` completions, so a stale approval no longer inflates the
  banner (`today_repository_impl.dart:115-140`). The build's proofs cover
  "one stale extra pending"; my tests cover the magnitudes around it.
- **P08-B14 — per-frame push guard.** `_PushOnce` was rewritten from
  clear-on-pop to `_armed` + `addPostFrameCallback`, because the old latch
  stuck when a pushed page navigated away with `go('/today')`
  (`today_loaded_body.dart:254-269`). The build proves the latch releases;
  my tests prove the two properties that make the frame guard safe.

## 2. Tests added this iteration — 7 new (feature suite 99 → 106)

`today_repository_test.dart` (+3, group `TodayRepository streams`):

- `watchPendingCount: every stale pending drops the total to zero` — live
  stream, all three seeded approvals moved to 2 Oct 22:30 UTC (23:30 London,
  previous London day) → count 0 **and** no row is `done_pending`, so banner
  and rows cannot disagree.
- `watchPendingCount: one stale seeded pending drops the total by one` — 3 → 2
  and the same quest's row reads `to_do`.
- `watchPendingCount: a pending on a deactivated quest still counts` — pins
  the documented `rule ?? 'once'` fallback: archiving the quest removes its
  Today row but must not silently drop an approval P11 still lists.

`today_view_test.dart` (+4):

- `every pending stale: banner gone and the counts agree` — no banner, no
  `Review`, no `Needs a look`, and the cards read `2 of 6` (Maya: this week's
  weekly approvals) and `1 of 4` (Leo: the story-day daily approval).
- `a later tap cannot stack a second editor` — after the editor is pushed,
  the row is behind the opaque route, so a tap in a *later frame* cannot
  reach it; one pop lands back on Today. This is the safety argument for a
  per-frame guard (a human double-tap can only land in the same frame).
- `the guard does not latch after a normal pop` — pop, then tap the same row
  again: the editor opens a second time.
- `the empty-state card shares the same gutters` — P08b's card and greeting
  use the same 20/370 column as the loaded screen (owner alignment rule).

Also corrected two stale test *names* left by the seed change (`Leo 1/4` →
`Leo 2/4`) and marked the superseded duplicate section in
`SHARED_REQUEST.md` so the resolved shared red is not read as open.

## 3. Audit of the changed code (no findings)

- `watchPendingCount()` reads the clock once per emission ✓, treats an
  unknown quest as `once` ✓ (tested), keeps counting "Anyone"-quest
  approvals ✓ (P08-B06 proof still green), and re-emits live ✓.
- `_PushOnce` cannot latch: `_armed` is re-armed in a post-frame callback,
  and by that frame the pushed page covers the button; a rejected/failed
  push also recovers. Tested for the same-frame double tap (P08-B12), the
  later-frame tap, the normal pop and the `go`-replace latch (P08-B14).
- Observation (not a bug, for review/UI): the banner counts *completions*,
  so a quest completed twice in one day reads "2 quests waiting" while
  Today shows one row — coherent with P11, which also lists one card per
  completion; the wording is Stage 4/5 copy territory.

## 4. Coverage vs the stage checklist (all re-run green)

bloc/state paths (12) · light+dark · widths 320/390/430 · scales 1.0/1.3 (12-case
matrix) · empty/loading/error (`Seed.demo` + `Seed.empty`, mock repo for the
impossible-from-DB states) · every tap → right route incl. `questId`/`childId`
params and back-navigation · semantics labels on icon buttons + banner
announced once · tap targets ≥ 44 parent (≥ 56 kid N/A: parent mode, route
gated to P17) · Pip rule per child from the DB, no v1 SVG, Reduce-Motion art ·
period ruling incl. London day/week boundaries and the BST→GMT switch ·
owner alignment + bottom-edge (light and dark).

## 5. Results

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | `351 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test test/features/today` | **106 passed, 0 failed, 0 skipped** (12 bloc · 23 repo · 50 view · 21 bug proofs) |
| `flutter test` (full app) | **+479, all passed** — the shared seed-contract red is gone (`e972b46`); `SHARED_REQUEST.md` §8 closed |

## 6. Bugs found this iteration

**None.** Every mechanism this stage exercised behaves as specified; the
whole app suite is green for the first time in the loop.

Open items are shared and already filed (not P08-owned, none blocking this
screen): `SHARED_REQUEST.md` §2 core card semantics, §4 `push` contract with
P09/P11, §6 `DISABLE_ANIMATIONS` flag (still blocks deterministic
`screenshot frames), §7 quest-meta `runSpacing`, §9 P11 must apply the same
period scoping as P08's banner (P08 is done and proved; until P11 follows,
the two screens can disagree the other way), §10 Bolt/Storybook still-art
coverage, §11 period rollover re-evaluation for an app left open overnight.

VERDICT: PASS
