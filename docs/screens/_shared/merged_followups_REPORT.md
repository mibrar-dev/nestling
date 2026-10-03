# Merged follow-ups report — P01, P02, P08 (accessibility + balanced headings)

## Files changed

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  - `_Greeting` avatar `Semantics` (~line 429): added `onTap: () =>
    context.go(SettingsRoutePaths.settings)`, mirroring the ancestor
    `InkWell(onTap)`.
  - `_SectionHeader` `Semantics` (~line 655): added `onTap: () =>
    context.go(QuestsRoutePaths.library)`, mirroring the ancestor
    `InkWell(onTap)`.
- `app/lib/features/onboarding/presentation/views/welcome_view.dart`
  - `_WelcomeText` headline: `Text('Chores that feel like a game.',
    style: display)` → `NestBalancedText(same copy, same style,
    textAlign: TextAlign.left)` inside the existing
    `ConstrainedBox(maxWidth: 300)`. No `maxLines` added (there was none).
- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`
  - Step title: `Text(step.title, style: h1)` → `NestBalancedText(step.title,
    style: h1, textAlign: TextAlign.left)`. Same copy/style, no `maxLines`
    added (there was none). Covers all three steps
    (`Set quests in seconds` / `Pip grows as they help` /
    `Pocket money, sorted`).
- `app/test/features/today/today_semantics_tap_test.dart` — new (4 tests).
- `app/test/features/onboarding/onboarding_balanced_headings_test.dart` —
  new (3 tests).

## What / why

1. ACCESSIBILITY (P08): each `Semantics(button, excludeSemantics: true)`
   dropped the ancestor `InkWell` tap action, so the announced button had
   `hasAction(tap) == false` (WCAG 2.1 AA SC 4.1.2 / 2.1.1, RULES §8). The
   fix passes the same `go` callback on the `Semantics` node, keeping the
   single-node announcement. Disabled/null-callback cases do not apply here
   (both callbacks are non-null `go` calls).
2. BALANCED HEADINGS (P01/P02): the design CSS uses `text-wrap: balance` on
   `.display` (`components.css:28`, P01 `h1.display`) and on `.h1` plus the
   `.balance` utility (`components.css:29,41`, P02 `h1.h1.balance.pg-title`).
   Both headlines now render through `NestBalancedText` with identical copy,
   style and (absent) `maxLines`, and `textAlign: left` so the narrowed box
   stays on the 20 px gutter (the component defaults to centre, which would
   shift the P02 title off the gutter and fail the alignment test). The P01
   300 px cap is kept: the balanced box narrows inside it, the outer layout
   and 2-line height are unchanged, and the existing
   `headline is capped … at 390dp` test (`width <= 300`) stays green.
   The P02 titles are single-line at 390 px, so `NestBalancedText` returns
   the plain `Text` (no visual change — rule compliance only).

## Design line breaks at 390 px (PNG ÷ 3, real Nunito)

Read with the file reader (1170 px PNG ÷ 3 = 390 logical):

- P01 `design/screens/light/P01-welcome.png`: 2 lines —
  `Chores that feel` / `like a game.`
- P02 `design/screens/light/P02-value-tour.png` (step 1 on screen): 1 line —
  `Set quests in seconds`
- P02 steps 2–3 have no static PNG (the HTML only carries step 1 at
  `:128`); measured with bundled fonts at 390 px they also fit on one
  `h1` line each: `Pip grows as they help` (1 line),
  `Pocket money, sorted` (1 line). Noted as already-matched, switched to
  `NestBalancedText` anyway with no visual change.

## Grep audit — other `excludeSemantics: true` + gesture in merged screens

`grep -rn "excludeSemantics: true" app/lib/features/{onboarding,auth,
privacy_consent,family,paywall,today}` finds 6 hits total:

- `family/.../add_child_form_card.dart:75` (`Age band` heading) — child is
  `Text`, no `InkWell`/`GestureDetector` ancestor or descendant. Static,
  left as-is.
- `family/.../add_child_form_card.dart:107` (`Avatar colour` heading) — same,
  static, left as-is.
- `paywall_view.dart:475` (`_BenefitRow`) — child `Row` (tick + `Text`), no
  gesture. Static, left as-is (matches the semantics report).
- `paywall_view.dart:525` (`_PlanCard`) — child `NestCard` with no `onTap`,
  inner radio is a static `Container`. Static, left as-is (matches the
  report).
- `today_loaded_body.dart:429` + `:655` — the two gesture-backed spots,
  fixed here with tests.
- No `excludeSemantics: true` hits at all in `onboarding`, `auth` or
  `privacy_consent`. The remaining `Semantics(button)` wrappers without
  `excludeSemantics` (`_Swatch`, `_KidCard` edit button, `_NoticeLink`,
  `_LegalTarget`, paywall close + `_LegalLink`) keep their descendant tap
  action and need no mirror.

## Test names added

`today_semantics_tap_test.dart` (4 tests, each asserts
`hasAction(SemanticsAction.tap)` and that `performAction(tap)` navigates to
the same `currentPath` as a real tap):

- `P08 Today semantics tap — profile avatar has tap action on the Sarah's
  profile node`
- `P08 Today semantics tap — profile avatar performAction(tap) goes to
  /settings like a real tap`
- `P08 Today semantics tap — See all quests has tap action on the See all
  quests node`
- `P08 Today semantics tap — See all quests performAction(tap) goes to
  /quests like a real tap`

`onboarding_balanced_headings_test.dart` (3 tests, bundled Inter/Nunito via
`FontLoader` at 390 px, caret-row line splitter as in
`nest_balanced_text_test.dart`):

- `P01 + P02 balanced headings (real Inter/Nunito, 390 px) P01 headline
  uses NestBalancedText and breaks like the design`
- `P01 + P02 balanced headings (real Inter/Nunito, 390 px) P02 step 1 uses
  NestBalancedText and stays on one line`
- `P01 + P02 balanced headings (real Inter/Nunito, 390 px) P02 steps 2-3
  stay on one balanced line (no visual change)`

Existing geometry contracts left untouched and green:
`welcome_view_test.dart` (`headline is capped … at 390dp`,
width × scale matrix, scene no-crop), `value_tour_view_test.dart`
(alignment gutters, pager geometry, copy/character groups),
`p01_bugs_test.dart`, `p02_bugs_test.dart`.

Results: `dart format` clean, `flutter analyze` → No issues found!,
`flutter test` → all 1389 tests pass (1382 existing + 7 new).

## Follow-up screens must do

- Nothing. The two Today spots are fixed; the paywall/family
  `excludeSemantics` hits are verified static (no gesture) and need no
  change; P01/P02 headings now satisfy the BALANCED HEADINGS owner rule.
  Screens building in parallel should rebase onto this change and keep using
  `NestBalancedText` (with `textAlign: left` for left-gutter headings) for
  any `.display` / `.h1` / `.kid-title` / `.kid-hero` / `.balance` heading,
  plus `onTap:` on any `Semantics(excludeSemantics: true)` that wraps a
  gesture.

VERDICT: PASS
