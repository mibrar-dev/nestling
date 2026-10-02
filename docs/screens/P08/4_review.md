# P08 · Today (home) — QA code review (Stage 4, **iteration 4**)

Route `/today` (+ `/today-empty`), feature `today`, mode parent, seed `demo`/`empty`.
Reviewed: the working tree, `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P08, `docs/design/SPACING_SPEC.md`, `app/lib/core/design_system/**`,
the design PNGs, `ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`, and the iteration 1–3 ledgers.
No code was edited. Per this iteration's rules, uncommitted work / branch position / merge
order are **not** findings and are not reported below.

## Verification I ran myself

| Check | Result |
|---|---|
| `flutter test` (full) | **479 passed, 0 failed** |
| `flutter analyze` | `No issues found!` |
| `dart format --set-exit-if-changed .` | `351 files (0 changed)` |
| `flutter test test/features/today` | 106 passed, 0 failed, 0 skipped (12 bloc · 23 repo · 50 view · 21 bug proofs) |
| skips anywhere in `test/` | none (the one `skip` hit is the convention comment at `p08_bugs_test.dart:12`) |
| **BOTTOM EDGE** | at x=30/195/360, y 770→843: **one** colour per column apart from the home pill — light `(255,255,255)`, dark `(31,28,46)`; the tab-bar fill spans x 0.00→389.67 at y=800, i.e. to both physical edges ✓ |
| **ALIGNMENT** | cards at y=350/600/700 all span **x 20.00 → 369.67** in light *and* dark (y=450's 27.33→362.33 is the rounded-corner tail below the kid cards) ✓ |
| Quest-row gap | 21.33 vs design 21.33; card height 68.67 vs 68.67 — no regression |
| Demo numbers recomputed from the seed | Maya 4/6, Leo **2/4**, banner 3 — matches both PNGs and the design mock |
| Screenshot freshness / identity | light 08:12, dark 08:13, empty 08:14 — all newer than the source; I opened light and empty myself and they are P08 (no contended-simulator frames this run) |
| v1 `pip_stage_*.svg` in the feature | none ✓ |
| `git diff main...HEAD` scope | only `features/today/**`, `test/features/today/**`, `docs/screens/P08/**` ✓ |

## Mandatory-rule status — all pass

| Rule | Result |
|---|---|
| PERIODS | **rows and banner both scoped.** `rows()`/`_statusOf` use `countsForCurrentPeriod` (`today_repository_impl.dart:186-192`); `watchPendingCount()` now joins completions to quests and filters with the same helper, defaulting unknown quests to `once` so a pending on a deactivated quest is not silently dropped. Boundary coverage is real: *"23:30 London yesterday does not count"*, *"weekly Monday 00:30 London counts"*, *"weekly Sunday night before the week start does not count"*, *"daily across the BST→GMT switch"*, *"summary counts follow the same period rule"*. |
| BOTTOM EDGE | **pass**, both themes, no strip, home-pill area clean |
| ALIGNMENT | **pass**, 20.00 gutters on every element, both themes |
| ORCH notes 1–4 | 1 ✓ per-child `PipAvatar`, 2 ✓ data-driven subtitle, 3 ✓ `· Daily` from the seed, 4 ✓ status-then-title order |
| Data over mocks | ✓ Leo's 2/4 and Maya's 4/6 are the seeded values |

## Ledger — iteration 3 closed

| # | Iteration-3 finding | Outcome |
|---|---|---|
| B1 blocker | shared `repositories_test.dart` red on `leo.done == 2` | **resolved by `e972b46`** — the seed now approves `q-bag` on the story day (`seed.dart:300-309`, `utc(10, 3, 6, 30)`), so it is *inside* the current London day and counts under the ruling; the shared expectation and P08 both say 2, and the mock's designed number survives. Full suite green |
| B2 major | banner count not period-scoped | **resolved** — `watchPendingCount()` period-scoped with `rule ?? 'once'`, proved by `[P08-B13]` ×2 plus three repository tests and a screen-level "banner disappears when no pending is in period" |
| B4 minor | `_PushOnce` `_busy` could latch | **resolved and improved** — the latch is gone entirely: the guard is now per-frame (`_armed` + `addPostFrameCallback`), so it cannot stick whether the page pops, leaves via `go`, or the push throws |
| B5 minor | boundary tests duplicated the clock pin as literals | **largely resolved** — a local `storyDay` plus offsets, with only the genuine 25 Oct BST edge keeping a calendar literal, and the reason documented |
| B3/B6/B7 | rollover refresh, still-art coverage, `DISABLE_ANIMATIONS` | remain open, all filed (§11, §10, §6) — three shared items, none P08-local |

**A correction to my iteration-3 review.** I told the orchestrator not to resolve B1 by
re-stamping `q-bag`'s approval onto the anchor day, on the grounds that "a daily quest
approved yesterday showing as done today" contradicts the ruling. That was wrong, and the
seed change is the better fix: re-stamping onto **today** puts the completion *inside* the
current period rather than outside it, so counting it is exactly what the ruling asks for,
and it preserves the design's "Leo 2 of 4". The alternative I proposed (editing the shared
test to `1`) would have satisfied the letter of the ruling at the cost of silently changing
the mock's number. The trail is intact in `SHARED_REQUEST.md` §8/§9; this note supersedes
my earlier advice so it is not re-applied.

---

## Findings

No blocker or major findings. The remaining items are all carried minors; four of the ten are
shared-code requests the screen agent may not file as code (`SHARED_REQUEST` §2, §6, §10, §11).

### B1 — minor — the banner and the Review list now disagree in the *other* direction until P11 is scoped

`SHARED_REQUEST.md` §9 UPDATE (iteration 4) records this honestly, and P08 is internally
consistent (banner 3 ↔ three "Needs a look" rows in the seeded demo). But the cross-screen
effect is real: once P08's banner stops counting a stale pending, P11's unscoped
`watchPendingApprovals` still lists it, so a parent can see "2 quests waiting" on `/today`
and "Waiting for you (3)" on `/approvals` — and the stale row still routes into P13 payout,
which is the double-payment path. Not a P08 defect and correctly not blocking, but the pair
should not ship in this state. **Fix:** the P11 loop scopes its list with the same
`countsForCurrentPeriod(rule ?? 'once')` helper (already written up in §9). If the P11 loop
is not going to run before this feature ships, the orchestrator should either revert the
banner scoping or relabel the banner — not leave both as they are.

### B2 — minor — `unawaited(context.push(...))` discards a Future that can carry an error

`today_loaded_body.dart:266` — inside the new `_PushOnce`, the push future is dropped with
`unawaited`. In normal operation `context.push` resolves with the popped result, so this is
harmless; but if go_router's redirect/exception path ever rejects, the error surfaces as an
unhandled async exception with no stack context pointing at the button. **Fix:**
`unawaited(context.push(widget.location).catchError((Object _) {}))` — or, if the loop
prefers, keep the future and swallow it in an explicit `try/catch` so the intent reads.

### B3 — minor — statuses are never re-evaluated when the period rolls over under an open app

Carried from iteration 3. Drift's `watch()` only re-emits on table writes, and `rows()`
resolves `at = now ?? _clock()` per emission (`:140`), so a parent who leaves the app open
overnight keeps yesterday's "Needs a look" / "Approved ✓" until something is written.
Filed as `SHARED_REQUEST.md` §11. **Fix:** re-add the single legal event
(`TodayLoadRequested`) on app resume via `AppLifecycleListener`, or refresh on
`TodayState`'s timestamp. Needs to be a shared pattern — every screen showing per-period
status has the same hole.

### B4 — minor — the new non-Mochi still art is still untested

`app/test/pip_avatar_test.dart:84-91` asserts `fallbackAsset` for Mochi only and the
reduced-motion test pumps a Mochi avatar, so nothing exercises `bolt/s2_idle_1.svg` or the
storybook files. The code is now total by construction
(`'.../${style.dir}/s${stage}_idle_1.svg'` for all three styles) and the files exist, so this
is coverage, not a defect — but it is the exact gap that hid iteration 2's M1. Filed as
`SHARED_REQUEST.md` §10. **Fix:** loop the reduced-motion assertion over
`PipStyle.values` × stages 1..4 and assert an `SvgPicture` is present.

### B5 — minor — `shot.sh` still cannot produce a stable frame

`app/lib/core/data/env_flags.dart:9` is unchanged: `bool.fromEnvironment('DISABLE_ANIMATIONS')`
parses the `=1` that `tools/screens/shot.sh:74` passes as **false**, so every run warns
`frame never stabilised in 25 s`. The captures are correct (I verified them), but RULES §5's
stable-frame guarantee is not met, and with the owner rules now making screenshot
determinism load-bearing for the bottom-edge/alignment checks, §6 has moved from cosmetic
to load-bearing. Filed as §6. **Fix:** parse `'1'` as well as `'true'`.

### B6 — minor — "Happy week: 0 days" for a family with no children

`today_bloc.dart:64` composes the date line unconditionally, so `Seed.empty()` still renders
*"Fri 2 Oct · Happy week: 0 days"* above a nest with no children (visible in
`ui/today-empty.png`, 08:14). Carried. **Fix:** omit the clause when `summaries.isEmpty`.

### B7 — minor — P08b content is still inset 36 px

`today_loaded_body.dart:722-727` unchanged: `NestCard` 20 + `NestEmptyState`'s own
`horizontal: NestSpacing.s4` = 36 px against the design's 20. (The card's *outer* edges are
correctly on the 20 px gutter — this is the inner inset only.) Carried; it belongs to the
P08b loop, which has its own design divergence list.

### B8 — minor — the banner is still a `liveRegion` on a five-stream rebuild

`today_loaded_body.dart:457-460`. The duplicated label is gone, but any coin change, child
edit or completion insert still re-announces the same sentence. Carried. **Fix:** a
`StatefulWidget` that sets `liveRegion` only when `pendingCount` differs from the previous
build.

### B9 — minor — `TodayState.happyDays` is still write-only

Set by the bloc, never read by a widget (the label is composed in `happyWeekLabel`). Its doc
comment was improved this iteration to describe the period-scoped `pendingCount` correctly,
which is good, but `happyDays` itself remains a field that invites a second, inconsistent
"happy week". **Fix:** keep it with a comment saying it is the seam for a per-child
breakdown, or drop it.

### B10 — minor — the three-children test still asserts copy, not the grid geometry

`today_view_test.dart:864` proves *"Maya, Leo and Sam did brilliantly yesterday"* and
*"Hand to Maya and 2 others"*, but nothing about the 2-up chunking fixed in iteration 1, so
a refactor back to one-row-per-child would pass. Carried. **Fix:** assert
`tester.getSize(find.byType(NestCard).at(2)).width` ≈ 170 (half of 350 − 10), not ≈110.

### B11 — minor (carried, informational) — ~10 Drift watchers per screen

`watchSummaries()` re-subscribes `watchItems()` internally (`:40`) and the bloc subscribes
both, with `watchChildren` watched twice plus `watchParentName`/`watchPayoutDay`/
`watchPendingCount`. No rebuild storm (Equatable props dedupe the `emit`) and the dataset is
tiny, so nothing user-visible. **Fix (opportunistic):** one
`Stream<TodayDay> watchTodayDay()` would collapse it to a single subscription set and remove
the nested `as List<dynamic>` casts at `today_bloc.dart:46-51`.

## Checks that passed (no findings)

- **RULES §1 scope** — three-dot diff is exactly `features/today/**`,
  `test/features/today/**`, `docs/screens/P08/**`; `analysis_options.yaml` untouched; no
  skips; `analysis` and `format` clean on the whole app.
- **ARCHITECTURE** — `domain/` is entities + an abstract `TodayRepository` (six members, no
  concrete types, no use-case classes); `data/` is model + Drift impl; one bloc, one
  `TodayLoadRequested`, `initial/loading/loaded/failure`; bloc still a GetIt **factory**; the
  clock is an injected constructor seam, not a global; DI and routes untouched.
- **No schema/migration/seed fork by the screen** — the two seed changes that affected P08's
  numbers (`e94d063` daily repeats, `e972b46` bag's approval day) landed on `main` through the
  orchestrator; P08 adapted through its own repository and tests.
- **Design-system usage** — no colour literals, no magic numbers where a token exists, no
  hard-coded font family; `NestCard`, `NestQuestCard`, `NestButton`, `NestIconButton`,
  `NestAvatar`, `NestIcon`, `NestProgress`, `NestCoinPill`, `NestEmptyState`,
  `NestSectionLabel`, `PipAvatar` all reused. `_PushOnce` is a navigation guard with no
  design-system equivalent. The only local `Container`s are the leaf-tint banner and the 26 px
  status chip — variants the system does not ship, documented as such.
- **DESIGN_SPEC §5 P08** — every element present; copy exact and en-GB; the one deviation
  (the stale "floating pill" line) is filed as §5.
- **Accessibility** — 44 px targets throughout; `header: true` on the greeting and the group
  labels; per-child Pip/progress labels; the banner announces once; nothing below 12 px; no
  red, no nagging. Shared exceptions remain filed (§2 doubled card labels).
- **Performance** — Equatable props mean identical states never rebuild; const separators and
  const subtrees; `_PushOnce` deliberately does no `setState`; no per-frame work; the failure
  path cannot stack subscriptions (`_closeOnError`).
- **Error handling** — `_closeOnError` makes the stream error terminal, a fixed kind message
  replaces the raw `toString()`, and the retry path is covered by a test whose stream stays
  open.
- **Children's Code** — no analytics, ads, tracking or network calls; on-device Drift only; no
  child identifier, nickname, DOB or photo leaves the app; `/today` and `/today-empty` are
  both in the router's `parentOnly` set so kid mode is redirected to the parental gate; coins
  only, never `£`; no urgency or loss-framing copy. The period scoping also *reduces* a
  children's-data hazard: a child's stale completion can no longer be silently approved and
  paid for a chore they are free to redo.

## Ship condition

No blocker or major findings, so this screen passes. Before the *pair* of screens ships,
someone should close **B1** — either the P11 loop applies the period scoping, or the
orchestrator reverts/relabels the banner — because until then `/today` and `/approvals` can
disagree about the same three quests. B5 (§6) is the one shared item with a live cost: it
makes every Rive screen's screenshots unverifiable for stability, which is exactly the
property the new bottom-edge and alignment owner rules rely on.

VERDICT: PASS