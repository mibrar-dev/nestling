# P08 · Today (home) — bug hunt (Stage 6, iteration 1)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seed `demo`/`empty`. **No screen code was changed.** Added
`app/test/features/today/p08_bugs_test.dart` — 11 proofs, every one
`skip`-marked with its bug id so the suite stays green until the fixes land
(run them with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 11
fail against iteration-1 code, by design).

Method: read the feature, the shared data layer, the router and the design
references, then probed every edge class in the brief with throwaway Drift
tests; each finding below is reproduced by a committed failing test.

New findings: **P08-B01 … P08-B10** (7 major, 3 minor) + the carried-over
list. The screen cannot pass: `VERDICT: FAIL`.

## New findings (this stage)

### P08-B01 — kid mode can deep-link into `/today-empty` without the parental gate — MAJOR

- **Where:** `app/lib/app/router.dart` (shared) — the `parentOnly` list has
  `/today` but not `/today-empty`; the matcher only expands `/today/…`, so a
  kid-mode deep link to the P08b route renders the full parent Today body.
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B01]'` → expected `/parental-gate`, actual
  `/today-empty`.
- **Failing test:** `[P08-B01] kid mode cannot deep-link into /today-empty`.
- **Fix:** add `/today-empty` to `parentOnly` (or match on route names rather
  than path prefixes). Shared file → `SHARED_REQUEST.md` §3.

### P08-B02 — kid cards render v1 `pip_stage_*.svg`, not each child's PipAvatar — MAJOR

