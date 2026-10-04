# K01 · Who's playing? — build plan (Stage 1)

Route `/who-is-playing` (kid mode) · feature `kid_home` · view `ProfilePickerView`.
Sources: `design/html-source/screens/K01-profile-picker.html`,
`design/screens/light|dark/K01-profile-picker.png` (÷3 = logical px),
`DESIGN_SPEC.md` §5 K01, `SPACING_SPEC.md` §§2/7/8/10/11.

## 0. Copy (character-exact from the HTML source)

- Title: `Who's playing?` — ASCII apostrophe U+0027, exactly as the HTML
  source holds it (`<h1 …>Who's playing?</h1>`, raw byte `0x27`; corrected
  iteration 3 — this line previously asserted U+2019 without citing the
  source, which shipped BUG-A. The repo convention is "match your own HTML
  source": `&rsquo;` screens ship U+2019, straight-`'` screens like K01/K03
  ship ASCII. Pinned by `k01_copy_parity_test.dart`, 13/13 green.)
- Sub: `Tap your face to start`
- Tiles: `Maya` / `Age 7–9`, `Leo` / `Age 4–6` — U+2013 EN DASH (`&ndash;`), NOT hyphen.
- Caption: `Grown-ups: tap the lock to get back to your dashboard.` — ASCII hyphen in `Grown-ups`.
- Lock `aria-label="Grown-ups"` → `semanticLabel: 'Grown-ups'`.
- Pet alt text → semantics: Maya `Pip the Fledgling`, Leo `Pip the Hatchling`.

## 1. Widget tree (top → bottom, logical px, tokens only)

Canvas 390×844. No bottom bar on this screen, so the meadow runs to the
physical edge (correct per design; the bottom-edge owner rule only constrains
the area below a bar — there is none here).

```
KidScope()                                  // sky gradient + 390×136 meadow hill, default height
└─ Scaffold(backgroundColor: transparent)
   └─ Column
      ├─ NestStatusBar()                    // reserves 47; OS draws glyphs (ignore in checks)
      ├─ Padding(20, 0, 20, 4)             // .k1-top: y 47..107
      │  └─ Row(mainAxisAlignment: end)
      │     └─ NestLockButton(large, semanticLabel 'Grown-ups')  // 56×56 r18, x 314..370 y 47..103
      ├─ Expanded                            // .scroll: side padding 20, bottom 32
      │  └─ SingleChildScrollView(padding: 20,0,20,32)
      │     └─ Column
      │        ├─ SizedBox(h:16)
      │        ├─ NestBalancedText("Who's playing?", kidTitle 28/34 w900 ink, center, maxLines 2)
      │        │   // .kid-title has text-wrap:balance (components.css:36) → NestBalancedText (mandatory)
      │        │   // est y 123..157
      │        ├─ SizedBox(h:16)
      │        ├─ Text("Tap your face to start", kidBody 18/26 w700 ink2, center, maxLines 2)
      │        │   // est y 173..199
      │        ├─ SizedBox(h:16)
      │        ├─ Expanded/flex-centered tiles band (.k1-mid flex:1 centers tiles vertically)
      │        │  └─ LayoutBuilder → Row(spacing 16)  // .k1-tiles gap 16
      │        │     └─ 2 × Expanded _ProfileTile (tile w = (390−40−16)/2 = 167; 132 at 320w)
      │        ├─ SizedBox(h:16)
      │        └─ Text(caption, 15/20 w700 ink2, center, maxLines 3)  // .kcap; est y ≈657..697
      └─ NestHomeIndicator()                // no-op in app (OS draws pill); kept for gallery
```

