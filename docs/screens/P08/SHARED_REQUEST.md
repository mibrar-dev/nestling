# Shared requests — P08 Today (home)

## 1. RESOLVED (merged from main `2f723db`, `5c0267e`) — stale router assertion

Need (original): update one stale assertion in
`app/test/app/router_redirect_test.dart` (`onboarded parent lands on Today`
expected `find.text('P08 Today')`, the foundation placeholder AppBar title).
Stage 2 replaced the placeholder with the real P08 view, so that string no
longer existed; the test was red.

Status: fixed on `main` by `2f723db` ("Tests: router redirect checks assert
the route path, not placeholder titles") and merged into this branch —
`flutter test` is green again on the shared suite.

## 2. NEW (non-blocking, a11y) — core cards double-announce their semantics

Need: `NestCard` (`app/lib/core/design_system/components/nest_card.dart:60-65`)
and `NestQuestCard`
(`app/lib/core/design_system/components/nest_quest_card.dart:107-111`) wrap
their content in `Semantics(button: true, label: …)` **without**
`excludeSemantics: true` (and without `container`/`explicitChildNodes`), so
Flutter merges the explicit label with every descendant label/text. A screen
reader hears the same information twice, e.g. on P08:

- quest row → `"Empty the dishwasher, 15 coins, Needs a look\nEmpty the
  dishwasher\n15 coins\n· Weekly · Sat\nNeeds a look"`
- Maya's card → `"Maya, 4 of 6 quests, 120 coins\nMaya\n4 of 6 quests\nMaya's
  Pip, a fledgling\nMaya's quest progress\n120 coins"`

Fix: add `excludeSemantics: true` to those two wrappers (the passed
`semanticLabel` already carries the intended announcement), or drop the
explicit label and let the children announce once.

Files: `app/lib/core/design_system/components/nest_card.dart`,
`app/lib/core/design_system/components/nest_quest_card.dart`
Blocks: no — rendering, navigation and the declared labels are all correct;
this is announcement quality only. Evidence: `docs/screens/P08/3_test.md`
§B4 (semantics dump).

Note: the same pattern exists in feature code for the P08 approvals banner
(`today_loaded_body.dart:359-361`) and is reported as B4a in
`docs/screens/P08/3_test.md` — that part is feature-fixable.

## 3. RESOLVED (already on main) — `/today-empty` is not parent-only

Need (original): add `/today-empty` to the router's `parentOnly` list —
kid-mode deep links to `/today-empty` rendered the parent screen.

Status: already fixed on `main` (`app/lib/app/router.dart` now lists both
`/today` and `/today-empty`); the unskipped `[P08-B01]` proof passes on this
branch. No action needed.

## 4. NEW (non-blocking, cross-screen contract) — P08 reaches P09/P11 by `push`

P08 now opens `/approvals` and `/quest-editor` (with and without `questId`)
with `context.push`, so the OS back button returns to `/today` (was: `go`
replaced the stack and back exited the app). Shell destinations
(`/settings`, `/child-profile`, `/quests`) and the mode switch
(`/who-is-playing`) still use `go`.

Need: the P09 (quest editor) and P11 (approvals) loops must return with
`context.pop()` and must not assume they were `go`-navigated to. No shared
file change — this is a coordination note.

Files: none (P08-local). Blocks: no.

## 5. NEW (doc, orchestrator) — DESIGN_SPEC §5 P08 describes a floating pill

`DESIGN_SPEC` §5 P08 asks for a floating primary `+ New quest` pill above
the tab bar, but `P08-today.html:29` puts the 44 px leaf `+` in the greeting
row, both design PNGs show no floating pill, and the code follows the
design. The §5 text looks stale.

Need: correct `DESIGN_SPEC` §5 P08 to describe the header `+` (shared doc
edit by the orchestrator).

Files: `docs/DESIGN_SPEC.md` §5. Blocks: no.

## 6. NEW (blocking for screenshot determinism) — `DISABLE_ANIMATIONS=1` never parses

`app/lib/core/data/env_flags.dart:9`:
`const bool kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`.
Dart only maps the string `'true'` to `true`, so the `=1` that
`tools/screens/shot.sh` always passes parses to **false**. Consequence for
P08 iteration 2: `PipAvatar` takes the live Rive path during screenshot runs
(the still-frame rule RULES §6 is silently off) and `shot.sh` reports
`WARNING — frame never stabilised in 25 s` on every run (light, dark and
empty this stage — the PNGs are still correct captures, but stability is
unverifiable). Iteration-1 shots stabilised only because the screen had no
animated widget yet.

Need (shared): parse `'1'` too (e.g. `bool.fromEnvironment(..., defaultValue:
false) || const String.fromEnvironment(...) == '1'`), or change `shot.sh`
to pass `=true`. Every Rive/Lottie screen is affected, not just P08.

Files: `app/lib/core/data/env_flags.dart` and/or `tools/screens/shot.sh`.
Blocks: partially — P08 lands and tests green without it, but no Rive
screen can produce a stable-frame screenshot until this lands.

## 8. NEW (blocking) — shared seed-contract test pins pre-ruling Leo count

`app/test/core/data/repositories_test.dart:42` (`today Maya 4 of 6, Leo 2
of 4`) asserts `leo.done == 2` (bed pending + bag approved). The mandatory
periods ruling (this stage's brief, `ORCHESTRATOR_NOTES.md`) makes bag's
approval stale: `q-bag` repeats `daily` (seed `e94d063`) and its approval is
from the previous London day, so Leo renders `1 of 4 quests`. Maya is still
4 of 6 (bins/hoover are `weekly`, same London week).

Need (shared — the screen agent may not edit it): update the expectation to
`leo.done == 1` (or approve bag on the anchor day in the seed if the
orchestrator wants the mock's "2 of 4" preserved — but a daily quest
approved yesterday showing as done today would contradict the ruling, so
changing the expectation is the honest fix).

Files: `app/test/core/data/repositories_test.dart` (one line).
Blocks: yes — `flutter test` is red until this lands. Proved by P08's own
`today_repository_test.dart` (Leo `done == 1`, green).

## 9. NEW (non-blocking, needs a ruling) — should the banner be period-scoped?

`watchPendingCount()` deliberately counts every family-wide `done_pending`
completion so the P08 banner agrees with P11 (`watchPendingApprovals`,
unscoped). If a completion goes stale under the periods ruling, the quest
row resets to "to do" but the banner still counts it — banner and rows can
then disagree the other way. P08 keeps the unscoped count (banner ≡ Review
list); flagging instead of guessing, per the fix list.

Need: orchestrator decision (scope both, or keep both unscoped).
Files: none yet. Blocks: no.

## 7. NEW (non-blocking, design system) — quest-meta `runSpacing` 4 px vs 6 px

`core/design_system/components/nest_quest_card.dart:80` uses
`runSpacing: NestSpacing.s1` (4) where `components.css:178` sets
`.quest-meta { gap: 6px }` (both axes). Invisible at 390 px (one line) but
visible when the meta wraps at 320 px / 1.3× text.

Need: change the shared `runSpacing` to 6 (with §2's semantics fix — same
files, one batch).

Files: `app/lib/core/design_system/components/nest_quest_card.dart`.
Blocks: no.
