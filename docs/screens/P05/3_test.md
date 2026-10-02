# P05 · Add children — test notes (STAGE 3, iteration 2)

Route `/add-children`, feature `family`, parent mode. All work is in
`app/test/features/family/` — **no screen code was touched** in this stage.

Iteration 1's `3_test.md` reported P05-BUG-1…3; the iteration-2 build stage
fixed them, so this stage's job was to (a) re-prove the fixed paths, (b) cover
the code the fixes introduced, and (c) re-verify the mandatory orchestrator
items on the real binary. Result: **no new bug found**, one open
device-only measurement handed to stage 4/5, and a green suite.

## What the iteration-2 build changed (and what the tests now pin)

| Change | Proof added |
|---|---|
| `FamilyChildrenRequested` deleted (dead event) | the two blocTests that used it were removed; roster + stream-failure paths are proven through `FamilyLoadRequested` (`add_children_test.dart` group *FamilyBloc roster*) |
| `lastSavedNickname` state field (P05-BUG-5 conditional clear) | `copyWith`/props/provenance unit test, bloc-level mid-save-typing test, widget test that the field keeps `Ada` typed mid-save and still clears on the next clean save |
| `if (state.saveInProgress) return;` (P05-BUG-2) | pre-existing proofs in `p05_bugs_test.dart`, plus a new interaction test: Continue during an in-flight save is inert (1 insert, no navigation, no inline error) and works again once the save settles |
| `_closeOnError` on the load subscription (P05-BUG-4) | `p05_bugs_test.dart` proof (2 subscribes / 1 cancel), plus a new test that the retry renders the roster and the retry panel is gone |
| `ageYears` derived from the band (P05-BUG-6) | `p05_bugs_test.dart` proof |
| `Semantics(header: true)` on the h1 (P05-BUG-7) | `p05_bugs_test.dart` proof |
| `IntrinsicWidth` per chip (P05-BUG-1) | font-robust geometry tests added below + real-font screenshot proof |
| Material/`InkWell` swatches, chip-group semantics, `Align(topCenter)` cards | swatch ring token test (dark), group-container semantics test |
| Continue reads `bloc.state.draftNickname` (review finding 9) | existing save/continue tests still green; the draft/field sync is now covered by the BUG-5 widget test |

## Tests added this iteration (27 new, in `add_children_test.dart`)

**Orchestrator-mandated UI state (`SEED=onboarding_kids`, item 2)** — 3 tests:
the seeded pair reaches the grid from the database and the route does **not**
redirect to `/welcome` even though `onboarding_complete = false` (the router's
`_onboardingLocations` allow-list); each card's avatar colour comes from its own
row (Maya lilac, Leo peach); saving from this seed appends and keeps all three.

**Age-chip row (mandatory item 1)** — 4 tests: every chip box is narrower than
the `Wrap` run, the leftmost chip starts exactly on the card's content edge
(left-aligned, not centred), same-row gaps are exactly 8 px, and no chip
overflows the content box at 320/1.0, 320/1.3 and 430/1.3.

**BUG-5 conditional clear** — 3 tests (see table). **BUG-2 interactions** — 3
tests: Continue mid-save, tapping the already-selected chip keeps it selected,
and a successful add-another restores focus to the nickname field so the next
child can be typed immediately.

