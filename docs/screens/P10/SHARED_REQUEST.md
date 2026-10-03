# Shared request — P10 geometry + semantics of three shared components

Need: P10's remaining design drift and two of its accessibility defects live in
`app/lib/core/design_system/`, which RULES §1 forbids a screen agent from
editing. Three items, all measured against
`design/html-source/screens/P10-quest-library.html` and
`design/screens/light/P10-quest-library.png` (1170×2532 @3x) at 390×844.
Failing proofs: `app/test/features/quests/p10_bugs_test.dart` (BUG-P10-5/6/7)
and `app/test/features/quests/quest_library_a11y_test.dart`.

Files:

- `app/lib/core/design_system/components/nest_segmented.dart`
- `app/lib/core/design_system/components/nest_tab_bar.dart`
- `app/lib/core/design_system/components/nest_text_field.dart`
- `app/lib/core/design_system/components/nest_chip.dart`

Blocks: **yes for P10 items 2 and 3** — the geometry and the semantics cannot
be closed inside `features/quests/**`. Item 1 does not block (P10 works around
it, see the note at the end).

---

## 1. `NestSegmented` announces every option label twice — MAJOR

`nest_segmented.dart:51-55` wraps each option in

```dart
Semantics(button: true, selected: isSelected, label: option.label, child: …)
```

with no `excludeSemantics: true`, so the option's own `Text(option.label)`
(`:73`) merges into the same node and Flutter concatenates the two:
the node's `label` is `"Ideas\nIdeas"` / `"Active (12)\nActive (12)"`.
`NestChip` avoids exactly this (`nest_chip.dart:119-121`, with the comment
"One node per chip: the label above owns the announcement").

Measured with `debugDumpSemanticsTree()` on `/quests`:

```
label: "Ideas
        Ideas"
```

A VoiceOver / TalkBack user hears every segmented option twice, on every
screen that uses the component (P09, P10, P12, P16, …).

**Fix:** add `excludeSemantics: true` to the per-option `Semantics`, and
`ExcludeSemantics` (or rely on the flag) for the inner `Text`.

**Proof:** `quest_library_a11y_test.dart` →
`P10 segmented control each option is one labelled, tappable button` and
`Ideas starts selected and Active does not`.

---

## 2. `NestSegmented` is 44 high where `.segmented` is 52 — MAJOR

HTML `.segmented { padding: 4px }` around
`.segmented button { height: 40px; min-height: 44px }` ⇒ **52** total
(4 + 44 + 4), with a 44-high thumb inset 4 px on every side.

`nest_segmented.dart:97-104` is `Container(height: NestDevice.tapParent /*44*/,
padding: EdgeInsets.all(NestSpacing.s1 /*4*/))` with children
`SizedBox(height: 44 - 4 = 36)` ⇒ **44** total, 36-high thumb.

Measured on the design PNG: the track's `--surface-2` pixels run
**y 105 → 157 (52)**; the selected `--surface` thumb runs **y 109 → 153 (44)**.
The app renders 44 / 36.

This is the root cause of the whole vertical cascade in
ORCHESTRATOR_NOTES items 3 and 4 — everything below it is 8 px high:

| element | design y | app y |
|---|---|---|
| segmented top | 105 | 105 |
| segmented height | 52 | 44 |
| search field top | 173 | 165 |
| chip pill top | 227 | 217 |
| first card top | 291 | 281 |

**Fix:** `height: 44 + 2 * NestSpacing.s1` (52) and drop the `tapParent - s2`
subtraction on the children so each option stays 44 high. `SPACING_SPEC` §9.1
already resolves the `height:40 vs min-height:44` self-conflict in favour of
44; the 4 px container padding is what is missing.

**Proof:** `p10_bugs_test.dart` → `BUG-P10-6`.

---

## 3. `NestTextField` cannot express the `.search` prefix slot — MAJOR

