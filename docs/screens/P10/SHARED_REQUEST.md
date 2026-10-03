# Shared request — P10 geometry + semantics of three shared components

Need: P10's remaining design drift and its accessibility defects live in
`app/lib/core/design_system/`, which RULES §1 forbids a screen agent from
editing. Measured against
`design/html-source/screens/P10-quest-library.html` and
`design/screens/light/P10-quest-library.png` (1170×2532 @3x) at 390×844.

**Status after stage 2 (integrate, iteration 2), main @ `c1be080` + batch4:**

| § | Item | Status |
|---|---|---|
| 1 | `NestSegmented` announces every option label twice (no `excludeSemantics`) | **OPEN — now the ONLY thing keeping P10's suite red** (3 tests, `+1921 −3`) |
| 2 | `NestSegmented` 44/36 high vs `.segmented` 52/44 | **LANDED** on `shared/shared_batch4` — `BUG-P10-6` passes |
| 3 | `NestTextField` cannot express the `.search` prefix slot | **LANDED** as `NestTextField.search` — `BUG-P10-5` passes |
| 4 | `NestTabBar` content 34 px below the design | **LANDED** (surface to the edge + content at the design top) — `BUG-P10-7` passes |
| 5 | `Semantics(excludeSemantics: true)` without `onTap` exposes no tap action | **P10 half LANDED** in `features/quests/**`; the shared `NestChip` half is **OPEN** (no P10 test is red on it) |
| 6 | NEW (small): promote the per-frame push guard to `core/` | optional |

Everything else is green: all 12 red tests the two halves handed over are
fixed in-scope, and the 9 P10 lib/test files + the shared `today` navigation
tests pass. §1 alone blocks the suite; a one-line change clears it.

---

## 1. `NestSegmented` still announces every option label twice — MAJOR · OPEN

`nest_segmented.dart:53-58` wraps each option in

```dart
Semantics(
  button: true,
  selected: isSelected,
  enabled: changed != null,
  label: option.label,
  onTap: …,                       // added by shared batch4
  child: Material(… InkWell(onTap: …) …),
)
```

The batch4 fix added the missing `onTap:` (so the node is actionable), but there
is still **no `excludeSemantics: true`**, so the option's own
`Text(option.label)` (`:80`) and the InkWell's inner `Semantics` both keep
their own nodes. `find.bySemanticsLabel('Ideas')` therefore matches **2**
elements on `/quests`, and a screen reader walks the label twice:

```
SemanticsNode#23  actions: tap  flags: isSelected, isButton  label: "Ideas"
  └─SemanticsNode#24  actions: focus, tap  flags: isFocusable  label: "Ideas"
```

`NestChip` avoids exactly this (`nest_chip.dart:119-121`, "One node per chip:
the label above owns the announcement").

**Fix:** add `excludeSemantics: true` to the per-option `Semantics` (the
`onTap` the batch added stays, so the node keeps its action).

**Proofs (currently failing — the last 3 red tests in P10):**
`quest_library_a11y_test.dart` →
`P10 segmented control each option is one labelled, tappable button`,
`P10 icon buttons every interactive node announces what it does`,
`P10 dark mode the same semantics contract holds in dark` (all three fail only
on the `'Ideas'` / `'Active (12)'` duplicate: `Found 2 widgets with a semantics
label named "Ideas"`).

Screen-side workarounds deliberately NOT taken: `ExcludeSemantics` around
`NestSegmented` would delete the control's tap actions from the semantics tree
(worse than the duplicate), re-implementing the control locally is forbidden,
and softening the three proofs to `findsWidgets` would mask the defect. The
`ExcludeSemantics` + `onTap` proof pattern to copy is `nest_chip.dart:119-121`.

---

## 5. `NestChip` exposes no `tap` action — MAJOR · shared half OPEN

`nest_chip.dart:119-137` builds

```dart
Semantics(button: true, label: …, excludeSemantics: true, child: Material(…InkWell(onTap: …)))
```

`excludeSemantics: true` drops the subtree, and the `InkWell` is the **only**
source of `SemanticsAction.tap` (it builds its own `Semantics(onTap:)` inside).
The node announces `isButton` with the right label and **no action**, so
VoiceOver's double-tap does nothing:

```
NestChip "All"   → label=All   actions=[]  isButton=true
plain InkWell    → label=Plain actions=[tap, focus]
```

**Fix (design system):** keep the label node and add its own
`onTap:` (the simplest, and what P10 did locally), or wrap the inner text in
`ExcludeSemantics` and drop the outer flag.

**P10 half (done in `features/quests/**`, for reference):**
`quest_filter_chip.dart`, `quest_idea_row.dart` now pass
`onTap:` **and** `container: true` on the `Semantics` node. The
`container: true` is load-bearing — without it the `+ Add` annotations bubble
into the row and the control loses its own addressable node, exactly as the
iteration-1 measurement showed:

```
SemanticsNode#39  actions: tap  flags: isButton, isImage
  label: "Make your bed\n5 coins · Ages 4+ · Bedroom\nAdd Make your bed"
```

After the fix:

```
SemanticsNode#…  Rect 257…358 × 254…298  actions: tap  flags: isButton
  label: "Add Make your bed"
```

**Proofs (now passing):** `every visible chip is a tappable button with its own
label`, `it is one tappable button named after the idea`,
`every visible row names its own Add button`, plus P10's own
`every P10 control is actionable from the semantics tree` in
`quest_library_view_test.dart`.

---

## 6. (optional) Promote the per-frame push guard to `core/`

`QuestPushOnce`
(`features/quests/presentation/widgets/quest_push_once.dart`) is a copy of P08's
private `_PushOnce`
(`features/today/presentation/widgets/today_loaded_body.dart:238-269`), because
a cross-feature import is not allowed by the feature contract. Two screens now
carry the same 20-line widget; a `core/` version (e.g.
`design_system/motion/push_once.dart`) would let both import it. Not blocking —
P10 works around it.

---

## 7. (informational) P08 paints `plate` lilac, P10 paints it sky

`features/today/.../today_loaded_body.dart`'s `todayTintFor` gives the seed icon
key `plate` a **lilac** tile, while P10's `questTileTintFor` gives it **sky** —
the same title ("Lay the table") therefore changes colour between the today
board and the quest library. P10 follows its own design sheet (`kQuestIdeaMeta`,
`idea-table` = sky) and its test
(`the same quest title keeps one tile tint across both tabs`), so the
agreement has to come from P08. Raised for the orchestrator; no P10 edit.