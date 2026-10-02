# Fix list after iteration 2

## From 4_review.md
# P08 · Today (home) — QA code review (Stage 4, **iteration 2**)

Route `/today` (+ `/today-empty`), feature `today`, mode parent, seed `demo`/`empty`.
Reviewed: the **working tree** (see M2 — it is ahead of `git diff main...HEAD`),
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P08,
`docs/design/SPACING_SPEC.md`, `app/lib/core/design_system/**`, the design PNGs,
`P08-today.html`, `ui/*.png`, `ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`,
and the iteration-1 findings in this file's ledger below. No code was edited.

## Verification I ran myself

| Check | Result |
|---|---|
| `flutter test` (full) | **387 passed, 0 failed** (80 in `test/features/today`) |
| `flutter analyze` | `No issues found!` |
| `dart format --set-exit-if-changed .` | `344 files (0 changed)` |
| `git diff main...HEAD --name-status` | only `features/today/**`, `test/features/today/**`, `docs/screens/P08/**` ✓ |
| Design-vs-app pixel measurement (light PNG vs `ui/today-light.png`, ÷3) | quest-row gap **21.33 vs design 21.33** — exact match; quest-card height 68.67 vs 68.67; kid cards start 262 vs 258 |
| Screenshot freshness | light 01:59, dark 02:07, empty 02:08 — all newer than the 01:48 source ✓ |
| v1 `pip_stage_*.svg` still referenced in the feature | none ✓ |
| `analysis_options.yaml` vs `main` | unchanged |

## Iteration-1 ledger

| # | Iteration-1 finding | Status |
|---|---|---|
| B1 | suite red (3 failures) | **fixed** — 387/387 |
| B2 | quest rows 8px apart, not 16px | **fixed** — measured 21.33 = design |
| B3 | banner subtitle wrong + hard-coded | **fixed** — `todayBannerSubtitle` from state |
| B4 | "1 quests waiting" | **fixed** — `todayPendingLabel` |
| B5 | "Happy week: 1 days" | **fixed** — `happyWeekLabel` |
| B6 | kids grid N-up, breaks at 3+ children | **fixed** — chunked 2-up + a 3-child test |
| B7 | `go` to top-level routes killed the back stack | **fixed** — `push`; `SHARED_REQUEST` §4 |
| B8 | dark screenshot predated the source | **fixed** — re-shot, chip verified in dark |
| B9 | greeting Nunito 800 / no tracking | **fixed** — w900 + −0.22 |
| B10 | banner semantics double-announce | **fixed** — label dropped, children announce once |
| B11 | quest order α, not status-first | **fixed** — `_rankOf` then title |
| B12 | `NestSectionLabel` re-implemented | **fixed** |
| B13 | dead `detail` + duplicate status copy | **fixed** — `detail` removed everywhere |
| B14 | retry leaked a second `forEach` | **fixed** — `_closeOnError` |
| B15 | raw `error.toString()` on screen | **fixed** — fixed kind copy |
| B16 | `text-wrap: balance` unavailable | accepted (platform limit) |
| B17 | `liveRegion` re-announces | deferred, documented in `2_build.md` |
| B18 | meta `runSpacing` 4 vs 6 | `SHARED_REQUEST` §7 |
| B19 | seed/design repeat-rule conflict | resolved by `main` `e94d063` |
| B21 | P08b content inset 36px vs 20px | deferred to the P08b loop (still open) |
| B22 | `DESIGN_SPEC` §5 stale floating-pill line | `SHARED_REQUEST` §5 |

Orchestrator notes: **1 ✓** (per-child `PipAvatar`, verified in both PNGs and by
`[P08-B02]`), **2 ✓**, **3 ✓** (`· Daily` now from the seed), **4 ✓**.

That is a genuinely clean iteration. The three findings below are new — none is a
regression, and two of the three are landing/verification hazards rather than screen code.

---

## Findings

### M1 — major — with Reduce Motion on, Leo's Pip renders as a "dashed placeholder" outline

`app/lib/core/design_system/motion/pip_avatar.dart:288-293` + `:389-391` + `:433`

`fallbackAsset` only has real art for Mochi:

```dart
static String fallbackAsset(PipStyle style, int stage) {
  if (style == PipStyle.mochi) {
    return 'assets/illustrations/pip_v2/mochi/s${stage}_idle_1.svg';
  }
  return 'assets/illustrations/pip_v2/${style.dir}/placeholder.svg';
}
```

and `_PipAvatarBody` short-circuits to that fallback whenever motion is reduced:

