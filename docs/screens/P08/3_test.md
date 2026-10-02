# P08 · Today (home) — test notes (Stage 3, iteration 2)

Screen: `P08` · route `/today` (+ `P08b` `/today-empty`) · feature `today` ·
mode parent · seeds `Seed.demo()` / `Seed.empty()`.
Scope of this stage: tests only — **no screen code was changed**.

## 1. Iteration-1 findings — re-verified closed

| Iter-1 finding | Status | Proof in this suite |
|---|---|---|
| **B1** banner `"1 quests"` | fixed (`todayPendingLabel`) | `P08 Today copy one pending approval reads "1 quest"`, helper test `pending label pluralises` (0/1/3) |
| **B2** header `"Happy week: 1 days"` | fixed (`happyWeekLabel`) | `date line uses the singular "1 day"`, helper test `happyWeekLabel singular / plural` |
| **B3** banner subtitle generic vs design names | fixed (`todayBannerSubtitle` from state) | `banner subtitle names the children`, helper test `banner subtitle names 0 / 1 / 2 / 3+ children`, plus the 3-/1-child widget tests |
| **B4a** banner semantics double-announced | fixed (liveRegion without duplicate label) | `the banner announces its copy exactly once` (node label contains the pending line once) |
| **B4b** core `NestCard`/`NestQuestCard` double-announce | carried — shared files, `SHARED_REQUEST.md` §2 (non-blocking) | not a P08-owned bug; still recorded |
| 11 skipped stage-6 proofs | all unskipped and passing | `p08_bugs_test.dart` (no `skip:` anywhere in `app/test/features/today/`) |

## 2. Tests added this iteration — 15 new (feature suite 65 → 80)

`today_view_test.dart` (+11):

- `P08 Today copy helpers` — `todayPendingLabel` 0/1/3; `todayBannerSubtitle`
  for 0, 1, 2 and 3 children; every Pip token → enum (`mochi`/`bolt`/
  `storybook`, all four skins, all five accessories) + safe fallbacks.
- `P08 Today Pip artwork (orchestrator rule)` — each kid card renders
  `PipAvatar` with the child's DB fields (Maya mochi·sunny·3, Leo
  bolt·sky·2), at the design's 72 px slot; **no v1 `pip_stage_*.svg`** is
  rendered and any Pip SVG that does load is `pip_v2`; P08b empty card is
  `PipAvatar(mochi, stage 1)` at 140; a non-default child
  (storybook·mint·scarf·stage 4) travels DB → card unchanged.
- `P08 Today family-size copy` — 3 children: `"Maya, Leo and Sam did
  brilliantly yesterday"` + `"Hand to Maya and 2 others"`; 1 child:
  `"Maya did brilliantly yesterday"` + `"Hand to Maya"` + `"2 quests
  waiting…"`.
- `P08 Today a11y regressions` — the banner live-region announces its copy
  exactly once.
- `P08 Today navigation (push)` — system back from the quest editor returns
  to `/today` (the `push` contract; mirrors the approvals proof).
- `P08 Today stress` — 6 children, long quest titles, 320 px @ 1.3×:
  no overflow, hand-off copy `"Hand to Maya and 5 others"`.

`today_repository_test.dart` (+2):

- `not_yet rows sit between to_do and approved` — full render order
  pending → to_do → not_yet → approved, title within rank (newer completion
  wins), on `Seed.demo`.
- `watchPendingCount re-emits when a new approval arrives` — same
  subscription sees 3 → 4 after an “Anyone”-quest approval (family-wide set,
  identical filter to P11's `watchPendingApprovals` — verified in
  `app_database.dart:315`).

`today_bloc_test.dart` (+2):

- `pendingCount is the family-wide count, not the visible rows` (no visible
  items, count 3 → banner still shows).
- `happyWeekLabel` singular/plural unit test.

The stage-2 build also adapted the existing tests to the new APIs
(`detail` dropped, `watchPendingCount` stubs, seed `e94d063` daily/weekly,
pending-first scroll order, friendly failure copy) — reviewed in the diff:
no assertion was weakened, the two copy-bug proofs from iteration 1 were left
intact and now pass.

## 3. Coverage vs the stage checklist

- **bloc_test every event/state path:** single event (`TodayLoadRequested`)
  → loading / loaded / failure / retry / re-emission / family-wide pending;
  every `TodayState` field asserted at least once.
- **Widget tests light + dark, 320/390/430, scale 1.0/1.3:** 12-case matrix
  (no `RenderFlex overflowed`, content reachable, `disposeApp` on every
  widget test) + dark content, dark failure.
- **empty / loading / error:** all three; loading/error drive `TodayView`
  with a mock `TodayRepository` (a healthy in-memory Drift DB cannot fail),
  everything else uses the in-memory DB with `Seed.demo`/`Seed.empty`.
- **every tap navigates to the right route:** Review→`/approvals`,
  `+`→`/quest-editor` (no `questId`), row→`/quest-editor?questId=…`,
  See all→`/quests`, avatar→`/settings`, kid card→
  `/child-profile?childId=…`, Hand→`/who-is-playing`, `Add a quest`→
  `/quest-editor`, `Browse ideas`→`/quests`; pushed pages also prove back
  navigation (approvals + editor).
- **semantics labels on icon buttons:** `New quest`, `"Sarah's profile"`,
  `See all quests` + card/row/Pip/progress labels; kid-mode ≥56 px targets
  do not apply (parent mode; `/today` and `/today-empty` are gated to P17 by
  the shell — `[P08-B01]` proof).

## 4. Results

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | `344 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test test/features/today` | **80 passed, 0 failed, 0 skipped** (12 bloc · 14 repo · 43 view · 11 bug proofs) |
| `flutter test` (full app) | **+387, all passed**, nothing skipped |

## 5. Bugs found this iteration

**None.** The three copy bugs and the banner a11y defect from iteration 1 are
fixed and regression-tested; the iteration-2 screen behaves per the design,
`ORCHESTRATOR_NOTES.md` (all 4 items) and the stage checklist.

Carried shared items (not P08-owned, all in `SHARED_REQUEST.md`):
§2 core card semantics duplication (a11y quality), §4 `push` coordination,
§5 doc, §6 `DISABLE_ANIMATIONS` flag never parsing (affects `shot.sh` frame
stability), §7 quest-meta `runSpacing`.

Notes / limits:

- The still-frame path (`MediaQuery.disableAnimations`) is owned by the shared
  component test `app/test/pip_avatar_test.dart:187`; at the screen level it
  cannot be distinguished under `flutter test` because the Rive runtime never
  binds there (probe: 0 `RiveWidget`s with or without the flag), so no
  screen-level still-frame assertion was added rather than a vacuous one.
- P08b visual polish beyond DESIGN_SPEC §5 P08b (header `"· A fresh nest"`,
  tip card, link styling, longer message, no header actions) is still P08b's
  loop scope, recorded for that plan.
- Stale `errorMessage` surviving a successful retry remains cosmetic only
  (state hygiene, never rendered).

VERDICT: PASS
