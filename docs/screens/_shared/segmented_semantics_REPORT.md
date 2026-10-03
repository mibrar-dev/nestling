# Shared report — segmented semantics (double announcement fix)

## Files changed

- `app/lib/core/design_system/components/nest_segmented.dart` — added
  `excludeSemantics: true` to the per-option `Semantics` wrapper (kept
  `onTap:`, so the labelled node still exposes `SemanticsAction.tap`).
- `app/test/core/design_system/semantics_actions_test.dart` — updated the
  `NestSegmented` group to the single-node contract and added one test.

## What / why

Each `NestSegmented` option wrapped its label, inner `Text`, and `InkWell`
in `Semantics(button: true, label: option.label, onTap: …)` without
`excludeSemantics: true`. The outer label and the inner `Text` both
announced the option, so screen readers read e.g. "Ideas" twice. Setting
`excludeSemantics: true` merges the subtree into the one labelled node —
exactly the `nest_chip.dart` "one node per chip" pattern. Keeping `onTap:`
on the wrapper preserves the tap action that `excludeSemantics` would
otherwise drop from descendants (RULES.md §8 / `common.md` accessibility
rule). Backward-compatible: no API, layout, or visual change.

## Tests

- Updated: `NestSegmented enabled options expose tap and select` — now
  asserts the single node via `bySemanticsLabel('Seg B')` (was the
  `buttonNode` two-node workaround).
- Updated: `NestSegmented disabled options expose no tap` — label stays
  exact (`nodeByLabel('Seg B')`) instead of the containment match.
- Added: `NestSegmented each option announces once with tap and selection`
  — 2-option control (`Active`/`Ideas`): `find.bySemanticsLabel('Ideas')`
  finds exactly one node; it is a button with `SemanticsAction.tap` and
  `isSelected == false`; `performAction(tap)` flips selection
  (`Ideas` selected, `Active` unselected).

## Follow-up for screens

None required. Screens using `NestSegmented` (e.g. P10 quest library) get
the single-announcement behaviour automatically; P10's
`quest_library_a11y_test.dart` segmented-control contract
(one node per option, tap action, selection flags) now holds against the
shared widget.

## Verification

- `cd app && dart format .` — clean (0 changed)
- `flutter analyze` — "No issues found!"
- `flutter test` — all pass (1777)

VERDICT: PASS
