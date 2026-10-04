# Shared batch 8 REPORT (branch `shared/shared_batch8`)

Scope: placeholder-title assertions (all at once) + `NestKidButton` muted
colourway (K08 `.k8-get.off`). Minimal, backward-compatible: no public API
renames, no route changes, no `app/lib/features/**/presentation` screen code
touched. Defaults unchanged except the additive `muted` enum value.

Evidence read first: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/design/SPACING_SPEC.md` (§2 `.btn-kid`, K08 `.k8-get` + `.off`),
`tools/screens/stages/common.md` (owner rules),
`../nestling-screens/K08/docs/screens/K08/SHARED_REQUEST.md` §1 (muted
spec: `surface-2` / `ink-2` at full opacity, same 3 px ink border, sh-kid,
17 px w900 label),
`app/lib/core/design_system/components/nest_kid_button.dart`,
`app/test/test_scope.dart` (`pushedPath` / `currentPath`),
`app/test/features/kid_home/kid_home_view_test.dart`,
`app/test/features/kid_home/k03_bugs_test.dart`,
`app/test/app/router_push_test.dart`,
`app/test/features/paywall/paywall_view_test.dart`,
`app/test/features/paywall/p07_bugs_test.dart`.

## Files changed

- `app/lib/core/design_system/components/nest_kid_button.dart`
  Added `NestKidButtonColor.muted` (bg `surface2`, fg `ink2`). `Opacity` is
  `1` when `enabled` OR `color == muted`, so the K08 "Save up!" button
  (`onPressed: null`) renders the flat `surface-2` / `ink-2` block at full
  opacity instead of the 0.45 wash. `Semantics(enabled:)` still follows
  `onPressed != null`, so disabled keeps `enabled: false` + no tap action.
  Same 3 px ink border, `kidShadow` (0,6), label style unchanged. Doc
  comments updated (enum + K08 `.k8-get.off` extension note).
- `app/test/features/kid_home/kid_home_view_test.dart` (16 hits)
  Every `find.text('K04 Quest detail' | 'K05 Quest complete' | 'K06 Pip
  nest' | 'K08 Reward shop' | 'K09 My jar')` replaced with a route
  assertion: celebration/detail/dock targets assert `pushedPath(tester) ==
  '/quest-complete' | '/quest-detail' | '/pip' | '/reward-shop' |
  '/my-jar'`; failed-write cases assert `pushedPath(tester) == '/kid-home'`
  (no celebration). `GoRouter.of(tester.element(find.text(...)))` finders
  now use `find.byType(Navigator).first` (same context `pushedPath` uses);
  `state.uri.path` + `extra` assertions kept. The dock a11y table dropped
  its third tuple element (`screen` copy) — `pushedPath` already proves the
  navigation, so the redundant `find.text(screen)` line is deleted.
- `app/test/features/kid_home/k03_bugs_test.dart` (9 hits)
  Same idiom: `K05` opens assert `pushedPath == '/quest-complete'`, `K04`
  opens assert `pushedPath == '/quest-detail'`, failed/silent no-op writes
  assert `pushedPath == '/kid-home'` (kept each test's reason string).
- `app/test/features/paywall/paywall_view_test.dart` (1 hit)
  `expect(find.text('P07 Paywall'), findsNothing)` →
  `expect(currentPath(tester), '/paywall')` (pumped at `/paywall`, no push).
- `app/test/features/paywall/p07_bugs_test.dart` (1 hit)
  Same replacement as above.
- `app/test/app/router_push_test.dart` (1 hit, comment only)
  Reworded the history comment to name the P02 title in words instead of a
  literal `find.text('...')` string, so the guard scan stays clean. No test
  logic changed (the file already asserts only router locations).
- `app/test/design_system/shared_batch8_test.dart` (new, 4 tests)
  Muted colourway pins (see below).
- `app/test/meta/no_placeholder_titles_test.dart` (new, 1 test)
  Guard scan of `test/**.dart` (excludes itself) failing on
  `find.text('Kxx ...')` / `find.text("Pxx ...")`.
- `app/lib/features/**/presentation/**`: untouched (per task; item 1
  explicitly allowed `app/test/**` edits only).

No feature code touched. `pubspec.yaml` unchanged.

## 1. Placeholder-title assertions

Grep before: 28 hits matching `find.text('K..` / `find.text('P..` (16 +
9 + 1 comment + 2 paywall). After: 0 (`grep -rnE
"find\.text\(['\"][KP][0-9]{2} " app/test` exits 1). The guard test enforces
this permanently.

Route table used (from `*_routes.dart`, stable shared contracts):

- K04 detail → `/quest-detail`, K05 complete → `/quest-complete`
- K06 nest → `/pip`, K08 shop → `/reward-shop`, K09 jar → `/my-jar`
- P07 paywall → `/paywall`, home (no navigation) → `/kid-home`

`pushedPath` is used after taps/pushes (it reads `GoRouter.state.uri`,
what the Navigator renders); `currentPath` is used where the app was pumped
at the route and never pushed (paywall screens). This matches the idiom and
comments already in these files (e.g. kid_home lock tests, `test_scope.dart`
75-77: "Assertions on a pushed screen MUST use this helper and never the
view's title text").

Each test's intent is preserved: navigation tests still prove the
destination + extras (questId/childId/coins, pending counts, DB flips);
no-celebration tests still prove no navigation (now via staying on
`/kid-home`) plus the SnackBar / retry-count assertions that were already
there.

## 2. NestKidButton muted colourway

`NestKidButtonColor.muted`:

- bg `tokens.surface2`, fg `tokens.ink2` (both themes via tokens)
- `Opacity(1.0)` even when `onPressed == null` (the grey pair IS the
  disabled look); all other colours keep `0.45` when disabled
- `Semantics(button: true, enabled: onPressed != null && !loading,
  onTap: enabled ? onPressed : null)` unchanged → disabled reports
  `isEnabled false`, no `SemanticsAction.tap`
- border `Border.all(ink, 3)`, shadow `kidShadow` offset `(0, 6)` (unpressed),
  label `NestType.buttonKid` at the caller's `fontSize` (K08 passes 17 w900,
  minHeight 56, radius 16)

Existing `NestKidButtonColor.values` loops (`buttons_test.dart`,
`overflow_test.dart`) now also render `muted` — still green, no behaviour
change for the other six colours.

## Tests

New tests (5):

- `app/test/design_system/shared_batch8_test.dart`
  - `muted paints surface-2 / ink-2 with the kid border+shadow`
  - `muted renders at full opacity when disabled`
  - `muted keeps disabled semantics when onPressed is null`
  - `muted stays enabled when onPressed is set`
- `app/test/meta/no_placeholder_titles_test.dart`
  - `no shared test asserts a placeholder screen title`

Updated tests (all green, intents unchanged): `kid_home_view_test.dart`
(dock/navigation/celebration/a11y groups), `k03_bugs_test.dart` (BUG-1/2/6,
retry, silent no-op, semantics groups), `paywall_view_test.dart`,
`p07_bugs_test.dart` (P07-BUG-1 groups), `router_push_test.dart` (comment
only).

Verification: `cd app && dart format .` → 0 changed on re-run;
`flutter analyze` → `No issues found!`; `flutter test --timeout 120s` →
`+3629 ~4: All tests passed!` (~4 are the pre-existing parked K03-BUG-16/17
+ siblings, still skipped).

## Follow-up screens must do

- K08: swap the unaffordable card's fallback (`white` + `onPressed: null`)
  for `NestKidButton(label: 'Save up!', color: NestKidButtonColor.muted,
  minHeight: 56, borderRadius: 16, fontSize: 17, onPressed: null)`. No other
  screen needs to change; `muted` with a non-null `onPressed` also works
  (full opacity, enabled semantics) but the design only uses the disabled
  form.
- All screens: never assert placeholder titles (`find.text('Kxx ...')` /
  `find.text('Pxx ...')`) in any `app/test/**` file — assert
  `pushedPath(tester)` after a push/tap or `currentPath(tester)` where
  pumped. The new `no_placeholder_titles_test.dart` guard fails the suite
  if one is added.

VERDICT: PASS
