# K03 Kid home — bug hunt (Stage 6, iteration 1)

Adversarial pass over `kid_home` K03: data edges, rapid double taps, back
navigation, deep links, restart persistence, mode guards, dark contrast,
320px + 1.3 text scale, async gaps, Europe/London day boundaries and integer
money. No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` (20 tests: 11 probes
  pass, 9 bug proofs skipped so `flutter test` stays green).
- Run the proofs: `cd app && flutter test --run-skipped --plain-name "K03-BUG"`.
- Every proof below fails on the current code for the reason stated.
- Environment: demo seed (`Seed.demo`), in-memory Drift (bug 1/4) and
  file-backed Drift (persistence probe).

## Bugs (numbered, severity)

### K03-BUG-1 — Rapid double tap writes a duplicate pending completion

**Severity: Major (data integrity).**
Where: `kid_home > data/kid_home_repository_impl.dart` `completeQuest()`
(no transaction, no latest-status guard) and
`presentation/views/kid_home_view.dart` `_QuestCard._complete()` (no
debounce; the route push does not disable the check in the same frame).

Repro (widget): open `/kid-home` (kid mode, demo), scroll to a to_do card,
tap the round check twice inside one frame (a genuine fast double tap).
Repro (repo): `completeQuest('maya', 'q-reading')` twice in a row.

Actual: two `done_pending` rows for the same quest/child are written. The
first call flips the seeded `to_do` row; the second call sees the latest
status as `done_pending`, skips the update branch and **inserts a new row**
(`completeQuest` has an else-insert for any non-to_do/not_yet latest status).
Read-back evidence: `id: 7` and `id: 13`, both `done_pending`, same second.

Impact: `watchPendingApprovals` now returns 4 items for a family the spec
seeds with 3; P11 lists the same quest twice; `ApprovalsRepositoryImpl`
`.approve()` treats every row as a distinct completion and inserts a second
`quest_bonus` ledger entry, so double approval pays the child twice.
`approveAll()` compounds it. UI guards (`done_pending` check becomes
inactive) only help after the stream round-trips, which is longer than a
double tap.

Failing tests:
- `K03-BUG-1 repo: second completeQuest after done_pending creates a duplicate row`
- `K03-BUG-1 widget: double-tapping the check creates two pending rows`

Suggested fix (feature-local): make `completeQuest` idempotent inside a
`transaction`: read the latest completion for (quest, child); if it is
`to_do`/`not_yet` update it, if it is `done_pending`/`approved` return
without writing. In the view, disable the check the moment it is tapped
(local `_completing` flag/bloc `completingQuestId`) so the second tap is a
no-op even before the stream re-emits. A DB uniqueness constraint on
(quest_id, child_id, day) would be a stronger shared-layer fix (schema →
SHARED_REQUEST).

### K03-BUG-2 — The celebration opens even when the completion write fails

**Severity: Moderate.**
Where: `kid_home_view.dart` `_QuestCard._complete()` — `bloc.add(...)` then
`unawaited(context.push(/quest-complete))`, unconditionally and without
waiting for the write.

Repro: use a repository whose `completeQuest` throws (or stop the DB). Tap a
to_do check.

Actual: `/quest-complete` (K05) opens, so the child is celebrated for a
quest the database never recorded; the "Hmm, that did not work." SnackBar
fires over the celebration, and after back navigation the card is still
to_do. Same shape if the quest row was deleted while the list was stale:
`completeQuest` silently `return`s when the quest does not exist, so there
is not even an `actionError`.

Failing test:
- `K03-BUG-2: a failed completion still opens the celebration`
  (expects `K05 Quest complete` absent; found one).

Suggested fix: drive navigation from success. Have the
`KidHomeQuestCompleted` handler emit a `justCompletedQuestId` (cleared on
the next load/stream emission) and a `BlocListener` push `/quest-complete`
only for that value; on failure keep the list and show the SnackBar as
today.

### K03-BUG-3 — A second identical completion failure is never announced

**Severity: Minor.**
Where: `kid_home_state.dart` `copyWith` keeps `actionError ?? this.actionError`
(write-only) and the view listens for `previous.actionError != current.actionError`.

Repro: two completion attempts fail with the same error string (e.g. both
`Exception: save failed`) before any reload.

Actual: the first failure emits `actionError`; the second `copyWith` produces
an equatable-equal state, so `bloc.emit` swallows it and the BlocListener
never fires again. The child/parent gets no feedback on the second attempt.

Failing test:
- `K03-BUG-3: state keeps the first actionError forever so a second identical failure is not announced`
  (collects 1 error state, expects 2).

Suggested fix: clear `actionError` when a new completion starts, or give it
a `errorNonce`/counter so every failure is a distinct state. `copyWithLoaded`
should also clear it once the stream is healthy (stage 3 noted this already).

### K03-BUG-4 — "Done today" never resets at the London day boundary

**Severity: Moderate (screen claim vs data semantics).**
Where: `kid_home_state.dart` `doneCount` (status-only) and
`kid_home_repository_impl.dart` `watchItems()` (latest completion of any age),
which ignore dates entirely; `kid_home_view.dart` renders "X done today",
"X of Y done" and the progress bar from it.

Repro: remove completions, insert one `approved` completion for a quest
whose `createdAt` is 30 hours ago (always a previous Europe/London day), open
`/kid-home`.

Actual: header says "1 done today" (and the bar advances). Nothing in the
query or state consults `london_time.dart`, `repeatRule` or the current day,
so on any later day yesterday's approvals (and even last week's) still count
as done today. There is no daily reset path anywhere in the app; midnight or
the BST↔GMT switch (25 Oct 2026 01:00 UTC) does not change what the child is
shown.

Failing test:
- `K03-BUG-4: a completion from a previous London day still reads as done today`
  (expects `0 done today`; finds `1 done today`).

Suggested fix: decide the semantics with the foundation (quest model lives
in `core/data`). Either (a) scope kid status to the current London day:
`watchItems` returns the latest completion *created on the current London
day* (or none → `to_do`) and K03's counts stay a pure projection; or
(b) if per-quest-latest is intended, stop claiming "today" in the header,
chip and progress semantics. (a) matches the K03 design copy and daily
quests; because `TodayRepositoryImpl` uses the same status model, file the
ruling as a SHARED_REQUEST if it is not screen-local.

### K03-BUG-5 — Kid-mode parental guard misses parent routes

**Severity: Moderate (guard bypass; shared router).**
Where: `app/lib/app/router.dart` `parentOnly` — matches `/today` exactly and
`/today/` prefixes only; later parent routes were never added.
`/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` are
reachable in kid mode.

Repro: `APP_MODE=kid` (or `AppModeController.selectMode(AppMode.kid)`) and
deep-link `/today-empty` or `/quest-editor`.

Actual: the parent placeholder screen renders; no redirect to
`/parental-gate`. The same list does block `/today`, `/settings`, etc., so
this is an omission, not a design decision.

Failing tests:
- `K03-BUG-5: kid mode can deep-link to /today-empty without the gate`
- `K03-BUG-5: kid mode can deep-link to /quest-editor without the gate`
  (both expect `currentPath == '/parental-gate'`; get the parent route).

Suggested fix (shared, cannot be fixed in the feature — file
SHARED_REQUEST): route metadata (`GoRoute`-level `parentOnly` flag) instead
of a prefix list, or extend the list with `/today-empty`, `/quest-editor`,
`/add-children`, `/pocket-money-setup` and add a router test enumerating
every parent path so future screens cannot silently miss the guard.

### K03-BUG-6 — Double tap stacks duplicate navigation routes

**Severity: Minor (UX / back-stack).**
Where: `kid_home_view.dart` `_QuestCard._openDetail()` / `_complete()` —
every tap pushes; nothing debounces.

Repro: fast double-tap a quest card body, or the check, without a frame in
between.

Actual: two `/quest-detail` (or two `/quest-complete`) routes are pushed.
One back press returns to the *second* copy, not to `/kid-home`. A child
must press back twice; on the celebration flow this reads as the app
"not going back".

Failing tests:
- `K03-BUG-6: double-tapping a quest card stacks two detail routes`
- `K03-BUG-6: double-tapping the check stacks two celebration routes`
  (after one `pageBack()`, `Hi Maya!` is not found).

Suggested fix: same guard as BUG-1/2 — a per-card pending flag (or
`context.push` gated on a `_navigating` bool plus `isCurrent` route check)
so only one route can be pushed per gesture burst.

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| 0 children | deep link `/kid-home` with `Seed.empty` → "Who's playing?" + Choose | pass |
| 1 child | family with Leo removed still renders Maya 4/6 | pass |
| 6 children | adding 4 children does not change the home | pass |
| long UK name | "Maximilian-Alexander" at 320px / scale 1.3, no overflow | pass |
| 9999 coins | coin pill renders, no overflow | pass |
| £0.00 / £999.99 | K03 shows coins only (`+0` for a zero-coin quest, no `£` anywhere) | pass |
| empty lists | empty-quests state covered by stage 3 | pass (existing) |
| back navigation | check → K05 → back returns to the home with the card flipped to "Waiting for Mum" | pass |
| deep links | `/kid-home` direct in kid mode rehydrates the active child from `app_state` | pass |
| restart | Drift file DB closed and reopened: completion still `done_pending` | pass |
| mode guard | kid mode → `/today` still redirects to `/parental-gate` | pass |
| dark contrast | 16 K03 token pairs (ink/ink2/coin/leaf/chip/buttons, sky + surface) ≥ 4.5:1 both themes | pass |
| 320 + 1.3 | matrix covered in stage 3; edge-data variant here | pass |
| async gap | late `completeQuest` failure after `bloc.close()` does not throw (bloc 9 ignores post-close emits) | pass |
| timezone | `london_time.dart` BST boundaries are correct (Oct switch 01:00 UTC); K03 itself does no time math | pass (see BUG-4) |
| money rounding | no pence arithmetic on this screen; all amounts integer coins | pass |

## Observations (checked, not raised as bugs)

1. Parent mode can deep-link to `/kid-home` and see the kid home. The
   DESIGN_SPEC guard is one-way (kid → parent/gate); no spec line requires a
   gate on kid routes and there is no in-app path from parent mode. Kept as
   an observation until the deep-link/product pass decides.
2. `/kid-home` in kid mode does not require the K02 PIN. K01/K02 are still
   placeholders owned by other K screens, so there is no PIN state to
   enforce yet; needs a family-feature ruling, not a K03 fix.
3. Leo's quests `paw`/`bag`/`leaf` fall back to the generic quest-card glyph
   (`_iconFor` map). The fallback is per plan (K03 design shows Maya only);
   `NestIcons.paw`/`bag` exist if the loop later wants the richer map.
4. `completeQuest` does not check that the quest is assigned to `childId`
   (only reachable via crafted extras into K04, which is a placeholder). The
   UI never produces a mismatched pair.

## Summary

| ID | Severity | Area | Fixable in K03 feature? |
|---|---|---|---|
| K03-BUG-1 | Major | duplicate pending completions / double payout | yes (repo + view) |
| K03-BUG-2 | Moderate | celebration before successful save | yes (view + bloc) |
| K03-BUG-3 | Minor | swallowed repeat failure feedback | yes (state/bloc) |
| K03-BUG-4 | Moderate | "done today" day-boundary semantics | partly (needs foundation ruling) |
| K03-BUG-5 | Moderate | kid-mode guard misses parent routes | no (shared router → SHARED_REQUEST) |
| K03-BUG-6 | Minor | stacked duplicate routes on double tap | yes (view) |

One major bug (K03-BUG-1, duplicate completion rows → duplicate approvals
and ledger entries) is proven and reproducible with a real double tap.
Iteration 2 needs to fix at least BUG-1/2/6 and re-run the skipped proofs
(`flutter test --run-skipped`) to green.

VERDICT: FAIL
