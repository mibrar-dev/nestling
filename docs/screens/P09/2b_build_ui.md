# P09 — 2b build, UI chunk (iteration 6)

Tree: `884566c` (main `6be6ffe` merged in) + the diff below.
Scope held: `app/lib/features/quests/presentation/views/**`,
`presentation/widgets/**`, and the view/widget tests
(`quest_editor_view_test.dart`, `quest_editor_view_geometry_test.dart`).
No `domain/`, `data/` or `bloc/` edit; no shared file; no simulator booted;
no `flutter clean`; no `google_fonts`; no `// ignore:`.

## CONTRACT CHANGES read before finishing

Re-read `2a_build_logic.md`. It carries **no shape changes** — the only
contract edit was `_checkCoins` throwing `ArgumentError` unconditionally
(last iteration) and a reworded domain doc. Its two flags for me:

- the CLOCK-rule call on the view's id mint ("yours if the orchestrator wants
  the rule applied to id minting too") — still **not** actioned, see
  §3 below;
- `appNowUtc()` is already in place (so no `DateTime.now()` in the feature).

`ORCHESTRATOR_NOTES.md` (09:27) mandates BUG-P09-14 → `newId('q')` from
shared. `git grep newId origin/main -- app/lib/core` is **empty**: shared/
unique_ids has not landed on main yet, so the mandated call cannot be made
here. No substitution invented (see §3).

## 1. Fixed — P09-TEST-9: the switch rode high whenever the text wrapped

**Was:** `Positioned(top: QuestEditorMetrics.approvalTrackTopInCard /* 20.5 */,
right: NestSpacing.s4, child: NestToggle(...))` — 20.5 is the design frame's
centred offset (16 padding + (40 − 31) / 2), a measurement of ONE metric, not
the CSS rule. `3_test.md` §4.3 measured the track 20 / 29 / 43.5 px above the
text-block centre at 390/320 × scale 1.0/1.3.

**Now:** the card's own height drives the offset, so the track is centred by
layout (`.switchrow { align-items: center }`) at every metric:

```dart
Positioned.fill(
  child: LayoutBuilder(
    builder: (context, constraints) => Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: (constraints.maxHeight - QuestEditorMetrics.approvalTrackHeight) / 2,
          right: NestSpacing.s4,
          child: NestToggle(...),
        ),
      ],
    ),
  ),
),
```

`QuestEditorMetrics.approvalTrackTopInCard = 20.5` is **deleted** (no
references left); the two design measurements that replace it are
`approvalTrackWidth = 51` / `approvalTrackHeight = 31` (`.toggle` in
`components.css`), already used by the row's slot and now by the offset.

**The design rect is unchanged at 390** — measured after the fix:
track `303 / 620.5 / 51 / 31`, card `20 / 600 / 350 / 72`, i.e. (72 − 31) / 2
= 20.5 card-local → 620.5 global, `closeTo(303/620.5/354/651.5, ±2)` in
`quest_editor_view_geometry_test.dart` green (the ALIGNMENT owner's ±2 px rule
holds, no uniform shift).

### 1.1 The part that cost the iteration: centring fought the hit slop

BUG-P09-10's three proofs (5 px above, 5 px below, 2 px right of the track)
are in `p09_bugs_test.dart` — not my file, but they must stay green, and they
failed on the first two structurally-obvious attempts. Root cause, now
documented in the code:

> `RenderBox.hitTest` **bounds-checks every ancestor box** before descending
> (`if (_size!.contains(position))`). Only the toggle's own
> `_RenderToggleHitSlop` overrides `hitTest` to accept its 4 px overhang. So
> every box between the card and the track must CONTAIN the 59×44
> `.toggle::before` area, or the design's own slop taps are silently eaten and
> the switch stops responding there.

Measured, each attempt verified against all three proofs:

| shape | track rect | 5 px above | 5 px below | 2 px right |
|---|---|---|---|---|
| `Positioned.fill` + `Padding(right:16)` + `Align` | 303 / 620.5 ✓ | pass | pass | **fail** |
| `Positioned.fill` + `Align` + `Padding(right:16)` | 303 / 620.5 ✓ | **fail** | **fail** | pass |
| `Positioned.fill` + `Align` + `SizedBox(51+16)` | **319 / 620.5 ✗** | fail | fail | fail |
| `Padding` wrapping the Stack (content-box centring) | 303 / 620.5 ✓ | **fail** | **fail** | pass |
| `Positioned(top:0,bottom:0,right:16)` + `Align` | 303 / 620.5 ✓ | pass | pass | **fail** |
| **`Positioned.fill` + `LayoutBuilder` + `Stack` (shipped)** | 303 / 620.5 ✓ | pass | pass | pass |

Two lessons written into the code comments: a `RenderPadding` region bounds-
checks, and a `SizedBox` sizes to its child (`RenderConstrainedBox` does
`size = constraints.constrain(child.size)`), so it cannot reserve an inset at
all — that variant put the track flush to the card edge at 319→370. The shipped
shape keeps the toggle a **direct loose-slot child of a Stack that covers the
whole slop** and moves the centring into the offset itself.

