# Fix list after iteration 1

## From 4_review.md

## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 1)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_1.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_1.png` (1170x2532). Same with `dark` -> `app_dark_1.png`.
- NOTE: both runs printed `WARNING — frame never stabilised in 25 s` and exited 1; the saved last-capture frames are still usable. Also NOTE: `shot.sh` does `cd "$APP_DIR"`, so a relative `<out>` resolves under `app/`; absolute OUT paths were used.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_1.png docs/screens/K03/ui/cmp_light_1.png` (and dark).

Results:
- light mean diff: 11.74% — bands: 0 (0-105) 2.73% · 1 (105-211) 5.56% · 2 (211-316) 11.17% · 3 (316-422) 4.96% · 4 (422-527) 12.53% · 5 (527-633) 22.74% · 6 (633-738) 25.27% · 7 (738-844) 8.97%
- dark mean diff: 10.89% — bands: 0: 2.71% · 1: 5.04% · 2: 9.47% · 3: 4.74% · 4: 13.00% · 5: 20.22% · 6: 23.50% · 7: 8.52%
- Read: `cmp_light_1.png`, `cmp_dark_1.png` (design | app | diff). All logical px (PNG/3). Tolerance ±2px.

Accepted (per `1_plan.md` §g + `SHARED_REQUEST.md`, NOT deviations):
- A1 counts copy: design "3 done today" / "3 of 6 done" / 50% bar vs app "4 done today" / "4 of 6 done" / ~66.7% bar. Demo DB yields done=4 (bins+hoover approved, dishwasher+table done_pending); live counts win, no seed fork (RULES §4).
- A2 quest icon tiles: design tints per quest (sky-tint dishwasher, lilac-tint reading) vs app `surface2` for all. Known `NestKidQuestCard` limitation, SHARED_REQUEST #1 filed, non-blocking. Measured light tile: design (230,239,254) vs app (243,238,229).

Deviations (design value → app value + fix):
1. Meadow/background band missing behind lower content (major, both themes). Design light: pale green from y≈524 to y≈717 at x=10 (e.g. (231,246,222) at y=550) behind progress bar + quest cards; home strip green. App light: sky blue at same rows ((230,244,255) at y=550); green only below the dock (e.g. (191,232,176) at y=830). Dark: design teal band behind progress/cards vs app navy. Fix: reconcile `KidScope` meadow hill (spec 390x136 pinned bottom) with the PNG green band (524-717, ~194px); check scroll transparency over the hill, hill height/offset, and the baked `hill-front` colour (SPACING §9.14).
2. Pet-stage → hearts vertical gap ~30px too tall (major). Yellow-heart rows at x=30: design y 443-452 vs app y 471-485; section-title dark text: design y≈490+ vs app y≈520+ (≈30px shift, bands 2/4/5/6). Consequence: design shows 2nd card ("Reading – 20 minutes", +10 pill, check top) while app shows only its top edge. Fix: match HTML `.k3-pet` (260x236, pip 152 at bottom 96, margin 14 top) + `NestPetStage` bottom padding so hearts sit ≈30px higher.
3. Pip/nest scale + position drift (moderate). Diff heat-map shows a strong red outline around Pip + nest in both themes; app Pip renders larger/higher than the PNG 152px pip on the 260x236 nest. Fix: check `NestPetStage` still-frame (`DISABLE_ANIMATIONS=1` SVG path) geometry/scale vs HTML `.k3-pet .pip`/`.nest`.
4. Dark pet glow mismatch (minor). App dark shows a lighter-navy circle behind Pip/nest (≈230px glow, SPACING §7 `white@10%`); design dark PNG is flat navy with no circle. App follows the spec, PNG omits it — flag for orchestrator to rule which wins; listed as a deviation vs the PNG either way.
5. Filled-hearts stroke (minor). HTML l.57: filled hearts `fill coin + 2px ink-2 stroke`, 26px, gap 8; empty `surface-2/ink-3`. App filled hearts render solid coin with little/no visible outline and look larger (15 rows vs 10 in the scan). Fix: match the 2px `ink-2` stroke on filled hearts.
6. Quest-card title size (minor, pre-declared). HTML/SPACING: Nunito 18/24 w800; app renders ≈1px smaller (≈17/22 per `1_plan.md` §f). Shared-component token; builder cannot fix locally — noted.
7. Dock icons glyph + light-theme fg (minor). HTML: 24px outline set (speech-bubble Pip, bag, jar); app: `NestIcons.pipFace/bag/jar` at 26px (plan accepts 26) — recognisable but different drawings. In light, design Pip/My-jar icons read white on coloured buttons while the app's read dark. Fix: verify `NestKidButton` IconTheme fg (`on-accent`/`on-leaf`) in light theme.
8. Status-bar double render (capture artifact, informational, band 0 ≈2.7%). Native simulator time ("00:39"/"00:42") + status icons overlap the mock `NestStatusBar` "9:41". Harness artifact of `simctl screenshot`, not app code; excluded from verdict.

Otherwise correct: header (`k3-top` pad 4/20/10, s64 lilac avatar, 22/26 w900 name, 15/20 sub, 120 coin pill, 56 r18 lock), speech bubble (surface, 3px ink border, r18, tail), "Today's quests" 28/34 + `kchip` style, kid progress (h16, 2px ink border, leaf fill + gloss), card geometry (min-h 72, pad 12, r24, 3px ink border, kid shadow, 56 checks, "Waiting for Mum" chip), dock layout (surface, 3px top border, pad 12/20/10, 3x min-h 66 17/20 buttons; dark token colours correct), home pill (134x5), no horizontal overflow, no bad ellipsis, coins-only (no £), dark-mode tokens correct elsewhere.

Iteration-2 fixes (local): #1 meadow band, #2 pet→hearts gap, #3 Pip scale, #5 heart stroke, #7 dock icon fg. Shared/pre-declared: tile tint + title size (filed/noted).


## From 6_bugs.md
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

