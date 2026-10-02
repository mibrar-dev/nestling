# P03 Create account — UI check (Stage 5, iteration 5)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844, new UDID this iteration).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` including the 17:22 UPDATE (subtitle wrap is SHARED,
do-not-tweak-locally; remaining diff mostly expected empty-vs-filled) + standing rules (PIP vacuous; status bar
ignored; bottom-edge OWNER rule; CHILD ORDER n/a; COPY exact characters vs HTML).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source, DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_5.png E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_5.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_5.png docs/screens/P03/ui/cmp_light_5.png` (and dark → `cmp_dark_5.png`).
- Read `cmp_light_5.png` with the file reader; verified edges by 1–2 px luminance scans.
- Filled-state capture: still host-blocked (no SimulatorKit/HID path, no Simulator.app GUI — proven iterations 2–4
  on this unchanged host; not re-proven by burning another launch this iteration). Fallback stands: empty-state
  captures cover all state-independent geometry; filled state pinned by the "design filled state" widget test.

## Mean diff

- Light: **4.66%** (unchanged) — bands (0) 0–105: 1.55% · (1) 105–211: 5.59% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 14.39% · (7) 738–844: 6.22%.
- Dark: **4.27%** — bands (0) 0–105: 1.58% · (1) 105–211: 5.86% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 11.20% · (7) 738–844: 5.74%.
- Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the design's home-pill vs none in
  `simctl` captures, and the shared subtitle wrap (see non-findings).

## Checked and matching (all P03-local elements)

- Header: headline ink y=120, Apple black y=255 — identical to design. Title break `Create your` / `family account`
  (edges x≈174/218 vs 172/217). Subtitle copy is U+2019 `You’re` (COPY rule satisfied).
- Legal footer: `Terms` rows 760–770, `Privacy Notice` rows 780–790 — same two-line structure as design
  (761–768 / 779–791); ≈38 dp centred block, normal gap, nbsp keeps the link together.
- CTA hairline: design y=677, app y=678 — within ±2 px; note clearance identical at 39 px.
- Helper on the 20 px gutter with the design-identical text-top gap; note row (shield x=24, text x=52–56,
  one baseline); or-row, buttons, fields, eye icon; dark-mode flips (Apple white, Google near-black, sky links,
  lilac shield).
- Bottom edge (OWNER): surface uniform to y=844 both themes — no strip. Alignment (OWNER): 20 px gutters,
  no overflow/clipping/stray ellipsis.

## Deviations

None in P03 scope. Every element this screen owns matches the design within the ±2 px tolerance, with correct
copy (character-exact, verified against the HTML), colours (tokens), radii, shadows, and icons in both themes.

## Non-findings (explained, do not fix — orchestrator-owned or expected)

- Subtitle wrap (`Children / never…`, line-1 right x≈329 vs design x≈365): reclassified SHARED by the 17:22
  UPDATE (body text ~3% wide on every screen; shared `shared/body_text_width` fix in flight, merges via the
  loop — merge order is a process item, not a finding). Local tweak explicitly forbidden; P03 must only
  re-measure after the merge. Not a P03 deviation.
- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh` (keep per orchestrator). Expected band-6 contributor.
- Status-bar clock and the design's home-indicator pill (never drawn by `simctl`): ignored/artefact; the OWNER
  bottom edge itself passes.
- Process items (uncommitted iteration-5 work, branch/merge order): handled by the loop and orchestrator.

No P03-local deviation remains that a designer could attribute to this screen — the one visible delta
(subtitle break) is a tracked shared defect with its fix owned by the orchestrator.

VERDICT: PASS