### 1.2 Tests

- `quest_editor_view_geometry_test.dart`: new group **"P09 approval toggle is
  centred at every metric"** — 390/320 × scale 1.0/1.3. Asserts the track's
  midpoint equals the card's midpoint (±1), flush to the content edge
  (`card.right − 16`, 0.01), clear of the sub-line, and inside the card. Those
  four cases are exactly the frames on which the old offset drifted.
- `quest_editor_view_test.dart`: the UI-verdict test's two hard-coded
  assertions were the old behaviour written down — `toggle.center.dy ==
  approval.top + 36` and `toggle.top == approval.top + 20.5`, i.e. a 72-high
  card baked in while that file's widget-test font makes the sub-line wrap and
  the card taller. Replaced with the centring contract (`approval.center.dy`,
  and `(approval.height − 31) / 2`), with the design-frame value (620.5) kept
  in the comment. Nothing weakened: the file now asserts the stricter property
  (centre of the CARD at any height) and the design rect still lives, in
  strict ±2 px form, in the real-font geometry test.

## 2. Verified, not changed

Re-measured against the design (real bundled fonts, 390×844) — all inside the
owner's ±2 px, no uniform shift, so nothing was moved: sheet `0/47/390/797`,
grabber `175/59/40/5`, Save pill `296/80/74/44`, field `20/156/350/52`,
icon tiles `20 + i*61.2 / 232`, person pills `20/300`, reward card
`20/364/350/76`, segmented `20/480/350/52`, day cells `20 + i*51 / 540`,
approval card `20/600/350/72`, track `303/620.5/51/31`, due card
`20/684/350/88`, sheet paper to the physical bottom edge (BOTTOM-EDGE rule),
20 px gutters on both sides throughout (ALIGNMENT rule), dark mode identical,
copy unchanged (no `google_fonts`, no tracking added), no `NestBalancedText`
needed (no `text-wrap: balance` in this screen's CSS), no `NestChip` rows,
PIP rule n/a (parent screen, no Pip), child order Maya→Leo unchanged, trial /
period rules untouched (no logic in this chunk).

## 3. Not actioned here — and why

- **BUG-P09-14 / P09-TEST-7 (major, `p09_bugs_test.dart:645`, the feature's
  one `skip:`)** — new-quest ids are `q-${appNowUtc().millisecondsSinceEpoch}`,
  which the pinned test clock freezes. `ORCHESTRATOR_NOTES` 09:27 says to use
  shared `newId('q')`; that helper **does not exist on main yet**
  (`git grep newId origin/main -- app/lib/core` → empty), so the mandated fix
  cannot be written. Substituting a local random suffix would (a) duplicate the
  shared helper the orchestrator is already building and (b) break
  `quest_editor_states_test.dart:578` — not my file, not my stage. **Left for
  the next iteration**, one line in `quest_editor_view.dart` once `newId`
  merges.
- **P09-TEST-8 (major)** — `_editorError` in `quests_bloc.dart` lets a
  non-`ArgumentError` (e.g. a `SqliteException`) reach the toast verbatim. That
  is `presentation/bloc/**`, the logic builder's layer, and not a UI/copy
  item. Left for the logic builder.
- The `p09_bugs_test.dart` un-skip for BUG-P09-14 belongs to the bugs stage
  (that file is not a view/widget test). Recorded, not done.

## 4. Gates (this layer only — integrator owns the whole app)

```
$ dart format lib/features/quests test/features/quests     → 0 changed
$ flutter analyze lib/features/quests test/features/quests  → No issues found!
$ flutter test test/features/quests/                        → 00:24 +413 ~1: All tests passed!
```

The single `~1` is stage 6's parked BUG-P09-14 (above). Before this iteration
the same suite was `+412 ~1 -1`; the count grew by the four new centring
tests. Whole-app `flutter test` and every simulator deliberately NOT run; no
simulator was booted, installed on, screenshotted or driven. Both scratch
files created while measuring the hit-region behaviour were deleted.

## 5. LEFT FOR NEXT ITERATION

1. **BUG-P09-14** — swap `'q-${appNowUtc().millisecondsSinceEpoch}'` for
   `newId('q')` once shared/unique_ids is on main, then have the bugs stage
   un-skip `p09_bugs_test.dart`'s proof.
2. **P09-TEST-8** — bloc `_editorError` mapping (logic layer).
3. Optional design-system note, not filed yet because it is not blocking: the
   reason P09-TEST-9 could not simply be "use `Align`" is that centring a
   switch this way silently eats its own 4 px hit slop. A DS-level fix would
   be a centring variant of `NestToggle` (e.g. one that keeps the track inset
   inside its own 59×44 bounds), which would remove the whole class of
   `Positioned`-offset compensation from every screen that overlays a switch.

VERDICT: PASS