```dart
final reduce = (MediaQuery.maybeOf(context)?.disableAnimations ?? false) || kDisableAnimations;
...
if (reduceMotion || !riveEnabled) { return _PipAvatarSvgFallback(...); }
```

`MediaQuery.disableAnimations` is true whenever the OS "Reduce Motion" accessibility
setting is on (iOS `UIAccessibility.isReduceMotionEnabled`). `app/assets/illustrations/pip_v2/bolt/`
contains **only** `placeholder.svg` — a dashed outline whose own `aria-label` reads
*"Pip placeholder - style art not yet generated"*. The demo family's second child is
Bolt (`seed.dart:161`), and `today_loaded_body.dart:566` passes
`style: pipStyleFor(summary.pipStyle)` → `PipStyle.bolt`.

⇒ With Reduce Motion on, the parent's home screen shows a dashed placeholder outline
where Leo's Pip should be — for one of the two children, on the screen's main content.
The screen's own code is correct (it passes the right style/skin/stage/accessory) and the
fix is not P08-local, so this is a `SHARED_REQUEST`. It is not filed.

Two aggravating details:

1. **It hides behind `SHARED_REQUEST` §6.** §6 documents that
   `bool.fromEnvironment('DISABLE_ANIMATIONS')` never parses `"1"` to `true`, so the
   still-frame rule is silently off and today's screenshots take the Rive path and look
   correct. **Fixing §6 without shipping Bolt/Storybook still art would make every P08
   screenshot show the placeholder instead.** §6 and this finding must land together.
2. **The semantics label then lies.** `today_loaded_body.dart:560-563` still announces
   *"Leo's Pip, a hatchling"* while a sighted reduced-motion user sees a dashed outline.

The gap is known but not owned: `docs/pip-v2/ANIM_B_NOTES.md:62` records
"`pip_v2/bolt/` untouched (placeholder)" and `docs/pip-v2/T10_pip_lab.md:11` accepts
"no placeholder/fallback SVG **unless reduced motion**" — i.e. the lab's acceptance
criterion tolerates it, so nothing will fail until a user turns Reduce Motion on.
`test/pip_avatar_test.dart:187` only exercises the fallback for **mochi**, which is why
this is invisible to CI.

**Fix (shared, new `SHARED_REQUEST.md` §8):** add
`assets/illustrations/pip_v2/{bolt,storybook}/s1..s4_idle_1.svg` (or make `fallbackAsset`
fall back to Mochi's approved still art for any style whose art has not landed — better
than a dashed outline in a shipped parent screen). Until then, `SHARED_REQUEST` §6 should
be marked as *coupled* to §8 so they are batched in the same merge.

### M2 — major — the iteration-2 work is uncommitted, so `main...HEAD` still describes iteration 1

`git status`: **804 insertions across 13 `app/` files are uncommitted**
(`+364` in `today_view_test.dart`, `+164` in `today_loaded_body.dart`, `+141` in
`today_repository_test.dart`, `+93` in `today_repository_impl.dart`, and so on). HEAD is
`d46e500`; its `TodayFailureBody` still takes `{required this.message}` and its views
still pass `message:`, so HEAD is a self-consistent **iteration-1** tree — it is simply a
different tree from the one that was tested, screenshotted and signed off.

This is not cosmetic. RULES §7's done criteria, this stage's own brief
("Review `git diff main...HEAD`") and the orchestrator's merge step all assume the branch's
commits describe the screen. Merging `screen/P08` as it stands today would land
**iteration-1 code** — the red suite, the wrong banner copy, the 8px quest gaps, the
`go`-navigation — while `2_build.md` and `3_test.md` in the same branch assert
`All tests passed!` and `compare.py 5.22%`. Every green claim in the notes is
unreproducible from the branch.

**Fix:** `git commit -am 'P08: loop iteration 2 fixes'` (plus `git add` for the untracked
`p08_bugs_test.dart`), then re-run `flutter analyze && flutter test` **from the committed
tree** and re-confirm the three `ui/*.png` still match it before asking for a review
re-run. Long term, the runner should refuse to advance a stage while `git status
--porcelain` in `app/` is non-empty.

### M3 — major — the branch is behind `main`; a naive merge reverts P01

`main` moved at 02:13 (`2eaac3f` "Resume notes: progress after P01 merge") while the
branch last merged `main` at 01:45 (`d46e500`). Consequences:

