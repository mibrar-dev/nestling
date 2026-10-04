# P17 Parental gate — 2b build UI (iteration 1)

Scope: presentation layer only — `presentation/views/**` and
`presentation/widgets/**` for `parental_gate`, plus widget/view tests
(`*view*`/`*widget*`) in `app/test/features/parental_gate/`. No bloc/
domain/data edits (the emitted bloc contract matched `1_plan.md` exactly;
`2a_build_logic.md` reported no CONTRACT CHANGES — verified). No simulator,
no whole-app test run, no `flutter clean`, no google_fonts, no
letterSpacing additions.

## Files changed

- `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart`
  — full-bleed kid-mode modal screen per the plan:
  - `Scaffold` (transparent, `KidScope` sky gradient + meadow hill behind
    everything, so the scrim/modal/handle colours run to the physical edges).
  - Backdrop column (`Padding 0 28`, `ExcludeSemantics`): `NestAvatar` s44
    (nickname initial or `•` neutral) + `Hi {nickname}!` (`NestType.h1`) +
    `NestCoinPill` (DB coins) + Pip slot 26 top gap, 200×200.
  - Backdrop child resolution: `AppSession.activeChildId` set → that child;
    null/missing → first row of `watchChildren(Seed.familyId)` (creation
    order — Maya, Leo); no children → `Hi there!` header, `•` avatar,
    coin pill `0`, `PipAvatar(style: mochi, skin: sunny, stage: 3, size: 200)`.
    String→enum mappers copied locally from K03's view (never a SharedResponse
    dependency on the bloc layer).
  - Scrim: `Positioned.fill(ColoredBox(color: tokens.scrim))`.
  - Modal layer: horizontal 24 padding → `LayoutBuilder` →
    `SingleChildScrollView` → `ConstrainedBox(minHeight: viewport)` →
    `Center` → `Semantics(label: 'Parental gate', explicitChildNodes: true)`
    → `NestModal` (title: null) with:
    - `_LockTile` 52×52, radius 16, `lilacTint` bg, `NestIcon(lock, 26, lilac)`.
    - `Grown-ups only` (`NestType.h2`, centered), instruction (bodySmall
      ink2, centered), question (`NestType.h3`, centered, maxLines 2, derived
      from `state.challenge?.question`).
    - Digits: `Semantics(label: 'Answer, {filled} of {total} entered',
      excludeSemantics: true)` wrapping a centered row of 56×64 boxes,
      radius 16, 2px border — filled: `surface` + ink; empty: `surface2` +
      `line`; first empty box shows the 3×24 leaf caret (rounded 2).
    - Keypad slot 296 wide, `FittedBox(scaleDown)` → `NestKeypad(kid: true)`,
      keys 72×72 (3×(72+24)+2×8 = 280 inside the slot).
    - `Back to Pip` ghost button, minHeight 56, fontSize 15.
    - Caption 10 px below (`NestType.caption`, ink2).
  - States: loading → equal-height placeholders + a leaf `CircularProgressIndicator`
    (no layout jump); failure → ink2 message + ghost `Try again` (minHeight 44)
    + `Back to Pip` + caption; loaded & items empty → sizing.shrink + the
    listener passes through once (`_didPassThrough`).
  - Listener (`unlocked`/`attempts`/`status`/`items`):
    - `unlocked == true` → `ParentalGateUnlockAcknowledged`, then parent
      mode FIRST (`AppModeController.selectMode(parent)` +
      `AppSession.setAppMode('parent')` + `refresh()`), then `context.pop()`
      when canPop else `context.go(TodayRoutePaths.today)`.
    - wrong answer → `SemanticsService.sendAnnouncement('That wasn’t right —
      try again')` once per increment (guarded by `_announcedAttempts`).
      No red/danger styling.
    - disabled gate → same unlock path WITHOUT the announcement, once.
  - `Back to Pip` → pop or `context.go(KidHomeRoutePaths.home)`.

- `app/test/features/parental_gate/parental_gate_view_test.dart` (new, 9 tests):
  exact copy; digit-fill left→right + delete; wrong entry clears the group
  label; correct entry → parent mode + `/today`; `Back to Pip` pops the gate
  back to `/kid-home`; every key + ghost exposes a tappable semantics node
  (`hasAction(tap)` + `performAction(tap)` changes state); loading spinner;
  failure + `Try again` + `Back to Pip`; disabled gate → parent + `/today`.
- `app/test/features/parental_gate/parental_gate_geometry_test.dart` (new, 2
  tests, light+dark): modal left=24 w=342 radius 32; lock tile 52 radius 16;
  digit boxes 56×64 gap 12; 11 Ink keys exactly 72×72; `Back to Pip` ≥ 56;
  scrim paints a 390×844 `ColoredBox`.
- `app/test/features/parental_gate/parental_gate_states_test.dart` (new, 5
  tests): dark renders no overflow; textScale 1.3 @390 overflow-free;
  320×844 @1.3 overflow-free; every key pad key ≥44-wide rect; caption
  contrast ≥4.5 via WCAG luminance ratio against `tokens.surface`/`ink2` in
  both themes.

## Notable details / decisions

- Semantics taps in widget tests need two pumps (`performAction(tap)` → bloc
  emit is dispatched through a scheduled frame, then the builder runs).
  Comments in the test file say so.
- The keypad wraps in `Semantics(label: 'Number pad')` and the digits row in
  `Semantics(label: 'Answer, …', excludeSemantics: true)` — the inner key /
  box widgets are already self-labelling / display-only so no `onTap:`
  pass-through was needed on the wrapper.
- `NestModal`'s shared padding already matches the design
  (top 24 / sides 20 / bottom 20), so no local fork was needed.
- No status bar reservation widget is in the P17 tree — the plan's widget
  tree and the v1 owner rule only require the scrim + KidScope to paint to
  the physical edges (verified by the geometry test).

## Verification

- `dart format` clean on `lib/features/parental_gate` +
  `test/features/parental_gate`.
- `flutter analyze lib/features/parental_gate test/features/parental_gate`
  → No issues found.
- `flutter test test/features/parental_gate` → 38/38 pass (2a's 22 plus my
  16).
- No simulator use, no `flutter clean`, no `Interactive` run, no hard-coded
  colours/sizes (tokens only), no `subscription_status` writes, no imports of
  `google_fonts`.

## LEFT FOR NEXT ITERATION

- Geometry position of the modal (y band) is measured by the UI stage (5_ui)
  on the single permitted simulator; the node rectangles this layer asserts
  are the spec values the UI stage compares against. If the UI check finds a
  uniform vertical shift, the place to adjust is the `Center`/LayoutBuilder
  wrapper above — the chrome inside must stay token-exact.
- `parental_gate_placeholder_card.dart` is now unused; left in place because
  file removal is not billed to this layer and any deletion will be picked up
  by the next safe-refactor / shared cleanup pass.

VERDICT: PASS
