# K03 Kid home — Stage 3 (TEST), iteration 9

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_bloc_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`).
Per RULES §1 this stage only touched `app/test/features/kid_home/**` and
`docs/screens/K03/**` — **no screen code was patched, and no bug was found, so
there is nothing to record as a defect**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `BC440E48-…`).

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched; no
  new suppressions).
- `flutter test` (whole app) → **exit 0, `+1557`** — 1557 pass, **0 skip,
  0 fail**.
- `flutter test test/features/kid_home/` → **exit 0, `+175`** — 175 pass,
  **0 skip, 0 fail**.

| File | Iteration 8 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 77 | **84** (+7, all pass) |
| `kid_home_bloc_test.dart` | 31 | **31** |
| `k03_bugs_test.dart` | 53 | **59** (+6 from the bugs stage's accessibility probes) |
| `kid_home_geometry_test.dart` | 1 | **1**, passing |

## What iteration 9 delivered (the surface under test)

1. **The new ACCESSIBILITY ACTIONS rule became testable**: main merged
   `shared/semantics_tap` (191be8f) — "every interactive design-system component
   exposes `SemanticsAction.tap`". Until now the suite only asserted labels.
2. **Quest-card rhythm measured on painted rects** (`kid_home_view.dart:110`,
   `_kQuestCardShadowRoom = 6`): the shared card reserves 6 px under itself for
   `kidShadow`, so the column spacing is `s3 − 6` and the *painted* cards keep
   the design's `.k3-quests { gap: 12px }`. Pending SHARED_REQUEST #16(b), which
   would remove the subtraction entirely. The layout-invariants test now
   measures the painted rects (new `_questCardPainted` helper), because the
   widget rects carry the reserve and would read 6 instead of 12.
3. Meadow-band documentation alignment (`0.62 × NestDevice.height`), no
   behaviour change.

## Tests added (this stage): the accessibility-actions matrix

New group `K03 accessibility actions (VoiceOver/TalkBack)` — **7 tests**. The
rule has two halves and each is asserted: `getSemantics(f).getSemanticsData()
.hasAction(SemanticsAction.tap)` for every control, and `performAction(tap)`
must change the **real** state or database, not just the visuals.

| Test | Control | Real effect asserted after the action |
| --- | --- | --- |
| `the lock exposes a tap action that opens the parental gate` | `Grown-ups` | `pushedPath` == `/parental-gate` |
| `every dock button exposes a tap action and routes` | `Pip`, `Shop`, `My jar` | `/pip`, `/reward-shop`, `/my-jar` (and the pushed screen) |
| `a quest card exposes a tap action that opens the detail` | merged card node | the K04 detail route with `childId: maya` in `extra` |
| `a to-do check exposes a tap action that completes the quest` | `Mark done` | the repository records `['maya','q-reading']` **and** the K05 celebration opens |
| `the failure retry exposes a tap action that reloads` | `Try again` | the screen returns to `loaded` with all 6 cards |
| `the picker CTA exposes a tap action that opens K01` | `Choose` | `K01 Who is playing` |
| `non-controls advertise no tap action (no phantom buttons)` | greeting, hearts row, progress bar, pending check | `hasAction(tap)` is **false**; a pending check exposes no node at all, so a screen reader never offers a button that does nothing |

The actual semantics tree, dumped while writing these (390 px, light), is the
evidence that the split is right:

```
label="Hi Maya, 4 done today"                              tap=false
label="120 coins"                                           tap=false
label="Grown-ups"                          button=true      tap=true
label="Let's do some quests!…"                             (image node)
label="Pip is happy today, 4 of 5 hearts"                  tap=false
label="Today's quests…"                                     (balanced heading)
label="4 of 6 of today's quests done"                      tap=false
label="Empty the dishwasher, Waiting for Mum's thumbs-up"  button=true tap=true
label="Hoover the stairs, Done"              button=true   tap=true
label="Pip" / "Shop" / "My jar"             button=true   tap=true
```

So every control is a real button with a tap action, and every announcement node
is inert — exactly what the rule asks for.

## Results

All 7 new tests pass, and nothing else moved: the layout matrix (light + dark ×
320/390/430 × text scale 1.0/1.3), the layout invariants on painted card rects,
the PERIODS ruling, the bottom-edge and alignment owner rules, navigation,
labels, tap targets (≥ 44 parent / ≥ 56 kid), the PipAvatar mandate, the
completion/celebration state machine, the shapes group (chip pill, card tile +
tint, 56 px check, `.speech` bubble, scene box per width), and the real-font
geometry test.

## Bugs found

**None.** No test failed, no semantics node was missing a required action, and
nothing in the screen misbehaved under the new rule. The one thing worth
recording is a harness subtlety rather than a defect (below).

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset emulated)
  pass — the dock surface runs to the physical edge and the meadow ends at the
  dock's top border in both themes.
- **ALIGNMENT:** gutters and shared card/bar/dock edges pass; the pet slot stays
  on the axis at 320/390/430; dock labels cannot wrap, so the three buttons keep
  equal heights at every width and text scale; quest cards now keep the design's
  12 px gap **between painted rects**.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| **ACCESSIBILITY ACTIONS** | **New group, 7 tests**: every control advertises `SemanticsAction.tap` and performing it changes the real state/DB; non-controls advertise none |
| PIP | Mandated `PipAvatar` for the active child in every state; no v1 `pip_stage_*.svg` |
| BOTTOM EDGE / ALIGNMENT | Proven by tests (above) |
| PERIODS + DATA OVER MOCKS | Counts from the DB; daily/weekly/once + new-period proofs green |
| COPY | Re-verified character-by-character against the HTML source (0 curly / 4 straight apostrophes; the app matches) |
| FONTS / LETTER SPACING | No `google_fonts`; every rendered string asserts `letterSpacing == 0` |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip` |
| UI CHECK MEASURES SHAPES | Card rhythm now measured on painted rects; chip pill, tile + tint, check, bubble and scene box measured as background/border rects |
| BALANCED HEADINGS | The only `.kid-title` heading renders through `NestBalancedText`; nothing else does |
| CHILD ORDER | No child list here; pinned at the repository level (K03-BUG-12) |
| TRIAL | No test writes `subscription_status` |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- **An offstage card has no semantics node at all.** The two to-do cards are
  built below the fold, so `tester.getSemantics(checkFinder).owner` is `null`
  and the action cannot be performed. Scroll the control into view first
  (`ensureVisible` + a pump) — that is why the check test does it, and why an
  earlier draft failed with a null-check error rather than a clean assertion.
- **`SemanticsAction` needs `package:flutter/semantics.dart`** (it is not
  re-exported by `material.dart`).
- Two ways to activate a semantics action, both used here:
  `tester.semantics.tap(find.semantics.byLabel(label))` (public, throws unless
  the node reports the action — but only finds nodes that exist in the
  semantics tree) and, for a widget finder (including merged card nodes),
  `tester.getSemantics(f).owner!.performAction(id, SemanticsAction.tap)`.
  `tester.getSemantics(find.bySemanticsLabel(...))` is *not* interchangeable:
  it can hand back a detached node.
- **Pushed routes:** assert `pushedPath`, not `currentPath` — the latter reports
  the declarative location a `push` came from (`/kid-home` while the gate is on
  screen).
- The design source uses a **straight** apostrophe in `Who's playing?`; a test
  written with `\u2019` silently finds nothing.
- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`;
  bottom insets are emulated via `tester.view.padding` / `viewPadding` at 3×
  physical px; never `pumpAndSettle` while a loading spinner is on screen.

VERDICT: PASS
