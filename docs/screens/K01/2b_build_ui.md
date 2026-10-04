# K01 · Who's playing? — Stage 2b (BUILD, UI CHUNK, iteration 1)

## Files changed (UI layer only)

- `app/lib/features/kid_home/presentation/views/profile_picker_view.dart`
  — replaced the placeholder with the real K01 screen.
- `app/lib/features/kid_home/presentation/widgets/profile_tile.dart`
  — new `ProfileTile` (the `.k1-tile` card).
- `app/lib/features/kid_home/presentation/widgets/kid_style_helpers.dart`
  — shared `avatarColorOf` / `pipStyleOf` / `pipSkinOf` /
  `pipAccessoryOf` / `pipStageName` switches, extracted from
  `kid_home_view.dart` (which now imports them; no duplicated switch).
- `app/lib/features/kid_home/presentation/views/kid_home_view.dart`
  — only the import swap + switch removal above; layout untouched.
- `app/test/features/kid_home/k01_profile_picker_view_test.dart` — new
  (seeded-demo widget tests).
- `app/test/features/kid_home/k01_profile_picker_geometry_test.dart` —
  new (real-font geometry pins).
- `app/test/features/kid_home/kid_home_view_test.dart` — two stale
  assertions on the old K01 placeholder (`'K01 Who is playing'`) updated
  to the real screen's `'Tap your face to start'`.

## What the view does

- `KidScope` + transparent `Scaffold`. Column: `NestStatusBar` (height
  only), lock row (`Padding(20,0,20,4)` → `NestLockButton` 56, r18,
  `semanticLabel: 'Grown-ups'`, busy-guarded push to `/parental-gate`),
  then the body, then `NestHomeIndicator` (no-op in-app).
- Loaded body: `NestBalancedText("Who’s playing?", kidTitle, maxLines 2)`
  → `Tap your face to start` (`kidBody`, ink2) → **tiles band**
  (`Expanded` + `Center`, `.k1-mid` flex-centre) → caption
  `Grown-ups: tap the lock to get back to your dashboard.`
  (`kidCaption`). Title→sub→band→caption gaps are 16 each, bottom pad 32.
- Tiles: `Row(spacing: 16)` of two `Expanded(ProfileTile)`; Maya, then
  Leo, in `state.profiles` order (repo guarantee, never re-sorted).
- `ProfileTile`: container with surface fill, 3 ink border, r32,
  `kidShadow`, `min-height: 336`, centred Column (gap 8): `NestAvatar`
  s96 → name (h1 28/34 w900, overridden to 28/32 via `copyWith`) → age
  (`kidCaption`, DB `7-9` → `Age 7–9` U+2013; empty band gets a 20-tall
  slot so both tiles keep identical heights) → pet circle (132, padded
  10 above the gap) → `PipAvatar(size: 112)` driven by the child's
  `pipStyle/pipSkin/pipAccessory/pipStage` (Maya mochi/sunny/none/3,
  Leo bolt/sky/none/2). Pet circle tint: lilac for Maya, peach for Leo,
  matching `.k1-pet` / `.k1-pet.p2`, mirrored for other avatar colours.
- Compact rule: tile width < 150 → avatar s64, pet 96, Pip 80, name
  stays 28 (ellipsis). Verified at 320 px + textScaler 1.3, no overflow.
- Selection: tile tap → `KidHomeProfileSelected(childId, pinSet)` →
  `BlocListener(selectedProfileId)` pushes `pinSet ? /kid-pin :
  /kid-home` with `extra: {'childId': id}`. No navigation in the bloc.
- Selection failure: same-style toast `Hmm, that did not work. Try
  again.` via the shared `actionError`/`actionNonce` channel.
- States: loading → `CircularProgressIndicator(tokens.leaf)` with
  `Semantics('Loading profiles')`; failure → Pip (mochi, stage 1,
  140) + `Oh no! Pip got lost.` / `Let's try again.` /
  `NestKidButton.white('Try again')` → `KidHomeLoadRequested`;
  loaded-empty roster → `Ask a grown-up to add your profile.` in the
  tiles band (lock row and title kept).
- Accessibility: tile root `Semantics(button, label: '<name>, Age
  7–9', onTap)` with `excludeSemantics: true` (mirrors
  `NestKidQuestCard`), the pet circle carries its own
  `Semantics(image: true, label: 'Pip the Fledgling' |
  'Pip the Hatchling', excludeSemantics: true)`, lock advertises
  `Grown-ups` — all tap-action tested via `performAction`.
- Dark mode: zero branches — all colours come from `context.nest`.

## Layout notes / deviations

- The plan's tree puts `Expanded` inside the `SingleChildScrollView`
  column, which is not a valid flex context; implemented as K03-style
  fixed header/footer with a bounded, scrollable tiles band in the
  middle (`ConstrainedBox(minHeight: viewport)` + `Center`), so the
  tiles still centre in the leftover space at 390×844 and the band
  scrolls under 320 px + 1.3 scaling. At design size the result is the
  same box positions.
- `.k1-pet` is `gap 8 + margin-top 10` = 18 above the pet circle;
  done with a 10-padded pet circle inside the gap-8 column (the plan's
  literal `SizedBox(h:10)` between two gap-8 edges would have read 26).
- Tile content stacks taller than the design's 336 floor (≈346–354
  with the 28/32 name line); the design's `.k1-tile` min-height is
  satisfied and nothing reflows.

## Tests

- `k01_profile_picker_view_test.dart` (13): exact copy incl. U+2019 /
  U+2013, Maya-then-Leo keys, per-child `PipAvatar` params (+no v1
  art), tap Maya → DB `maya` + `/kid-pin`, tap Leo → DB `leo` +
  `/kid-home`, lock → `/parental-gate`, semantics tap actions incl.
  `performAction` writes the DB, loading, failure + Try-again recovery,
  empty roster, 320 px @1.3 light + dark.
- `k01_profile_picker_geometry_test.dart` (4): lock 56 at x 314, y 47;
  tile width 167, gap 16, border 3 ink, radius 32, min-height 336,
  20 px gutters; pet circle 132 centred with Pip 112 centred inside;
  pet tints lilac/peach.

Verification: `flutter analyze lib/features/kid_home` — no issues; new
view + geometry tests all green (13 + 4).

## LEFT FOR NEXT ITERATION

- Nothing blocking. Optional polish: a frame-by-frame UI capture stage
  (5_ui) comparison against both PNGs; compact-metric tile at 320 px is
  covered by overflow asserts only.

VERDICT: PASS
