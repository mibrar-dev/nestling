# K01 · Who's playing? — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/who-is-playing` (feature `kid_home`, mode kid) on the
merged base (`7e46483`, main merged). Every proof lives in
`app/test/features/kid_home/k01_bugs_test.dart` and is backed by the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake for failure paths. No screen code was changed.

Verification commands:

```
flutter test test/features/kid_home/k01_bugs_test.dart
  → +13 ~7: All tests passed!      (7 proofs parked with skip: true)

flutter test --run-skipped test/features/kid_home/k01_bugs_test.dart
  → 7 failures, one per open bug below
```

| # | Severity | Status | Area |
|---|---|---|---|
| K01-BUG-1 | major | open | 3+ children collapse the tile row |
| K01-BUG-2 | major | open | two-finger tile burst navigates twice |
| K01-BUG-3 | major | open | a tile is dead after returning from a route |
| K01-BUG-4 | minor | open | empty nickname → unlabelled tile |
| K01-BUG-5 | major | open | Try again cannot recover from a profiles failure |

Also already tracked by the other stages (referenced, not re-proved here):
5_ui D1 (tiles band 16.5 px low) and D2 (caption 34 px low) — the
orchestrator notes say to fix both in the next build; D3/D4 (meadow) are the
shared `kid_meadow` work, not a K01 finding.

---

## K01-BUG-1 — major — 3+ children collapse the tile row

`_PickerLoaded` lays every profile out in ONE fixed `Row` of `Expanded`
cards (`profile_picker_view.dart:252-270`). Two children give the design's
167 px tiles; each extra child shrinks every tile without floor or scroll,
past the point where the compact metrics fit.

**Repro (widget test, 390×844, Seed.demo + inserted children):**

- +1 child (Nina) → tiles `[106, 106, 106]` px (design 167, compact minimum
  132); the 96 px pet disc is clamped to 86×96 — an ellipse, not a circle.
- +2 children (4 total) → tiles 75.5 px; the 64 px avatar disc renders
  49.5×64.
- +4 children (6 total) → tiles `[45 × 6]` px; 20 px padding leaves 25 px
  of content for a 64 px avatar and an 80 px Pip.

**Failing tests:**

- `K01-BUG-1 — 3+ children collapse the tile row a third child shrinks every tile below the compact minimum`
- `... at 4+ children the pet disc/avatar stop being circles`
- `... six children leave 45 px slivers (design tile: 167)`

**Suggested fix:** make the tiles band scroll horizontally (or wrap) when
`profiles.length > 2`, keeping the design tile width (167 at 390) and the
20 px gutters; never let a tile shrink below the compact minimum (132).
The 1–2 child layout stays as designed.

## K01-BUG-2 — major — two-finger tile burst navigates twice

Each tile has its own `_busy` latch (`profile_tile.dart:36-43`), so a touch
on Maya does not block a simultaneous touch on Leo. Both
`KidHomeProfileSelected` events write `app_state` and both one-shot
emissions reach the picker's `BlocListener`, which pushes `/kid-pin` and
`/kid-home` on top of each other. The last DB write wins the active child,
and one back press lands on the other child's screen.

**Repro (widget test):** pointer 7 down on Maya + pointer 8 down on Leo,
both up in the same burst (before any frame). After settling: top route
`/kid-home`, `activeChildId == 'leo'`, and `K02 Kid PIN` is present in the
widget tree (`skipOffstage: false`) beneath it — two navigations for one
gesture burst.

**Failing test:** `K01-BUG-2: tapping Maya then Leo stacks two kid routes`.

**Suggested fix:** single-flight the picker navigation — a screen-level
latch set before `context.push` and cleared when the pushed route pops, or
`IgnorePointer` over the tiles while a selection is pending, or ignore
`KidHomeProfileSelected` in the bloc while `selectedProfileId` is
unconsumed. (Related observation, not a finding: because the first push
installs within the first tap's dispatch, a *sequential* second tap already
lands on the newly pushed route — e.g. a PIN keypad key. A one-frame
guard before navigating would remove that too.)

## K01-BUG-3 — major — a tile is dead after returning from a kid route

`selectedProfileId` is a one-shot that only clears on the next home-stream
emission (`copyWithLoaded`, `kid_home_state.dart:150-160`). After
`setActiveChild`, the clear emission races *ahead* of the selection emit
(Drift re-notifies `app_state`, the handler then emits `copyWithSelection`),
so the one-shot stays set. A second tap on the same child then emits an
`==`-equal state, the bloc drops it (Equatable), and nothing happens — no
navigation, no toast.

**Repro (widget test, Seed.demo where `activeChildId` is already `maya`):**
tap Maya → `/kid-pin`; back to the picker (`selectedProfileId == 'maya'`,
asserted); tap Maya again → the path stays `/who-is-playing` forever. The
same flow breaks after a Leo visit to `/kid-home`.

