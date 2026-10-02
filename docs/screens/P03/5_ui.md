# P03 Create account — UI check (Stage 5, iteration 3)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` iteration-3 items (legal nbsp, subtitle curly quote + break,
filled capture) + standing rules (PIP vacuous — no Pip here; status bar ignored; bottom-edge OWNER rule;
CHILD ORDER n/a — no children listed; COPY — exact typographic characters vs HTML).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), `design/html-source/screens/P03-create-account.html`
(`You&rsquo;re`, `Privacy Notice` plain space, `— ever.` em dash), DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_3.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_3.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_3.png docs/screens/P03/ui/cmp_light_3.png` (and dark → `cmp_dark_3.png`).
- Read `cmp_light_3.png`, `cmp_dark_3.png`, and `app_light_3.png` with the file reader.
- Filled-state capture (ORCHESTRATOR_NOTES item 3, still open): re-probed this iteration —
  `idb ui tap --udid BC440E48… 195 472` still fails with `SimulatorKit … does not exist`
  (this Xcode 27 install ships no SimulatorKit/HID path and no Simulator.app GUI, verified in iteration 2).
  Host-blocked, unchanged. Fallback stands: empty-state captures validate all state-independent geometry,
  and the filled state is pinned by the passing `create_account_view_test.dart` "design filled state" test.

## Mean diff

- Light: **4.66%** (was 5.08%) — bands (0) 0–105: 1.58% · (1) 105–211: 5.60% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 14.39% · (7) 738–844: 6.22%.
- Dark: **4.27%** (was 4.61%) — bands (0) 0–105: 1.57% · (1) 105–211: 5.87% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 11.20% · (7) 738–844: 5.74%.
- Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the design's home-pill vs none in
  `simctl` captures, and deviation 2 below. Everything else is at noise level.

## Checked and matching

- Legal footer (ORCHESTRATOR_NOTES iter-3 item 1): FIXED. Blue-link rows now design `Terms` 760–768 /
  `Privacy Notice` 780–790 vs app `Terms` 760–770 / `Privacy Notice` 780–790 — `Privacy Notice` stays together
  on line 2 via the U+00A0 (verified one U+00A0 in the view). Caption block ≈38 dp, centred, normal gap.
- CTA hairline (iteration-2 deviation 2): FIXED. 1 px gutter scan: design y=677, app y=678 (both themes) —
  within the ±2 px tolerance. Note-to-bar clearance identical at 39 px both.
- Header, title break (`Create your` / `family account`, line edges x 174/218 vs 172/217), helper on the 20 px
  gutter, note row single baseline with shield at x=24 and text at x=52–56, or-row, buttons, fields, eye icon,
  dark-mode flips (Apple white, Google near-black, sky links, lilac shield): all match within tolerance.
- Bottom edge (OWNER): surface runs uniform to y=844 both themes. Alignment (OWNER): 20 px gutters, no
  overflow/clipping/stray ellipsis. Copy beyond the subtitle (title, labels, helper, note with U+2014 em dash,
  legal line with nbsp, buttons): exact vs the HTML.
- Subtitle vertical position matches (line-1 rows y 190–200 both); only its break point and one character differ.

## Deviations (element, design value, app value, fix)

1. Subtitle uses a straight apostrophe (COPY rule + ORCHESTRATOR_NOTES iter-3 item 2). Design/HTML: `You’re`
   (U+2019, `&rsquo;`). App (`create_account_view.dart:116`): `You're` (U+0027 — repo-wide U+2019 count in the
   view is 0; the repo's own `copy_audit_test.dart:27,76` expects U+2019 and documents U+0027 as a failure).
   Fix: replace the one character with U+2019. One-line, in-scope fix.
2. Subtitle wraps a word early (ORCHESTRATOR_NOTES iter-3 item 2). Design line 1 ends `…in charge. Children never`
   (right edge x≈365–367) with `need an email.` on line 2. App line 1 ends `…in charge. Children` (right edge
   x≈328–330) with `never need an email.` on line 2 — same 350 dp measure, so the app's subtitle glyphs run
   ~35 px wider per line than the HTML `.body`. Fix: match the HTML subtitle metrics exactly (16/24 Inter 400,
   weight/letter-spacing/word-spacing per `tokens.css`/`components.css` — no ad-hoc sizing), then confirm the
   design break `Children never / need an email.` at 390 width; keep sensible wrapping at 320 / scale 1.3.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA vs the design's filled values + solid-green CTA: correct launch behaviour
  under `SEED=fresh` (ORCHESTRATOR_NOTES item 3 — keep). Expected band-6 contributor, not a defect.
- Status-bar clock (`9:41` vs `15:25`/`15:29`) and the design's home-indicator pill (never drawn by `simctl`):
  ignored/artefact per standing rules; the OWNER bottom edge itself passes.
- Process items (uncommitted iteration-3 build/test/copy-audit work in this worktree) belong to the loop, not to findings.

Two deviations remain, both visible side-by-side and both covered by mandatory rules (exact COPY characters;
the specified subtitle break) — so this iteration does not pass. Each is a small localised fix.

VERDICT: FAIL
