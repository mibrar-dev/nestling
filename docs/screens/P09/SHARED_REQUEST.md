# Shared requests — P09

## 1. `NestSegmented` height — RESOLVED on main (`8ad0cdc`, "shared(batch4)")

Need: `NestSegmented` used to render a **44 px** container with a **36 px**
thumb, but `docs/design/SPACING_SPEC.md` §"`.segmented → NestSegmented`" (and
DESIGN_SPEC §9 conflict 1) both rule that the rendered value wins:
"height **52** total (44 + 4 + 4); buttons Expanded, **44** high". The P09
design PNG agrees — measured on `design/screens/light/P09-quest-editor.png`
the segmented track is y 480→532 (52) and the selected thumb y 484→528 (44).

Status: **landed**. The component now builds
`height: NestDevice.tapParent + NestSpacing.s2` (52) with
`height: NestDevice.tapParent` (44) segments, so P09's Repeats block needs no
workaround. `quest_editor_view_geometry_test.dart` pins the track at
`(20, 480, 350, 52)` and the three tab centres at 79.7 / 195 / 310.3, so a
regression fails the screen's own suite. Nothing further is requested.

## 2. `NestToggle` paints its track centred in its hit box — compensated in P09, advisory

Need: `.toggle` in `design/html-source/components.css` is a **51x31** track with
an absolutely positioned `::before { left/right: -4px; top/bottom: -7px }`
hit area. The design puts the **track** flush with the row's content edge and
lets only the hit area overhang into the card padding — measured on the P09
PNG the track is x 303→354, y 620.5→651.5 while the hit area runs to 358.

`NestToggle` is the mirror image: a 59x44 box (the same 51+8 / 31+13 hit area)
that *centres* the 51x31 track inside it, so in a `.card` the painted switch
lands 4 px short of the content edge and 2 px low — an alignment failure under
the owner's "nothing a few px off" rule for any screen that right-aligns a
toggle (P09 `Needs my approval`, and P08/P16 wherever they use it).

P09 does not re-implement the component: it wraps it in
`Transform.translate(QuestEditorMetrics.toggleTrackOffset /* (4, -2) */)` so
the visible track lands on the design rect, and the 44 px tap target only
moves into the card's own 16 px padding (where the CSS `::before` sits
anyway). A cleaner fix on the component would be to make the 51x31 track the
child's own box and let the 59x44 hit area be an `OverflowBox`/padding that
hangs outside it — then every call site aligns the track by ordinary layout.

Files: `app/lib/core/design_system/components/nest_toggle.dart`
(needs a shared change because `core/` is off-limits to screen agents).

Blocks: **no** — P09 lands and is pixel-correct with the in-view offset.

## 3. NOTIFY (done inside P09, one precedent-based exception) — P08 tests located the pushed editor by its placeholder title

Need: `test/features/today/today_view_test.dart` (11 uses) and
`test/features/today/p08_bugs_test.dart` (4 uses) found the pushed P09 route
with `find.text('P09 Quest editor')` — the **placeholder** `AppBar` title of
the foundation stub. P09 replaced the stub with the real sheet (no AppBar, per
the design), so all 8 of those P08 proofs went red and `flutter test` could
not pass. The repo already ruled on this exact class of fix:

- `docs/screens/_shared/router_push_test_fix_REPORT.md` §4 — "Never a
  placeholder view title"; assert a route (or a `ValueKey`), and §5 names
  these two files as the outstanding instance of it.
- `docs/screens/_shared/shared_batch4.md` §4 — the batch agent was told
  explicitly: "You MAY edit `app/test/features/today/**` … to delete the
  hidden anchor".

Status: **done** in this iteration, test-only, no P08 assertion weakened.
The anchor becomes the durable contract — `pushedPath(tester)` /
`_pushedUri(tester)` (both read `GoRouter.state.uri` from the top-most
rendered route) for "the editor is on screen", and
`find.byType(QuestEditorView, skipOffstage: false)` for the two proofs whose
whole point is "exactly one editor page, not two stacked". Every other
assertion in those tests (query params, `pop` returning to `/today`, the
guard latching) is untouched.

Files (outside RULES §1, deliberate): `app/test/features/today/today_view_test.dart`,
`app/test/features/today/p08_bugs_test.dart`.
Blocks: no — but **the orchestrator should know**: if P08's loop is running,
these two files are the only place its branch and this one touch the same
lines, and a merge conflict there is a textual conflict, not a design one.