`_ProfileTile` (one per child, in `presentation/widgets/profile_tile.dart` or
private in the view file — builder's choice, feature dir only):
`Material(surface, r32, border 3×ink, kidShadow)` + `InkWell` →
`Padding(20 top/bottom, 10 sides)` → `Column(center, spacing 8)`:
1. `NestAvatar(initial 'M'/'L', s96, lilac/peach)` — 96 circle (same
   `_avatarColor` switch as `kid_home_view.dart:20`; REUSE by extracting to a
   shared feature-private helper, do not duplicate the switch twice).
2. `Text(nickname, 28/32 w900 ink, maxLines 1, ellipsis)` — `.k1-name`
   (28 px, NOT `kidTitle`; call-site `TextStyle` via `NestType.h1` — h1 is
   exactly 28/34 w900 — with `copyWith(height: 32/28)`; letterSpacing stays 0).
3. `Text('Age 7–9', 15/20 w700 ink2, maxLines 1)` — `NestType.kidCaption`.
   DB stores `ageBand` as `7-9` (hyphen); display replaces `-` with `–`
   (U+2013). Empty band → omit the line (keep the 8-gap: use `SizedBox` so both
   tiles stay the same height).
4. `SizedBox(h:10)` on top of the gap (`.k1-pet margin-top:10` + column gap 8).
5. `Container(132 circle, lilacTint / peachTint)` → centered
   `PipAvatar(size 112)` — the child's OWN Pip (orchestrator PIP rule):
   Maya `mochi/sunny/none/stage 3`, Leo `bolt/sky/none/stage 2`, mapped with the
   same `_pipStyle/_pipSkin/_pipAccessory` switches as `kid_home_view.dart:32`
   (extract to the same feature helper). Semantics on the circle:
   label `Pip the Fledgling` / `Pip the Hatchling`, `image: true`,
   wrapping an `ExcludeSemantics` Pip (PipAvatar has internal gestures).
6. Tile min-height 336: content sums to ≈346 (20+96+8+32+20+18+132+20), so the
   min is satisfied naturally; assert `≥336` in geometry test.

Tile vertical position is NOT a fixed offset: `.k1-mid{flex:1}` centers the
tiles in the leftover space (est band ≈295..641, caption ≈657..697, all ±tbd by
UI check ±2 px). Implement with `Expanded` + `Center`/`align center`, never a
hard-coded `SizedBox`.

Narrow-width rule (320 px): tile w = 132, content w = 112 < pet 132 and avatar
96 + tight. `LayoutBuilder` on the tiles row: when tile width < 150 use compact
metrics — avatar s64, pet circle 96 with Pip 80, name stays 28 (ellipsis).
Must not overflow at 320 w + textScaler 1.3 (test it).

Dark mode: zero branches — tokens flip (tile border ink → near-white,
surface → #1F1C2E, pet circles → dark tints, meadow → dark greens). Verify
against the dark PNG in the UI stage.

## 2. BLoC + repository (Drift, additive only — K02–K05 share this bloc)

`watchProfiles()` already exists and returns creation order (Maya, Leo) via
`watchChildren` (`app_database.dart:499`; CHILD ORDER ruling satisfied — do NOT
re-sort). `KidChild` has NO `ageBand` yet — the builder MUST add it:

- `domain/entities/kid_child.dart`: add `required this.ageBand` (+ props).
  Update ALL existing constructors in feature tests (compiler will list them).
- `data/kid_home_repository_impl.dart` `_toChild`: map `ageBand: row.ageBand`.
- `domain/kid_home_repository.dart`: add `Future<void> setActiveChild(String childId);`
- impl: `(db.update(db.appState)..where((a) => a.id.equals(1))).write(
  AppStateCompanion(activeChildId: Value(childId)))` — needs `drift` import;
  `AppStateCompanion` is generated. (No `AppSession` dependency — the repo
  owns its writes like `completeQuest` does.)
- `presentation/bloc/kid_home_state.dart` (additive fields only):
  `profiles = const <KidChild>[]`, `selectedProfileId` (nullable, one-shot).
- `presentation/bloc/kid_home_event.dart`: `KidHomeProfilesRequested`,
  `KidHomeProfileSelected(childId, pinSet)`, internal
  `KidHomeProfilesReceived(profiles)`, `KidHomeProfilesFailed(error)`.
- `presentation/bloc/kid_home_bloc.dart`:
  - On `KidHomeLoadRequested` (already sent by the route builder): keep the
    existing `_homeSub` guard untouched, ADD a guarded `_profilesSub` with the
    same pattern (`emit.forEach`-equivalent via listen → add Received/Failed;
    cancel on error and on `close()`).
  - On `KidHomeProfileSelected`: `await _repository.setActiveChild(childId)`
    then `emit(state.copyWithSelection(childId))`; on error emit
    `withCompletionFailed`-style action error (reuse `actionError/actionNonce`
    + toast copy `Hmm, that did not work. Try again.`). NO navigation in bloc.
  - `copyWith` must carry `profiles`/`selectedProfileId` through (check every
    existing `copyWith`/`withCompletion*` constructor call — a dropped
    `profiles` list blanks the picker after any quest completion emit).

K02 contract (same feature, coordinate — do NOT edit K02's view):
tile tap pushes with `extra: {'childId': id}` —
`KidHomeRoutePaths.pin` when `pinSet` is true, else `KidHomeRoutePaths.home`.
K02 owns reading the extra.

## 3. Interactions → navigation

| Control | Action | Destination |
|---|---|---|
| Profile tile (whole tile is the button, ≥56 everywhere) | `add(ProfileSelected)` → `BlocListener(selectedProfileId)` pushes (tile-local `_busy` guard, K03 `_QuestCard` pattern) | pinSet → `/kid-pin`, else → `/kid-home` (`KidHomeRoutePaths`), extra `{'childId': id}` |
| Lock `Grown-ups` | `context.push(ParentalGateRoutePaths.gate)` (`/parental-gate`), `_busy` guard (copy K03 `_GateLockButton`) | parental gate modal |
| Try again (failure) | `add(KidHomeLoadRequested)` — must work because error path releases subs (K03-BUG-15 pattern) | stays, stream re-emits |

Semantics (ACCESSIBILITY rule): tile root is
`Semantics(button: true, label: '$nickname, Age 7–9', onTap: <same handler>)`
wrapping `ExcludeSemantics` content — the `onTap:` ON the excluding node is
mandatory. Lock already exposes tap via `NestLockButton`. Tests assert
`hasAction(SemanticsAction.tap)` on both tiles + lock, and that
`performAction(tap)` on a tile writes `activeChildId` to the DB.

## 4. Empty / loading / error

- `initial/loading`: `KidScope` + status bar + lock row + centered
  `CircularProgressIndicator(tokens.leaf)`, `Semantics(label: 'Loading profiles')`.
- `failure`: centered column — neutral `PipAvatar(mochi, stage 1, size 140)`,
  `h2` `Oh no! Pip got lost.`, body `Let's try again.`,
  `NestKidButton.white('Try again')` → reload (K03 `_KidFailure` pattern).
- `loaded` with `profiles.isEmpty` (Seed.empty): title + sub + message
  `Ask a grown-up to add your profile.` (kidBody, ink2, center) in place of the
  tiles; lock row still present. (Design shows no empty state; this text is
  specified here.)

## 5. Accessibility / robustness checklist

- Tap targets: tiles ≈167×346, lock 56×56. Nothing below 56.
- Text: all kid text Nunito ≥15 px (name 28, age/caption 15 — caption matches
  the HTML's 15 px `.kcap`).
- `textScaler` 1.0–1.3 (app clamp) + 320 px width: no overflow (compact metrics
  §1 + widget test).
- VoiceOver/TalkBack order: title → sub → Maya tile → Leo tile → caption →
  lock (lock is last in paint order — top-right visual, acceptable as the
  design's escape hatch; keep DOM order = visual column order).
- No `DateTime.now()`, no dates, no money on this screen — KNOWN RED
  date-failures do not apply; do not touch them.
- No `google_fonts` / `GoogleFonts.*` anywhere (also scrub feature tests).
- No `letterSpacing` additions (design CSS sets none on these elements).

## 6. Test plan (all in `app/test/features/kid_home/`; end every pump with `disposeApp(tester)`)

New `k01_profile_picker_test.dart` (widget, seeded demo DB):
1. Renders `Who's playing?` / `Tap your face to start` / caption with exact
   code points (assert the U+2019 and U+2013 explicitly).
2. Two tiles in order Maya-then-Leo (`ValueKey('k01-tile-maya')`,
   `ValueKey('k01-tile-leo')`), ages `Age 7–9` / `Age 4–6`.
3. `PipAvatar` params per tile: Maya mochi/stage 3, Leo bolt/stage 2
   (predicate on widget fields, `riveEnabled: false` in tests).
4. Tile tap → DB `activeChildId == 'maya'` AND route `/kid-pin` (Maya pinSet);
   Leo → `/kid-home`? (Leo pinHash — seed sets only Maya's `1234`? verify from
   seed: Leo `pinHash` absent → pinSet false → `/kid-home`. Assert per actual
   `pinSet` values, not assumptions.)
5. Semantics: every tile + lock `hasAction(tap)`; `performAction(tap)` on Maya
   tile writes DB.
6. Lock tap → `/parental-gate`.
7. Loading / failure (+Try again reloads) / empty (no-children message).
8. 320 px wide + `textScaler 1.3`: `tester.takeException` is null, no overflow
   banners; light + dark theme pump.
Bloc test: profiles arrive Maya-first; `ProfileSelected` writes `app_state` and
emits `selectedProfileId`. Repo test: `watchProfiles` creation order;
`setActiveChild` persists. Geometry test: tile rects — border 3, radius 32,
gap 16, widths 167 @390; pet circle 132, Pip 112; lock 56 at x 314.

## 7. SHARED_REQUEST

None. Everything needed is inside the feature dir (`kid_child.dart`,
`kid_home_repository.dart`, impl, bloc, views, widgets) plus existing shared
components (`KidScope`, `NestStatusBar/HomeIndicator`, `NestLockButton`,
`NestAvatar`, `NestBalancedText`, `NestKidButton`, `PipAvatar`, `NestType`,
`NestSpacing`). No core/route/seed changes. No `SHARED_REQUEST.md` file.

VERDICT: PASS
