# P08 · Today (home) — build notes (Stage 2, iteration 2)

Built per `1_plan.md` + every item in `FIXES_1.md` + `ORCHESTRATOR_NOTES.md`
(all 4 mandatory items). The 11 skipped proofs in `p08_bugs_test.dart` are
unskipped and pass; the 4 suite reds from iteration 1 are green.

## Files changed (all RULES §1-legal)

Lib (`app/lib/features/today/**`):

- `domain/entities/today_item.dart` — **dropped `detail`** (B13/C7: dead
  second source of status copy; the view's `todayStatusLabel` is the one
  mapper). Gained nothing; `repeatRule`/`iconKey` kept.
- `domain/entities/child_day_summary.dart` — added `pipStyle`/`pipSkin`/
  `pipAccessory` (defaults mochi/sunny/none) for `PipAvatar` (B02).
- `domain/today_repository.dart` — added `watchPendingCount()` (B06).
- `data/today_repository_impl.dart` — `rows()` sorts by **(statusRank,
  title)** with done_pending 0 / to_do 1 / not_yet 2 / approved 3 (B11/B10);
  `watchSummaries()` builds from **all** children (B04: zero-quest children
  get `0 of 6`-style cards — `0 of 0 quests`) and carries pip fields;
  `watchPendingCount()` counts family-wide `done_pending` (B06, same set P11
  lists); dropped `_statusLabel`; `import package:drift/drift.dart` (house
  pattern, needed for `&`).
- `data/models/today_item_model.dart` — `detail` removed from ctor/json.
- `presentation/bloc/today_bloc.dart` — `pendingCount` from
  `watchPendingCount()` (B06); `happyWeekLabel()` plural helper (B5);
  combined stream transformed by `_closeOnError` (first error forwarded,
  then close) so a failed load releases its watchers and retry starts fresh
  (B14/B08). Raw message stays in state for logs/tests.
- `presentation/widgets/today_loaded_body.dart` —
  - `todayPendingLabel()` singular/plural (B4), used by visible text;
    banner `Semantics` keeps `liveRegion` but drops the duplicating explicit
    label (B10/C5).
  - `todayBannerSubtitle()` from state nicknames: `Maya and Leo did
    brilliantly yesterday` (B3, orchestrator note 2).
  - Greeting `fontWeight w900 + letterSpacing -0.22` on the token style (B9).
  - Quest gaps `i == 0 ? s2 : s4` (B2).
  - `_KidsGrid` chunks pairs; lone card gets `Row[Expanded, Spacer]` so one
    child keeps the 170 column (B6/B05/B09).
  - `_KidCard` renders each child's own `PipAvatar(style/skin/accessory,
    clamped stage, size 72)` in the design slot (orchestrator note 1, B02);
    v1 `pipStageAsset` helper deleted; `pipStageName` kept for the semantics
    label. `PipAvatar` handles the still frame itself (`DISABLE_ANIMATIONS`/
    `MediaQuery.disableAnimations`).
  - `_GroupLabel` → `NestSectionLabel` (B12, restores `header: true`).
  - `push` for `/approvals` + `/quest-editor` (±`questId`, incl. P08b `Add a
    quest`); `go` kept for shell destinations and `/who-is-playing` (B07);
    coordination note filed as `SHARED_REQUEST.md` §4.
  - Hand-off 3+ copy → `Hand to Maya and 2 others` (B20/C12).
  - P08b art → `PipAvatar(mochi, stage 1, 140)` (B03; `skin` omitted — sunny
    is the default and the lint forbids redundant args).
  - `TodayFailureBody` renders a fixed kind string; raw error stays in state
    (B15/C8).
- `presentation/views/today_view.dart`, `today_empty_view.dart` — failure
  branch is now `const TodayFailureBody()`.

Tests (`app/test/features/today/**`): unskipped all 11 proofs (B01 passes
as-is — guard already on main; B07's path assertion now reads the pushed
page's `GoRouterState.uri` because `currentConfiguration` keeps reporting
the shell branch after a `push` — same method the navigation tests use, see
2_build note); new repo tests (no-quest child summary, family-wide pending
count); updated stale expectations (dishwasher `daily` per seed `e94d063`,
status-order list, `_expectedDateLine` plural, friendly-copy assertions,
`watchPendingCount` stubs on every mock, pending-controller rework of the
re-emission test, scroll loops follow render order). `detail` references
removed.

## Fix-item ledger (FIXES_1 refs)

Review B1–B8 + UI 1–6 + bugs B01–B10 + carried C1–C15: **all fixed except**
C9/B16 (balance substitution — accepted, note only), C10/B17 (liveRegion
re-announce on unrelated emissions — kept `liveRegion`, minor, deferred),
C11/B21 (P08b divergences — that loop's scope), C13 second half (shared
`NestCard` semantics — `SHARED_REQUEST.md` §2 stays open), C14/B22 (doc —
`SHARED_REQUEST.md` §5), B18 (shared runSpacing — new §7). B19 needed no
filing (seed `e94d063` resolved it). **New shared bug found: §6**
(`DISABLE_ANIMATIONS=1` never parses to `true`, so `shot.sh` frames never
stabilise once Rive widgets are on screen — see below).

## Verification tails

- `dart format .` → `Formatted 344 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app).
- `flutter test test/features/today` → `All tests passed!` (+65: 52 + 11
  proofs + 2 new repo tests).
- `flutter test` (full) → `All tests passed!` (+372).
- `shot.sh` light + dark + empty from final sources (all newer than the
  sources; all three read back). Each run warns `frame never stabilised in
  25 s` — caused by shared §6 (Rive idle loop runs because the flag parses
  to false), not by this screen: captures are complete and correct.
- `compare.py` vs design PNGs: light mean **5.22 %** (was 6.66),
  dark **4.85 %**. Residual is data-driven, not spacing: live date
  (`Fri 2 Oct` vs mock `Sat 4 Oct`), seed repeats (`· Daily` vs mock's mixed
  labels — DB is correct per DATA OVER MOCKS), all 10 real rows vs the
  mock's 5, banner balance-wrap. Dark: zero theme branches, all tokens flip
  (banner, cards, pills, chips, progress). Status bar ignored per rules.

VERDICT: PASS