- `git diff main` (two-dot) shows **deletions** of all of `docs/screens/P01/**`, of
  `app/test/features/onboarding/{onboarding_bloc_test,p01_bugs_test,welcome_view_test}.dart`,
  and a **modification** to `app/lib/features/onboarding/presentation/views/welcome_view.dart`
  — i.e. merging this branch as-is would revert another feature's landed work.
- The three-dot diff is clean, so **P08 itself edited nothing outside RULES §1** — this is
  branch staleness, not a scope violation, and needs no code change.
- It also means my "full suite" result is partial: `flutter test` here ran **387 tests
  without** P01's onboarding suite, because those files are not in this worktree. So
  "full suite green" is true of the branch's stale view of `main`, not of a merge result.

**Fix (orchestrator, no code change):** merge `main` into `screen/P08` before landing,
then re-run `flutter test` — P01's `onboarding_bloc_test.dart`, `p01_bugs_test.dart` and
`welcome_view_test.dart` must be present and green in the merged tree. The loop already
has this rule (`5c0267e` "merge main into the screen branch before each build"); it needs
to run again *after* the last stage, not only before the build.

---

## Minor

- **m4** `presentation/bloc/today_state.dart:25-26` — the doc comment still says
  *"Items with `status == 'done_pending'`"*, but `pendingCount` is now a family-wide DB
  count (`watchPendingCount`, which deliberately includes "Anyone" quests so the banner
  agrees with P11). The next reader will assume it matches the visible list and "fix" it
  back. Reword: *"Family-wide `done_pending` completions (the set P11 lists), including
  'Anyone' quests — not just the rows shown here."*
- **m5** `test/features/today/today_view_test.dart:864` — the three-children test proves
  the *copy* ("Maya, Leo and Sam…", "Hand to Maya and 2 others") but not the grid geometry
  that B6 fixed. Add a width assertion so a future refactor cannot silently return to
  one-row-per-child: with three children, `tester.getSize(find.byType(NestCard).at(2)).width`
  should be ≈170 (half of 350 − 10), not ≈110.
- **m6** `today_bloc.dart:64` + `today_loaded_body.dart:253` — a childless family still
  gets the header clause "· Happy week: 0 days" (`ui/today-empty.png`), which means
  nothing before the first child exists. Consider dropping the clause when
  `summaries.isEmpty` (P08b's own header copy is a separate loop's scope).
- **m7** `today_loaded_body.dart:722-727` — P08b content is still inset 36px
  (`NestCard` 20 + `NestEmptyState` 16) where the design's `.empty-card` wants 20;
  measured again on `ui/today-empty.png` (button spans x 54.8→335.2 inside a card whose
  edge is at 20). Iteration-1 B21, correctly deferred to the P08b loop — re-check there.
- **m8** `today_loaded_body.dart:419-420` — `liveRegion` still re-announces on every
  emission of the five combined streams even when the count is unchanged (iteration-1
  B17, deferred). Now cheaper to fix than before, since the label is gone: wrap in a
  `StatefulWidget` that only sets `liveRegion` when `pendingCount` differs.
- **m9** `presentation/bloc/today_state.dart:35` — `happyDays` is write-only: the label is
  built in the bloc (`happyWeekLabel`) and nothing reads `state.happyDays`. Either drop it
  or keep it as the seam for a future per-child breakdown; as-is it is a field that
  invites someone to render a second, inconsistent "happy week".
- **m10** `today_loaded_body.dart:68-69` — the `'sofa'` arm of `todayTintFor` is
  unreachable: `q-living` (the only sofa quest) is unassigned, and `rows()` only emits
  directly-assigned quests. Harmless, but it is a hint that the map and the data model
  have drifted; a one-line comment or removal keeps the next reader honest.
- **m11** (carried, not re-raised) The screen opens ~10 Drift watchers: `watchSummaries()`
  re-subscribes `watchItems()` internally (`today_repository_impl.dart:40`) *and* the bloc
  subscribes both, with `watchChildren` watched twice and `watchPendingCount` added on top.
  Every DB write re-runs all of them. No rebuild storm (Equatable props dedupe the
  `emit`) and the dataset is tiny, so this is not user-visible — but one
  `Stream<TodayDay> watchTodayDay()` would collapse it to a single subscription set and
  would also let the bloc drop the nested `as List<dynamic>` casts at
  `today_bloc.dart:46-51`.

## Checks that passed (no findings)

- **RULES §1 scope** — three-dot diff is exactly `features/today/**`,
  `test/features/today/**`, `docs/screens/P08/**`. No `core/`, no `app/`, no other feature,
  no `tools/screens/`. `analysis_options.yaml` byte-identical; no `skip`/`ignore`/`only`
  in the four test files.