`P10 .search { display:flex; gap:10px; padding:4px 16px; min-height:52px }`
with a **24 px** svg: the glyph box starts 16 px inside the field and the
placeholder starts at field x + 50 (absolute x ≈ 70; the design PNG measures
x ≈ 73.7, the extra ~3.7 px being Chrome's default `input` padding).

`NestTextField` forwards `prefixIcon` straight to
`InputDecoration.prefixIcon`, which Material lays out in a
`kMinInteractiveDimension` (48 px) slot. Because that slot is **tight**,
`NestIcon`'s own `SizedBox.square(24)` cannot shrink it —
`BoxConstraints.tightFor(24).enforce(tightFor(48))` clamps back to 48 — so
the glyph paints at **48×48** and the placeholder starts at field x + 64.

Measured in the app tree: `NestIcon(NestIcons.search)` rect =
`(20, 120, 68, 168)` = 48×48, `SvgPicture` `width/height` 24 but laid out 48.
Measured on the design PNG: the glyph's drawn extent is `x 40…58, y 191…209`
= 18×18, i.e. the 24 box at field x + 16.

**Fix:** expose `prefixIconConstraints` on `NestTextField` and pass it to
`InputDecoration`, so a screen can pin the slot. P10 then supplies
`BoxConstraints.tightFor(width: 24, height: 44)` plus a 10 px gap widget so
the placeholder lands on the CSS value.

**Proof:** `p10_bugs_test.dart` → `BUG-P10-5`.

---

## 4. `NestTabBar` content sits 34 px below the design — MAJOR (item 5)

Design `.tab-bar { height: 84px; padding: 8px 4px 24px }` sits at
**y 726 → 810**, with the 34 px home strip below it.
Measured on the design PNG: the bar's `--line` top border is exactly at
**y 726**; the tab icons' `--ink-3` pixels run **y 739…757** (the 24 px svg box
is 736…760) and the labels' **y 767…777** (the 14 px line box is 764…778).

`NestTabBar` (`nest_tab_bar.dart:33-44`) is a plain `Container(height:
NestDevice.tabH /*84*/, padding: top 8 / left 4 / right 4 / bottom 24)` inside
`Scaffold.bottomNavigationBar`, so it is laid out flush with the physical
bottom edge: measured on device it spans **y 760 → 844**, icons at
**771…795** (centre 783) and labels at **799…813**. That is 34–35 px low.

OWNER BOTTOM-EDGE RULE: the bar's **surface must keep running to the physical
edge** (no paper strip under the home indicator) while its **content stays at
the design's position**. Both at once means the bar must be
`tabH + homeH = 118` high with `padding.bottom = 24 + 34 = 58`:
surface 726…844, content top 734, icon box 736…760, label box 764…778.

**Fix (shared):** give `NestTabBar` a `bottomInset` / `fillsToEdge` treatment,
or make the Container `tabH + NestDevice.homeH` with the extra home strip as
bottom padding. Both are shared: every parent tab screen shows the same 34 px
drift today.

**Proof:** `p10_bugs_test.dart` → `BUG-P10-7`
(`FakeViewPadding(top: 47, bottom: 34)`, icon centre must be 748).

---

## 5. `NestChip` (and P10's copy of the pattern) exposes no `tap` action — MAJOR

**This one P10 can and must fix in its own files**, but the pattern originates
in the design system, so please fix it there too.

`nest_chip.dart:119-137` (and `P10 quest_filter_chip.dart:29-33`,
`quest_idea_row.dart:123-128` and `:145-149`) put

```dart
Semantics(button: true, label: …, excludeSemantics: true, child: Material(…InkWell(onTap: …)))
```

`excludeSemantics: true` drops the subtree — and `InkWell` is the **only**
source of `SemanticsAction.tap`, because it builds its own
`Semantics(onTap: …)` *inside*. The resulting node announces `isButton` with
the right label and **no `tap` action**: VoiceOver's double-tap and TalkBack's
double-tap do nothing.

Measured:

```
QuestFilterChip "All"                → label=All      actions=[]  isButton=true
QuestAddButton "Add Make your bed"   → label=Add …    actions=[]  isButton=true
NestChip        "All"                → label=All      actions=[]  isButton=true
plain InkWell   "Plain"              → label=Plain    actions=[tap, focus]
```

On the real `/quests` tree the `+ Add` control is worse: because its `Semantics`
has `container: false`, it merges into the row's node, so
`find.bySemanticsLabel('Add Make your bed')` finds **nothing** at all — the
button has no node of its own:

```
SemanticsNode#33  flags: isButton, isImage
  label: "Make your bed\n5 coins · Ages 4+ · Bedroom\nAdd Make your bed"
```

**Fix (design system):** drop `excludeSemantics: true` and instead wrap the
inner text in `ExcludeSemantics` (the `NestChip` comment already describes
this as the intent), or keep the flag and add an explicit
`Semantics(onTap: …)` / `onTap` handler above it.

**Fix (P10, in its own files):** move the `Semantics` *inside* the `InkWell`,
the way P08 already does for its avatar button
(`app/lib/features/today/presentation/widgets/today_loaded_body.dart:424-437`).

**Proof:** `quest_library_a11y_test.dart` →
`every visible chip is a tappable button with its own label`,
`it is one tappable button named after the idea`,
`a row is one tappable button naming the quest and its meta`,
plus the dark-mode and "every interactive node" groups.