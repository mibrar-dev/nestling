ROLE: Rive author (continuing your earlier session — you already built app/assets/animations/rive/pip.riv from tools/rive/pip/scene.rml with the Rive CLI 1.2.0).
QA RESULT (orchestrator reviewed design/animations/rive/*.png): the rig, state machine and data-binding work — great — but the CHARACTER IS OFF-MODEL versus our brand art. Kids will see Pip on every screen, so art fidelity is the priority now.
Reference art (exact shapes/colours to match): app/assets/illustrations/pip_stage_1.svg … pip_stage_4.svg, nest.svg, jar_coins.svg (read the SVG path data — reuse the same geometry in RML; convert paths faithfully). Also see design/ASSETS_OVERVIEW.png and design/screens/light/K06-pip.png, K07-evolution.png, K09-jar.png.
Specific differences to fix on stage 3 (current default):
- Wings: yours are large green oval "ear muffs" stuck to the head sides. Ours: small leaf-green (#1F9D63-ish per SVG) wing TIPS emerging from the body sides at mid-height, pointed leaf shape, ink outline.
- Beak: ours is a rounded peach/orange (#FF8A5B) beak (quadratic curve shape from the SVG), not a flat triangle.
- Crest: ours has 2–3 ink tuft strokes on top of the head. Missing.
- Body: ours is a round/pear chick (per stage), with a soft belly patch and a white highlight ellipse top-left; outline ink #1E1B3A, same stroke weight ratio as the SVG (6 in 240 space).
- Eyes: white sclera + ink pupil + tiny white catchlight, positioned like the SVG (not pushed down onto the cheeks).
- Feet: orange ellipses at the base; ground shadow ellipse rgba(30,27,58,.12).
TASKS:
1. Rebuild Pip so each STAGE (1 egg, 2 hatchling w/ shell hat, 3 fledgling, 4 songbird w/ tail, scarf, crest, spread wings) matches its SVG silhouette and palette. Keep your existing state machine contract (mood idle/happy/eating/sleepy, stage 1–4, evolve trigger, tap trigger) and view model names so pip_rive.dart keeps working; update pip_rive.dart + RIVE_GUIDE.md if any name changes.
2. Add artboard "Jar" (shortlist #3): glass jar matching jar_coins.svg (lilac lid, glass outline, gold coin stack) with a view-model number `fill` 0..1 driving the coin level (clip/mask) + a trigger `drop` that animates 3 coins falling in and a small splash; 1.6 s; loop none.
3. Verify with `rive --verify`, `rive inspect` (0 unresolved bindings) and `--screenshot` for EVERY stage × mood and the jar at fill 0.2/0.62/1.0. Save PNGs to design/animations/rive/v2/ and build a side-by-side comparison sheet design/animations/rive/v2/COMPARE.png: left = SVG render of pip_stage_N.svg, right = your Rive render, for N=1..4, plus jar. LOOK at it (you can read PNGs) and iterate until they match closely.
4. Keep pip.riv small (< 30 KB). Then in app/: `flutter analyze` → No issues; `flutter test` → pass.
FINAL REPLY: sizes, compare-sheet path, any contract changes.
