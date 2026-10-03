# Shared request — P09 `NestSegmented` height

Need: `NestSegmented` renders a **44px** container with a **36px** thumb, but
`docs/design/SPACING_SPEC.md` §"`.segmented → NestSegmented`" (and
DESIGN_SPEC §9 conflict 1) both rule that the rendered value wins:
"height **52** total (44 + 4 + 4); buttons Expanded, **44** high". The P09
design PNG agrees — measured on `design/screens/light/P09-quest-editor.png`
the segmented track is y 480→532 (52) and the selected thumb y 484→528 (44).
The component took the CSS `height: 40px` declaration instead of the
`min-height: 44px` clamp that a browser actually applies. P09 builds on
`NestSegmented` as required (no re-implementation), so until the component is
fixed the Repeats section and everything below it sits 8px higher than the
design. Fixing it also corrects P10 (`/quests`) and P12 (`/money`), which
share the component.

Files: `app/lib/core/design_system/components/nest_segmented.dart`
(container `height: NestDevice.tapParent` → 52, segment
`height: NestDevice.tapParent - NestSpacing.s2` → 44).

Blocks: no — P09 lands and works with the current 44px component; the
8px drift is cosmetic and is called out in `2b_build_ui.md`.