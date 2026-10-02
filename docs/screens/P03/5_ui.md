# P03 Create account — UI check (Stage 5, iteration 2)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (6 items, mapped below) + standing orchestrator rules
(PIP vacuous — no Pip on this screen; status-bar time ignored; bottom-edge OWNER rule enforced).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x → 390×844 logical),
`design/html-source/screens/P03-create-account.html`, DESIGN_SPEC §5 P03, SPACING_SPEC §§1–2,9–11.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_2.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; the brief's relative path breaks after `shot.sh` cds into `app/`, as proven in iteration 1).
- Same with `dark` → `app_dark_2.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_2.png docs/screens/P03/ui/cmp_light_2.png` (and dark → `cmp_dark_2.png`).
- Read `cmp_light_2.png`, `cmp_dark_2.png`, `app_light_2.png`, and both design PNGs with the file reader.
- Filled-state capture (ORCHESTRATOR_NOTES item 3) was attempted and could not run on this host:
  `idb ui tap/text` fails (`SimulatorKit … does not exist` — this Xcode 27 install ships no SimulatorKit for HID),
  and there is no Simulator.app GUI to drive (`open -a Simulator` → `Unable to find application`; only simctl headless).
  No pyobjc/Quartz to synthesize clicks either. Fallback evidence: the empty-state captures below validate all
  state-independent geometry (header, title break, caption block height/gap, helper alignment, note row, CTA panel),
  and the filled state itself (email text, password dots, enabled green CTA, eye icon) is pinned by the passing
  `create_account_view_test.dart` "design filled state" widget test (see `6_bugs.md`). The filled simulator capture
  remains open work for an iteration with GUI/HID tooling.

## Mean diff

- Light: **5.08%** (was 13.15%) — bands (0) 0–105: 1.58% · (1) 105–211: 5.60% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 15.76% · (7) 738–844: 8.19%.
- Dark: **4.61%** (was 12.21%) — bands (0) 0–105: 1.55% · (1) 105–211: 5.87% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 12.33% · (7) 738–844: 7.36%.
- Bands 1–5 now sit at 1.5–5.9% (header/title/buttons/fields fixed). Residual diff concentrates in bands 6–7:
  empty-vs-filled field contents, disabled-vs-enabled CTA colour (both expected, see non-findings), the design's
  home-indicator pill vs none in `simctl` captures, and deviations 1–2 below.

## Checked and matching (ORCHESTRATOR_NOTES items verified)

- (1) Header offset GONE — do-not-patch respected. Headline ink starts y=120 and Apple-button black starts y=255 in **both** design and app (light, 1 px scans). Bands 1–2 dropped 15–31% → 2.5–5.6%. P03-BUG-3 shared fix confirmed; nothing patched locally.
- (2) Title break matches the design: line 1 ends x≈174 (`your`), line 2 ends x≈218 (`family account`) in both (design 172/217). No hard `\n` involved at this stage's level of observation. P03-BUG-7 fixed.
- (5) Legal footer is two centred lines with normal line height inside the edge-to-edge panel: link rows design `Terms` ≈761–771 / `Privacy Notice` ≈779–791 (gap ≈20) vs app first link ≈763–773 / second ≈781–791 (gap ≈19). Caption block ≈38 dp, not 80. P03-BUG-1 geometry fixed. CTA hairline design y=677 both themes.
- (4) Helper alignment fixed: `At least 8 characters` ink starts x≈21–23, field border at x=20 (was 40 vs 20); helper text-top sits 12 px below the field's bottom border in **both** design and app (586→598 vs 588→600). P03-BUG-8 fixed.
- (6) Note row is shield + text on one baseline: shield left x=24 both, text left x=52–56 both; row ink spans y 627–637 (design) vs 629–641 (app).
- Presence/order/copy/icons/radii/shadows: unchanged from iteration 1 — all present and correct in both themes (Apple black→white flip, Google white→near-black flip, lilac shield, sky underlined links, eye toggle, pill buttons, r16 fields).
- Bottom edge (OWNER): strip y 800–843 is uniform surface to the physical edge — light lum 255, dark lum 35 (`#1F1C2E`) — no paper/meadow strip in either theme. Passes.
- Alignment (OWNER): 20 px gutters hold; no overflow, clipping, or stray ellipsis at 390 width.

## Deviations (element, design value, app value, fix)

1. Legal caption breaks to different lines (minor, visible). Design line 1 ends `…our Terms and` (right edge x≈296) with `Privacy Notice` whole on line 2 (x 150–240). App line 1 ends `…our Terms and Privacy` (blue rows span x 236–352) with lone `Notice` on line 2 (x 176–214) — the `Privacy Notice` link itself wraps mid-phrase. Both blocks are centred, so the app's caption glyphs run ~56 px narrower per line than the design's at the same 350 dp measure. Fix: verify the caption resolves the 13/18 caption token with loaded Inter (no fallback/size slip), then pin the design break — keep `Privacy Notice` unbroken on line 2 — while retaining the two-line centred block, normal line height, and 44 dp link targets from the P03-BUG-1 fix. Re-check at 320 dp / scale 1.3 (must still wrap sensibly, no overflow).
2. Bottom-CTA hairline sits +5 px low (minor, exceeds ±2 tolerance). 1 px gutter scan: design paper→surface transition at y=677 (both themes); app at y=682 (both themes). Note-to-bar clearance is identical (39 px both: note ink bottom 638→677 vs 643→682), so the whole lower block (note + CTA) rides uniformly ~2–5 px low — upper form matches exactly (headline y=120, Apple y=255, email/password/labels within 0–2 px). Fix: find the accumulated ~5 px between the or-row and the note (field heights / 16 px gaps / helper 6 px gap — audit against SPACING_SPEC §§2–3,8) and re-measure; likely 1 px growths in a few stacked elements. Re-verify after deviation 1 lands, since caption metrics feed panel height.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA in the app vs `sarah@example.co.uk` + dots + solid-green CTA in the design: correct initial product behaviour under `SEED=fresh` (ORCHESTRATOR_NOTES item 3 — keep the empty state). Dominates residual band 6 alongside the dots/text pixels; not a defect.
- Status-bar time (`9:41` vs `13:28`/`13:29`) and the design's home-indicator pill (absent in every `simctl` capture — verified a capture artefact in `6_bugs.md`): ignored per the status-bar rule; the OWNER bottom-edge itself passes (see above).
- Process items (uncommitted iteration-2 build/test work in this worktree) are the loop's to commit, not findings.

A designer side-by-side would still flag the legal line reading `…Terms and Privacy / Notice` instead of `…Terms and / Privacy Notice`, and the CTA is 5 px off the ±2 px tolerance — so this iteration does not pass. Both are small, localised fixes; the 13%→5% improvement (header, title, caption block, helper, note) is confirmed and must be preserved.

VERDICT: FAIL
