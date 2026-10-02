# K03 Kid home — build notes (Stage 2, iteration 1)

Implemented per `docs/screens/K03/1_plan.md`. Placeholder replaced with the
real kid home: greeting header, Pip stage, happiness hearts, today's quests
with live counts, and the Pip/Shop/My jar dock.

## Files changed (all inside RULES §1)

- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` — added
  `child`, `actionError`, `doneCount`/`totalCount`/`fraction` getters,
  `copyWithLoaded` (explicit constructor so a null child clears).
- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart` — added
  `KidHomeQuestCompleted({childId, questId, coins})`.
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart` — load
  subscribes `combineLatest2(watchActiveChild, watchItems)` via `emit.forEach`
  (read-only `core/data/stream_combine.dart` import); completion calls
  `repo.completeQuest`, failures set `actionError`. No new repo methods.
- `app/lib/features/kid_home/presentation/widgets/kid_status_chip.dart` — new
  feature-private `.kchip` (h32, leafTint/leafInk, Nunito 800 15/15).
- `app/lib/features/kid_home/presentation/views/kid_home_view.dart` — full
  K03 layout per plan §(a): `KidScope` > transparent `Scaffold` > status bar,
  header (avatar s64 mapped from `avatarColour`, `.k3-name`/`.k3-sub` via
  `GoogleFonts.nunito` + tokens, `NestCoinPill`, `NestLockButton` large with
  label 'Grown-ups'), scroll (pet stage idle + speech, hearts, section +
  count chip, kid `NestProgress`, repo-order cards), dock (3 vertical
  `NestKidButton`: lilac Pip / coin Shop / leaf My jar), home indicator.
  Navigation per §(c): card body `push` detail, to_do check adds the event +
  `push` complete, done checks non-interactive, dock `go` pip/shop/jar, lock
  `push` gate. Loading/failure/empty-child/empty-quests states per §(d);
  `actionError` keeps the list + SnackBar.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — blocTest with fake
  repo: load (Maya, 6 items, 4/6, fraction ≈ 0.667), failure sets
  `errorMessage`, completion calls `completeQuest('maya','q-reading')`,
  null child clears.
- `app/test/features/kid_home/kid_home_view_test.dart` — `setUpTestScope`
  + `pumpAppRoute('/kid-home')`, ends with `disposeApp`: light content
  (6 `NestKidQuestCard`, 'Waiting for Mum' ×2, 'Done' ×2, '+10'/'+15'),
  dark pumps, all 6 navigations assert destination placeholder titles,
  320-wide + 1.3 scaler overflow/semantics check.
- `docs/screens/K03/SHARED_REQUEST.md` — two non-blocking items (tile tint,
  stale "3 of 6" copy).

## Fix items from the plan

- Counts render live (4 of 6 under demo), not the stale PNG "3 of 6" — §(g.2).
- Card order is repo (alphabetical) order, not PNG sample order.
- Icon tile stays `surface2` (accepted drift, §(g.1)); title 17/22 per the
  component; dock icons 26 per `IconTheme`.
- No `NestKidButton.white/.lilac` named constructors exist — used
  `NestKidButton(label:, color: white/lilac)` instead.
- `NestLockButton` default is already `large: true`; `NestStatusBar`
  default `time: '9:41'`; `NestKidButton` default `color: leaf`;
  `NestPetStage` default `mood: idle` — omitted as redundant (lint).
- `context.push` futures wrapped in `unawaited` (lint `discarded_futures`).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` — `No issues found!`
- `flutter test` — all 301 tests pass (14 new K03 tests included).

Tail of `flutter test`: `00:06 +301: All tests passed!`

VERDICT: PASS