**Failing test:** `K01-BUG-3: tapping the same tile after back does nothing`
(the test asserts the mechanism first: `bloc.state.selectedProfileId` is
still `'maya'` instead of null).

**Suggested fix:** consume the selection instead of relying on a stream
emission — e.g. a `selectionNonce` that increments per selection (the view
navigates on nonce change), or a "selection handled" event the view
dispatches in the listener, or clear `selectedProfileId` after the push.
Keep navigation out of the bloc (existing contract).

## K01-BUG-4 — minor — empty nickname makes an unlabelled tile

`ProfileTile` builds its semantics label from the raw nickname
(`profile_tile.dart:53-57`); `''` yields an empty accessible name. The
avatar falls back to `'?'`, the label does not. P05's form blocks empty
names, but the DB/entity allow the row (edit paths, imports, future code).

**Repro:** insert `children(id: 'noname', nickname: '')`, pump the picker,
read the tile's semantics — `label == ''`.

**Failing test:** `a child with an empty nickname still has a usable label`.

**Suggested fix:** fall back to a stable label (e.g. `Kid`) when the
nickname is blank, and/or enforce non-blank nicknames at the DB/validation
layer.

## K01-BUG-5 — major — Try again cannot recover from a profiles-only failure

(Also stage-4 review finding 1.) The failure card can be shown when
`watchProfiles` errors while the home stream is healthy (it emits
`KidHomeData(child: null)` then stays quiet). `KidHomeLoadRequested` only
restarts the home stream when `_homeSub == null` (`kid_home_bloc.dart:52`)
and `copyWithProfiles` never touches `status` (`kid_home_state.dart:166`),
so a successful profiles retry leaves `KidHomeStatus.failure` forever — the
only write path (`setActiveChild`) is behind the failure card.

**Repro (fake repo):** `watchHome` yields `KidHomeData(child: null)`;
`watchProfiles` errors once, then yields Maya. Pump → failure card. Tap
Try again → the roster recovers but the card stays.

**Failing test:** `K01-BUG-5: Try again cannot recover from a profiles
failure`.

**Suggested fix:** in `_onProfilesReceived`, restore `loaded` when a
healthy roster arrives after a failure (and clear `errorMessage`); and/or
make Try again emit `loading` and restart the profiles stream when the home
subscription is still live.

---

## Checked clean (probes that pass and stay in the suite)

- **0 children** (`Seed.empty`): title, empty-roster message, lock, no
  tiles, no exception.
- **1 child**: single tile fills the 20 px gutters without overflow.
- **Long UK name** (`Maximilian-Alexander`) at 320 px + 1.3 scale: no
  exception, ellipsized inside the tile.
- **Empty age band**: line omitted, both tiles keep the same height/rhythm.
- **Money/timezone**: no `£`, coin count or date anywhere on the screen
  (probe), so £0.00/£999.99/9999-coin and BST rounding cases cannot occur
  here.
- **Rapid same-tile double tap**: one route (tile latch works).
- **Rapid lock double tap**: one gate route (`_busy` latch held over the
  awaited push).
- **Deep links**: `/who-is-playing` renders in kid and parent mode.
- **Restart persistence**: `setActiveChild` survives a file-backed DB
  reopen.
- **Copy**: U+2019 in the title, en dashes in `Age 7–9` / `Age 4–6`,
  ASCII hyphen in `Grown-ups` — per plan §0 and the house convention.
- **Semantics**: Maya's tile, Leo's tile and the lock all expose
  `SemanticsAction.tap`.
- **Dark mode**: all 16 token pairs used on the screen (sky top/bottom,
  meadow, surface, pet tints, avatar inks, light + dark) are ≥ 4.5:1.
- **320 px + 1.3 text scale** (real bundled fonts): title, sub and caption
  render in full; the balanced title box does not collapse.

## Cross-stage notes (not new bugs)

- **U+2019 vs ASCII apostrophe.** `k01_copy_parity_test.dart` (stage 3)
  asserts the title must be ASCII `Who's playing?` to match the HTML
  fixture, while `1_plan.md` §0, the view test, and P02/P03/P04/P07 all
  ship U+2019 and stage 5 explicitly ruled the U+2019 rendering not a
  defect. The two tests cannot both pass; this needs one orchestrator
  ruling (the UI stage and the shipped convention favour U+2019).
- **D1/D2 (layout).** Tiles band +16.5 px and caption +34 px versus the
  design are already in `5_ui.md` and `ORCHESTRATOR_NOTES.md` (fix in the
  next build). Not re-proved here.
- **D3/D4 (meadow hills).** Shared `kid_meadow` work per
  `ORCHESTRATOR_NOTES.md` — deliberately not reported as K01 bugs.
- **WIP files.** `k01_profile_picker_matrix_test.dart` was mid-write by the
  concurrently running stage 3 during this pass (analyzer errors there are
  that stage's in-flight work, not K01's).

VERDICT: FAIL