- **ARCHITECTURE** — `domain/` is still entities + an abstract `TodayRepository` (five
  members, no concrete types, no use-case classes); `data/` is model + Drift impl; one
  bloc, one `TodayLoadRequested`, `initial/loading/loaded/failure`; `TodayBloc` is still a
  GetIt **factory**, so `BlocProvider` closes it and `emit.forEach` cancels on pop; DI and
  routes untouched; every import `package:nestling/…`.
- **No schema/migration/seed fork** — all new data (`members.role`, `families.payout_day`,
  `children.{age_years,happy_days,pip_style,pip_skin,pip_accessory}`,
  `quests.{repeat_rule,icon}`) is read from existing tables.
- **Design-system usage** — no colour literals, no magic numbers where a token exists, no
  hard-coded font family; components reused throughout (`NestCard`, `NestQuestCard`,
  `NestButton`, `NestIconButton`, `NestAvatar`, `NestIcon`, `NestProgress`, `NestCoinPill`,
  `NestEmptyState`, `NestSectionLabel`, `PipAvatar`). The two local `Container`s (leaf-tint
  banner, 26px status chip) are variants the system does not ship and are documented as
  such — correct per RULES.
- **DESIGN_SPEC §5 P08** — every element present: header greeting + date + `+` + `S`
  avatar, leaf-tint banner + "Review", 2-up kid cards (Pip, "4 of 6 quests", progress,
  coin pill), "Today's quests" + "See all", `MAYA · 9` groups, quest rows in HTML chip
  order, hand-off button. Copy is exact and en-GB throughout, including the
  data-derived banner line. Numbers come from the seed, per DATA OVER MOCKS.
- **Accessibility** — 44px targets on every tappable (plus/avatar 44, Review 44, See all 44
  via `12+20+12`, quest rows ≥56 by content, hand button 52); `header: true` on the
  greeting and the group labels; per-child Pip and progress labels; the banner now
  announces once; nothing below 12px; no red, no nagging. (Two shared exceptions remain
  filed: `SHARED_REQUEST` §2 doubled card labels, and M1's placeholder art.)
- **Performance** — `BlocBuilder` + Equatable props, so identical states never rebuild;
  `const` separators and `const` stateless subtrees; no `setState` in build, no
  `IntrinsicHeight`/`shrinkWrap` lists, no per-frame work. See m11 for the watcher count.
- **Error handling** — `emit.forEach` with `_closeOnError` so a failed load terminates and
  "Try again" cannot stack subscriptions; a fixed, kind failure message with the raw error
  kept out of the UI; the failure path is covered by a test whose stream stays open.
- **Children's Code** — no analytics, ads, tracking or network calls; data is read from
  the on-device Drift DB only; no child identifier, nickname, DOB or photo leaves the app;
  `/today` and `/today-empty` are both in the router's `parentOnly` set (`main` `ded8eb9`)
  so kid mode is redirected to the parental gate before this view can render; coins only,
  never `£`; no urgency or loss-framing copy. Nothing to file.

## Before this screen passes

1. **M2** — commit the working tree; re-verify analyze/tests/screenshots from the commit.
2. **M3** — merge `main` into `screen/P08` and re-run the full suite with P01's tests present.
3. **M1** — file `SHARED_REQUEST` §8 (Bolt/Storybook still art) and mark §6 as coupled to it,
   so the animation-freeze fix cannot turn today's correct screenshots into placeholders.

m4-m11 are polish and may ride along, but m4 and m5 are cheap and protect the fixes just
landed.


## From 6_bugs.md
# P08 · Today (home) — bug hunt (Stage 6, iteration 2)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seeds `Seed.demo()` / `Seed.empty()`. **No screen code was changed.** Re-hunted
the iteration-2 working tree (after the fix pass and `main` merges `b0809f6`,
`f6b02d8`, `e7ad050`).

The feature suite now has 86 tests
(82 passed, 4 skipped). `p08_bugs_test.dart` itself has 17: the 11
iteration-1 proofs (unskipped, green), **4 new skipped proofs** for the two
findings below, and 2 unskipped regression pins. Run the proofs with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 4
fail against the current screen, by design.

## Iteration-1 ledger — all 11 fixed and re-verified

| ID | Iteration-1 finding | Status / proof |
|---|---|---|
| P08-B01 | kid mode could open `/today-empty` | fixed on `main` (`ded8eb9`); proof green |
| P08-B02/B03 | v1 Pip SVGs instead of per-child `PipAvatar` | fixed; proofs assert Maya mochi·sunny·3 / Leo bolt·sky·2, P08b mochi·1 |
| P08-B04 | questless children invisible | fixed (`watchSummaries` from `watchChildren`); proof green |
| P08-B05 | kids grid N-up, 3+/6 children | fixed (pair chunking); proofs green + new width assertion (170 px) |
| P08-B06 | banner ignored family-wide pendings | fixed (`watchPendingCount`); proof green |
| P08-B07 | back from Review exited the app | fixed (`push`); proof green |
| P08-B08 | retry leaked watchers | fixed (`_closeOnError`); proof green |
| P08-B09 | single child card 350 px | fixed (`Row + Spacer`); proof green |
| P08-B10 | quest rows α-sorted | fixed (rank then title); proof green |

Carried C1–C15 from the iteration-1 list: fixed or dispositioned in
`2_build.md` (accepted: C9/B16 balance wrap; deferred: C10/B17 liveRegion,
C11/B21 P08b polish; shared: C13 §2, C14 §5, §6, §7).

## New findings (this iteration)

### P08-B11 — a quest's status ignores the mandatory period ruling — MAJOR

- **Where:** `app/lib/features/today/data/today_repository_impl.dart:154-168`
  — `_statusOf()` returns the latest completion's raw status with no
  `countsForCurrentPeriod` check, and `rows()` (`:119-152`) never passes the
  quest's `repeatRule` or a `now`. The summaries' `done` count (`:59-64`)
  inherits the stale statuses.
- **Rule:** `ORCHESTRATOR_NOTES.md` §"Ruling on 'done today'" (K03-BUG-4):
  *"treat a quest's latest completion as current only if
  `countsForCurrentPeriod(quest.repeatRule, completion.createdAt,
  DateTime.now().toUtc())`; otherwise the quest is 'to do'."* The ruling is
  restated in this stage's brief. Stages 2/3/5 claimed it done; the feature
  contains no call to `countsForCurrentPeriod` (grep: only `core/data/
  london_time.dart` and `test/core/london_period_test.dart` reference it).
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B11]'`
  - daily quest with a completion *before today's London day start* →
    expected `to_do`, actual `approved`;
  - weekly quest with a completion *before this London week's start* →
    expected `to_do`, actual `approved`;
  - Maya's kid card with one stale daily approval → expected `4 of 6 quests`,
    actual `5 of 6 quests` (probe measured `5of6=1, 4of6=0`).
