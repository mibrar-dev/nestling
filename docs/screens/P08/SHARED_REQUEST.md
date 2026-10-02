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

## 3. NEW (blocking, kid-mode guard) — `/today-empty` is not parent-only

Need: add `/today-empty` to the router's `parentOnly` list in
`app/lib/app/router.dart:96-106`. The list contains `/today` and the matcher
only expands `/today/…`, so `'/today-empty'` neither equals nor starts with a
parent prefix: in kid mode, a deep link to `/today-empty` renders the full
parent P08b screen instead of redirecting to `/parental-gate`. Proved by
`[P08-B01] kid mode cannot deep-link into /today-empty` in
`app/test/features/today/p08_bugs_test.dart` (run with `--run-skipped`;
expected path `/parental-gate`, actual `/today-empty`). Details:
`docs/screens/P08/6_bugs.md` §P08-B01.

Fix: add `'/today-empty'` to `parentOnly` (or switch the guard to match on
route names rather than path prefixes, which would not have missed it).

Files: `app/lib/app/router.dart` (shared — the screen agent may not edit it).
Blocks: yes — a parent-only screen is reachable in kid mode until this lands.