- **Where:** `today_loaded_body.dart` (`pipStageAsset`, `_KidCard`'s
  `SvgPicture.asset`); `ChildDaySummary` has no pip style/skin/accessory
  fields at all. Violates the mandatory orchestrator rule (products screens
  must use `PipAvatar` with the child's `pip_style / pip_skin /
  pip_accessory / pip_stage`).
- **Repro:** `--run-skipped … --plain-name '[P08-B02]'` → expected 2
  `PipAvatar` (Maya = mochi · sunny · stage 3, Leo = bolt · sky · stage 2),
  actual 0 (two v1 stage SVGs).
- **Failing test:** `[P08-B02] kid cards render each child's own PipAvatar`.
- **Fix (feature-local):** extend `ChildDaySummary` + `watchSummaries()` with
  `pipStyle`/`pipSkin`/`pipAccessory` from `children`, render
  `PipAvatar(style/stage/skin/accessory)` in the same 72×72 centred slot.
  Clamp `stage` to 1..4 (`PipAvatar` asserts) — the DB column has no check.

### P08-B03 — P08b empty card still uses the v1 egg SVG — MAJOR

- **Where:** `today_loaded_body.dart` `_EmptyCard` —
  `SvgPicture.asset(NestlingIllustrations.pipStage1)`. Same mandatory rule:
  never use the v1 `pip_stage_*.svg` in product screens.
- **Repro:** `--run-skipped … --plain-name '[P08-B03]'` with `Seed.empty` →
  expected 1 `PipAvatar` (mochi · sunny · stage 1), actual 0.
- **Failing test:** `[P08-B03] P08b empty state uses PipAvatar (mochi/sunny/1)`.
- **Fix:** `PipAvatar(style: PipStyle.mochi, skin: PipSkin.sunny, stage: 1)`
  at the design's 140×140.

### P08-B04 — children with no assigned quests are invisible on Today — MAJOR

- **Where:** `today_repository_impl.dart` `watchSummaries()` — cards are built
  from `byChild`, a map built from *items*. A child with zero active assigned
  quests (the ordinary state right after P05 "Add a child") never appears in
  `summaries`, so no card, no `NAME · age` group, no hand-off name.
- **Repro:** `--run-skipped … --plain-name '[P08-B04]'` — insert child `Sam`
  with no quests, pump `/today` → expected `find.text('Sam')`, actual none
  (probe measured 0).
- **Failing test:** `[P08-B04] a child with no assigned quests still gets a
  card`.
- **Fix:** build summaries from `watchChildren(familyId)` (all children) and
  attach `done`/`total` from the items; agree the 0-quest copy with design
  ("0 of 0 quests" vs "No quests yet").

### P08-B05 — kids grid is N-up: 3+ children collapse, 5+ children overflow — MAJOR

- **Where:** `today_loaded_body.dart` `_KidsGrid` — one `Row` of `Expanded`
  cards for any child count.
- **Evidence (probes + proofs):**
  - 3 children → all cards on one row: 3 × 110 px; "4 of 6 quests" ellipsises
    to "4 o…" (the number the card exists to show). Distinct card rows: 1 vs
    the design's 2.
  - 6 children → one row of ~50 px cards; each card's interior is 22 px while
    avatar (32) + gap (8) = 40 → **`A RenderFlex overflowed by 18 pixels on
    the right.`** (6 exceptions in one pump).
- **Repro:** `--run-skipped … --plain-name '[P08-B05]'` (two tests).
- **Failing tests:** `[P08-B05] three children keep the 2-up kids grid`,
  `[P08-B05] six children keep the 2-up grid with no overflow`.
- **Fix:** chunk into pairs (Stage 4 B6 snippet) so `.kids` stays the design's
  2 × 170 + gap 10 grid; add the two tests above to the suite.

### P08-B06 — approvals banner undercounts family-wide pending approvals — MAJOR

- **Where:** `today_bloc.dart` `pendingCount = items.where(done_pending)`.
  `items` only contains quests assigned to a child, but P11 (`watchPending
  Approvals(familyId)`) lists every `done_pending` completion — including
  "Anyone" quests. The banner count disagrees with the screen `Review` opens.
- **Repro:** `--run-skipped … --plain-name '[P08-B06]'` — insert a
  `done_pending` completion for the unassigned quest `q-living`, pump
  `/today` → banner expected "4 quests waiting for your thumbs-up", actual
  "3 quests waiting for your thumbs-up".
- **Failing test:** `[P08-B06] banner counts family-wide pending approvals`.
- **Fix:** add `Stream<int> watchPendingCount()` to the repository (COUNT of
  `done_pending` completions for `Seed.familyId`) and use it for
  `pendingCount`; keep `items` for the rows. Do not derive it from per-child
  items (see P08-B04).

### P08-B07 — system back from Review exits the app instead of returning to Today — MAJOR

- **Where:** `today_loaded_body.dart` — Review uses `context.go('/approvals')`;
  `/approvals` is a top-level route and `go` **replaces** the stack, so there
  is nothing to pop. Same for `/quest-editor` (+`?questId`) and P08b's CTAs.
- **Repro:** `--run-skipped … --plain-name '[P08-B07]'` — tap Review, then
  `tester.binding.handlePopRoute()` → expected `true` + `/today`, actual
  `false` and the path stays `/approvals` (probe: Android back / iOS
  swipe-back would exit the app).
- **Failing test:** `[P08-B07] system back from approvals returns to Today`.
- **Fix:** `context.push` for `/approvals` and `/quest-editor` (with and
  without `questId`); keep `go` for shell destinations (`/settings`,
  `/child-profile?childId=`) and the mode switch (`/who-is-playing`). Note in
  `SHARED_REQUEST.md` so P09/P11 return with `context.pop()`.

### P08-B08 — retry after a stream error leaks the failed load's watchers — MINOR

- **Where:** `today_bloc.dart` `emit.forEach(combineLatest2…)` +
  `core/data/stream_combine.dart` (`controller.addError` without close). The
  errored handler never completes, so its subscriptions stay; every "Try
  again" adds another full set of live Drift watchers.
- **Repro:** `--run-skipped … --plain-name '[P08-B08]'` — error an open
  stream, tap Try again → `watchItems` called twice (ok) but the first
  subscription never cancelled: cancels 0, expected 1.
- **Failing test:** `[P08-B08] retry releases the failed load's watchers`.
- **Fix (feature-local):** make the first error terminal before `emit.forEach`
  (`StreamTransformer.fromHandlers`: `sink.addError(e, s); sink.close();`) —
  then the handler completes and cancels; or cancel in `onError`.

### P08-B09 — a single child's card stretches to 350 px, not the design's 170 px column — MINOR

- **Where:** `today_loaded_body.dart` `_KidsGrid` — `if (cards.length == 1)
  return cards.single;`.
- **Repro:** `--run-skipped … --plain-name '[P08-B09]'` — delete Leo, measure
  the remaining kid card → 350.0 px; design `.kids
  {grid-template-columns:170px 170px}` (≤ 175 expected); probe measured
  350.0.
- **Failing test:** `[P08-B09] a single child keeps the 2-up grid card width`.
- **Fix:** pair-chunking alone does not cover the odd count — put the lone
  card in a 2-up row (`Row` + `Expanded` + `Spacer`/`SizedBox(width:170)`).
  If a full-width single card is deliberate, document it in SPACING_SPEC §8
  and close this as a doc deviation instead.

### P08-B10 — quest rows are α-sorted; the design orders pending-first — MINOR

- **Where:** `today_repository_impl.dart` `rows()` — `..sort((a, b) =>
  a.title.compareTo(b.title))`.
- **Repro:** `--run-skipped … --plain-name '[P08-B10]'` — Maya's order is
  `Empty the dishwasher → Hoover the stairs → Lay the table …`; design order
  is done_pending → to_do → approved, which scatters the "Needs a look" rows
  the banner exists to surface.
- **Failing test:** `[P08-B10] quest rows are ordered pending-first like the
  design`.
- **Fix:** sort by `(statusRank, title)` with `done_pending` 0, `to_do` 1,
  `not_yet` 2, `approved` 3, and update `today_repository_test.dart`'s
  α-order assertion in step.

## Carried over from earlier stages (still open)

| Ref | Sev | Item | Where / evidence |
|---|---|---|---|
| C1 | major | Banner "N quests…" + header "Happy week: N days" are not pluralised ("1 quests", "1 days") | `today_loaded_body.dart:361/378`, `today_bloc.dart:59`; 2 suite reds (3_test B1/B2, 4_review B4/B5) |
| C2 | major | Banner subtitle is hard-coded "Your little birds did brilliantly" instead of "Maya and Leo did brilliantly yesterday" built from state | `today_loaded_body.dart:385`; 1 suite red (4_review B3) |
| C3 | major | Quest-row gap is 8 px on every row; spec/plan say 16 px (8 only label→first) | `today_loaded_body.dart:240`; 4_review B2 / 5_ui §3 |
| C4 | minor | Greeting renders Nunito 800, design 900 / −0.22 tracking | `today_loaded_body.dart:288`; 4_review B9 / 5_ui §6 |
| C5 | minor | Banner `Semantics(liveRegion, label:)` duplicates its children in the announced node | `today_loaded_body.dart:359-361`; 3_test B4a / 4_review B10 |
| C6 | minor | `NestSectionLabel` exists but group labels are hand-rolled (loses `header: true`) | `today_loaded_body.dart:566`; 4_review B12 |
| C7 | minor | Dead `TodayItem.detail` + `_statusLabel` (second source of status copy) | `today_repository_impl.dart:121/136`; 4_review B13 |
| C8 | minor | Raw `error.toString()` rendered to the parent | `today_bloc.dart:66` / `today_loaded_body.dart:698`; 4_review B15 |
| C9 | minor | `text-wrap: balance` banner wrap cannot match the mock — accepted substitution, note only | 4_review B16 |
| C10 | minor | `liveRegion` banner re-announces on unrelated stream emissions | `today_loaded_body.dart:360`; 4_review B17 |
| C11 | minor | P08b divergences beyond this screen ID's design refs (header "A fresh nest", long message, "Browse ideas" as a link, "Tip for new nests" card) | 3_test §4; 4_review B21 covers the 36 px inset |
| C12 | minor | Hand-off copy for 3+ children ("Hand to Maya and friends") | `today_loaded_body.dart:630`; 4_review B20 |
| C13 | shared | `NestCard`/`NestQuestCard` semantics duplication + 4 px vs 6 px runSpacing | `SHARED_REQUEST.md` §2; 4_review B18 |
| C14 | doc | DESIGN_SPEC §5 P08 still describes a floating "+ New quest" pill the design does not have | 4_review B22 |
| C15 | test debt | `today_repository_test.dart` asserts `q-dishwasher` repeat `'weekly'`, but the mid-iteration seed merge `e94d063` made it `'daily'` (DATA OVER MOCKS: the DB is right). One suite red — update the expectation (and keep `q-bins`/`q-hoover` `weekly`) in the fix stage. | 4th suite red |

## Checked, no bug found

- **Rapid double taps** — `+`, `Review`, quest rows, Hand: `go` is
  idempotent, one editor page, no exception (probe).
- **State after restart (Drift persistence)** — approve everything, dispose
  the app, relaunch: banner stays hidden, "Approved ✓" persists (probe).
- **Timezone Europe/London / BST** — `toLondon` boundaries (last Sunday
  March/Oct, 01:00 UTC) are correct; P08 renders the live date (Fri 2 Oct
  2026, not the mock's Sat 4 Oct — expected).
- **Long UK names** ("Maximilian-Alexander") at 320 px / 1.3× — no overflow
  (name ellipsises per plan §e).
- **Coins edges** — 9999 coins (kid card + quest pill) and 0-coin quests
  render at 320 / 1.3×; P08 never shows £, so £0.00/£999.99 and integer-pence
  rounding do not apply here.
- **Dark-mode contrast** (computed WCAG ratios): ink/surface 16.5/14.8,
  ink2/paper 8.3/10.8, leaf link/paper 4.6/8.7, coin chip 7.0/9.6, leaf chip
  7.1/8.5, banner subtitle (85 % alpha) 5.0/6.6 — all ≥ 4.5 in both themes.
- **Empty seed at 320 px / 1.3×** — no overflow.
- **Async gaps / emit after close** — bloc 9.2.1 cancels the `forEach`
  subscription when the bloc closes, so P08 has no post-close emission path.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `344 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test` (full) → **+337 −4 ~11**. The −4: C1 ×2, C2 ×1 and C15 ×1
  (the stale seed assertion); the ~11 are this stage's skipped proofs. None
  of the four is caused by this stage (all four reproduce on the unmodified
  working tree).

## Verdict

Seven new major bugs (B01–B07) — a guard bypass, a mandatory Pip-rule
violation on both surfaces, invisible children, a collapsed/overflowing kids
grid, an approvals count that lies, and back navigation that exits the app —
plus B08–B10 and the 15 carried items. No PASS is possible.

VERDICT: FAIL