- **Failing tests:**
  `[P08-B11] a daily completion from the previous London day is to do`,
  `[P08-B11] a weekly completion from last week is to do again`,
  `[P08-B11] the kid card count excludes stale completions`.
  Unskipped pin (passes now and must keep passing):
  `[P08-B11] a "once" completion from years ago still counts`.
- **Suggested fix (feature-local, `data/`+`domain/` only):**
  1. `_statusOf(Quest quest, String childId, List<QuestCompletion>
     completions, DateTime now)`: keep the latest completion; if `latest ==
     null` → `'to_do'`; else `countsForCurrentPeriod(quest.repeatRule,
     latest.createdAt, now) ? latest.status : 'to_do'`.
  2. Pass the `Quest` (not just its id) and a single
     `now = DateTime.now().toUtc()` computed once per `rows()` call
     (sort and rows must agree).
  3. `done`/progress follow automatically — they are derived from item
     statuses.
  4. **Testability caveat:** `flutter_test_config.dart` pins only
     `Seed.anchorOverride`, not the wall clock. With a hard-wired
     `DateTime.now()`, the demo assertions ("4 of 6", pending chips) become a
     time bomb — they pass while the real date sits within the seed's
     London day/week and fail after. Inject a clock seam
     (`TodayRepositoryImpl({required db, DateTime Function()? clock})`,
     default `() => DateTime.now().toUtc()`) and pin it in tests, or pin
     `now` the same way `Seed.anchorOverride` is pinned. (The ruling's
     "do not hard-code dates" still holds.)
  5. Decide explicitly whether `watchPendingCount` (approvals banner) should
     also be period-scoped. Today it is family-wide to match P11, and P11
     lists every `done_pending`; if the banner is scoped but P11 is not, the
     Review list will disagree with the count. Flag for the orchestrator
     rather than guessing.

### P08-B12 — a rapid double-tap pushes two pages — MINOR