**Failure recovery / robustness** — 4 tests: retry subscribes exactly once and
renders the roster (and the panel is gone, so it cannot be double-pressed);
a late empty roster emission collapses the grid without breaking the form; a
24-character nickname (the bloc's hard limit) ellipsizes inside the 135 px
column at 320/1.3× and stays inside its card; the inline error keeps the CTA on
screen and bottom-edge correct at 320/1.3× and 390/1.3×.

**Semantics / dark / owner rules** — extended: the chip and swatch groups are
labelled `container` semantics with their children still reachable; the whole
form is interactive in dark mode and the selected swatch's ring is `tokens.ink`
(light in dark) with spread 3 — matching the dark design's
`box-shadow: 0 0 0 3px var(--ink)`; the bottom-edge rule now runs at
320/390/430 in both themes; the failure panel's `Try again` is a 44+ target.

Family totals: **98 tests in `test/features/family/`** — 90 in
`add_children_test.dart` (63 after the build stage's two removals + 27 added
here) and 8 in `p05_bugs_test.dart`, zero skips.

## Results

```
dart format .        clean (358 files, 0 changed)
flutter analyze      No issues found!          (full app)
flutter test         00:13 +585: All tests passed!   (full suite)
```

Every test that pumps the app ends with `disposeApp(tester)`; the
router-only harness (`_pumpAppView`) replaces `disposeApp` with a
`pumpWidget(Container())` drain because it never opens the Drift scope.

## Bugs found

**None in this iteration.** All three iteration-1 bugs are fixed and proved;
`SHARED_REQUEST.md` #3 (the `NestChip` full-width `Center`) remains open at the
design-system level — the screen works around it locally with `IntrinsicWidth`,
which is verified below, but the shared fix is still owed.

### Mandatory items verified on the real binary

`shot.sh /add-children … light onboarding_kids parent maya` →
`docs/screens/P05/ui/iteration2_test_probe_light.png` (390×844 @3x):

1. **Age chips: FIXED.** Four pills (`4–6`, `7–9` selected, `10–12`, `13+`) in
   **one left-aligned row** with 8 px gaps, matching the design and the dark
   design. Verified against `nest_chip.dart:74`'s full-run `Center`.
2. **Kids from the database: OK.** Maya (`Age 7–9`, lilac) and Leo (`Age 4–6`,
   peach) render from `SEED=onboarding_kids` with edit pencils.
3. **Header offset: FIXED.** The shared 60 px compact nav landed; the app's h1
   ink now sits at y 112.3–138.0 and the sub at 155.0–170.0 — **pixel-identical
   to `design/screens/light/P05-add-children.png`**.
4. **Bottom edge + alignment: hold.** CTA surface runs to the physical edge;
   20 px gutters with head/cards/form/CTA/caption on the same edges (proved in
   tests at 320/390/430).

### Open item for stage 4/5 — vertical rhythm around the kid grid (measured)

Measured from the PNGs above (logical px, ÷3):

| | design | app (iter 2) | Δ |
|---|---|---|---|
| h1 ink | 112.3–138.0 | 112.3–138.0 | 0 ✓ |
| sub ink | 155.0–170.0 | 155.0–170.0 | 0 ✓ |
| kid grid top | 187 | 234 | **+47** |
| kid card height | 116 | 124 | +8 |
| form card top | 315 | 404 | **+89** |
| form card internals (h3 → "Nickname") | 33.3 | 33.3 | 0 ✓ |

So ~45 px of empty space appears **above** the grid and ~34 px **below** it
(the two `SizedBox(gap14)` / `SizedBox(s3)` gaps measure ≈59 and ≈46 on device).
Two facts bound this down:

* With **no grid** (`SEED=fresh`, iteration-1 shot) the same code path measures
  exactly the design rhythm: form card top = 183 with the then-current nav,
  i.e. `14 + 12` from the end of the sub — **no inflation**.
* In **widget tests** the grid is at `sub + 14` and the form card at
  `grid bottom + 12`, exactly as written, for 1/2/3/5 children at every width
  and scale.

So the extra space appears only when the shrink-wrapped `GridView` is a child
of the `ListView` (`kid_card_grid.dart:20-47`), and only on the simulator. The
card itself is not the cause: the tile measures 124 px on device, exactly
`cardH` for `textScaler == 1.0` (the card's text never overflows it — no debug
stripes in the shot), and the form card's internals are pixel-identical to the
design, so the whole block is rigid and just sits 89 px low.

Prime suspects, in order: (1) the nested `LayoutBuilder` + `GridView(
shrinkWrap: true)` extent when the real fonts are loaded (GoogleFonts fetches
Nunito/Inter at runtime — they are not bundled in `pubspec.yaml`, so tests run
with the fallback font and cannot reproduce it); (2) the 8 px card height
(`cardH` adds a trailing `gap10` pencil clearance the design does not have, and
drops the design's extra 2 px gap before the age line).

**Not patched** — it is a visual-band question owned by stage 4/5 (compare.py),
and the evidence above is what they need to re-measure after re-shooting.
Re-running the iteration-1 numbers (light 6.61% / dark 6.76% drift) is
meaningless: the chips and the header are fixed and the seed now carries kids.

## Noted, not bugs

* **Roster order** (iteration-1 P05-BUG-3): `watchChildren` orders by nickname,
  so Leo renders left of Maya while the design mock shows Maya first. Unchanged
  by design (DB is the source of truth); still pinned by a test, and visible in
  the UI-check seed — the orchestrator owns the mock-vs-ordering call.
* **`+ Add another child` then `Continue` in one frame**: the BUG-2 guard drops
  the second request entirely, so a sub-frame Continue tap does not navigate.
  The buttons re-enable and the test proves Continue works immediately after.
  Worth a follow-up "queue the navigation" decision, not a blocker.
* Typing the *identical* nickname again while its own save is in flight is
  treated as "unchanged" and cleared (`typedMore` compares the trimmed draft to
  the saved value). Same string, no information lost.
* `flutter_test` uses a fallback font, so in-test line counts are pessimistic;
  the 320 + 1.3× overflow tests are conservative, never optimistic.

VERDICT: PASS