- **Where:** `today_loaded_body.dart:658` (quest row), `:376` (`+`), `:460`
  (Review) — `context.push` with no in-flight guard. The taps land before the
  first frame rebuilds, so each runs its own push.
- **Repro:** `--run-skipped … --plain-name '[P08-B12]'` — double-tap
  "Empty the dishwasher": two `/quest-editor?questId=q-dishwasher` pages are
  stacked (`skipOffstage: false` count = 2; probe: after the first system back
  the editor is still on screen for a second back). `+` and `Review` behave
  the same.
- **Failing test:** `[P08-B12] a rapid double-tap opens one quest editor`.
- **Suggested fix (feature-local):** guard the push while a navigation is
  already in flight — e.g. `if (ModalRoute.of(context)?.isCurrent ?? true)
  context.push(...)`, or hold a local `_pushing` flag cleared on return; keep
  `push` (the back-stack contract from B07). Re-run the proof (it also
  asserts one back returns to `Today's quests`).

## Resolved during this stage

- **4_review M1 — Reduce Motion drew the dashed Pip placeholder for Leo.**
  Was real (probe: `bolt/placeholder.svg` for Leo). `main` `f6b02d8`
  ("PipAvatar fallback: approved art for every style") landed while this
  stage ran and is merged (`e7ad050`); the new unskipped regression pin
  *"Leo's Pip renders real art, not the placeholder"* passes. With §6 fixed,
  the screenshots will now fall back to real art rather than placeholders —
  the §6/§8 coupling noted in `4_review` is no longer a hazard.
- **M3 — branch behind `main`.** Resolved by `e7ad050`: P01's tests are
  present and the full suite is green (455 tests).

## Carried / still open

- **M2 (process).** The iteration-2 work is still uncommitted at hand-off
  (`app/` working tree modified). The loop's rule "process items are not
  review findings" applies; the orchestrator commits between stages.
- **m4** `TodayState.pendingCount` doc comment still describes it as "items
  with status done_pending" while it is now the family-wide DB count.
- **m6** childless family header still reads "Happy week: 0 days" (P08b's own
  header copy is a separate loop's scope).
- **m7** P08b empty-card content inset 36 px vs the design's 20 (P08b loop).
- **m8** `liveRegion` banner re-announces on unrelated emissions (deferred).
- **m9** `TodayState.happyDays` is write-only (nothing reads it).
- **m10** unreachable `'sofa'` arm in `todayTintFor`.
- **m11** ~10 Drift watchers per open (re-subscription smell; not
  user-visible).
- **Shared §6** `kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`
  still never parses `=1` (screenshot frame stability); **§2** core card
  semantics duplication; **§4** push coordination for P09/P11; **§5** stale
  DESIGN_SPEC floating-pill line; **§7** quest-meta `runSpacing` 4 vs 6.

## Checked, no bug found (this iteration)

- Parent/kid guard: `/today`, `/today-empty`, `/quest-editor` all gated;
  `[P08-B01]` green.
- Back navigation: `push` + system back from approvals and editor returns to
  Today (proofs green).
- Restart persistence: no changes to the load path since the iteration-1
  check (approve → dispose → relaunch keeps the banner hidden, statuses
  approved).
- Dark-mode contrast (labels unchanged, tokens unchanged) and 320 px / 1.3×,
  long UK names, 0/1/6 children, empty lists, 9 999 coins, `£`/pence: all
  covered by the existing suites and iteration-1 checks; P08 still renders
  coins only, so money rounding is N/A.
- `once`/daily/weekly boundary maths: `countsForCurrentPeriod`,
  `londonDayStartUtc`, `londonWeekStartUtc` are correct incl. BST
  (`test/core/london_period_test.dart`); the gap is that the feature never
  calls them (P08-B11).
- Emit-after-close / async gaps: `_closeOnError` + bloc 9.2.1 cancellation;
  `[P08-B08]` green.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test test/features/today` → **82 passed, 4 skipped, 0 failed**.
- `flutter test` (full) → **455 passed, 4 skipped, 0 failed**.
- The 4 skips are this stage's proofs for P08-B11 (×3) and P08-B12; they are
  the only red results under `--run-skipped`.

## Verdict

One new **major** bug (P08-B11 — the mandatory periods ruling is not
implemented, so stale completions keep showing as done/pending and inflate
the kid-card counts) plus one minor (P08-B12). Fix them, unskip the four
proofs, and re-run the suite; B11's clock seam is part of the fix so the demo
assertions do not become date-dependent.

