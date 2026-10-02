# P03 Create account — UI check (Stage 5, iteration 1)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No `ORCHESTRATOR_NOTES.md` exists — only the standing orchestrator overrides apply (PIP vacuous here:
no Pip on this screen; status-bar time ignored; bottom-edge OWNER rule enforced).
Design sources: `design/screens/light/P03-create-account.png`,
`design/screens/dark/P03-create-account.png` (1170×2532 @3x → logical 390×844),
`design/html-source/screens/P03-create-account.html`, DESIGN_SPEC §5 P03, SPACING_SPEC §§1–2,9–11.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_1.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_1.png docs/screens/P03/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P03-create-account.png docs/screens/P03/ui/app_dark_1.png docs/screens/P03/ui/cmp_dark_1.png`
- Read `cmp_light_1.png`, `cmp_dark_1.png`, both app shots, and both design PNGs with the file reader.

## Mean diff

- Light: **13.15%** — bands (0) 0–105: 2.63% · (1) 105–211: 15.65% · (2) 211–316: 31.53% · (3) 316–422: 5.24% · (4) 422–527: 3.50% · (5) 527–633: 5.35% · (6) 633–738: 32.67% · (7) 738–844: 8.75%.
- Dark: **12.21%** — bands (0) 0–105: 2.59% · (1) 105–211: 16.22% · (2) 211–316: 29.70% · (3) 316–422: 5.96% · (4) 422–527: 3.80% · (5) 527–633: 5.60% · (6) 633–738: 26.33% · (7) 738–844: 7.63%.
- Worst bands are 2 (Apple/Google zone) and 6 (CTA/legal zone) in both themes; bands 3–5 (or-row, fields, note) sit at 3–6% — the mid-form matches well.

## Checked and matching (not deviations)

- Presence/order/copy: back chevron, `Create your family account`, `You're the grown-up in charge. Children never need an email.`, `Continue with Apple`, `Continue with Google`, `or` with hairline dividers, `Email`, `Password`, eye toggle, `At least 8 characters`, shield + `No child emails or photos — ever.`, `Create account`, `By continuing you agree to our Terms and Privacy Notice` (both links, sky + underline). All present, in order, correct UK copy.
- Icon choice: Apple single-path glyph and 4-colour `G` match the HTML artwork; eye and shield-check icons correct; lilac shield, sky links in both themes.
- Dark-mode flips correct: Apple black→white bg, Google white→near-black bg with grey border, fields/labels/links resolve to dark tokens. The muted-green CTA in the app is the *disabled* state (see 5), not a theme bug.
- Alignment (OWNER): 20 px side gutters hold; email-field edges 22–367 and CTA edges 24–366 in design and app.
- Bottom edge (OWNER): below the `NestBottomCta` panel to y=844 the app is uniform surface (light `#FFFFFF`, dark `#1F1C2E`) — no paper/meadow strip, no coloured ring around the home area, in either theme. Passes the OWNER rule.
- No overflow, clipping, or unwanted ellipsis at 390 width; button radii (pill), field radius (16), and shadows match.

## Deviations (element, design value, app value, fix)

1. Whole scroll content sits ~14–16 dp too high (shared nav-bar defect). Headline ink starts design y≈120 vs app y≈104; Apple-button top design y≈254 vs app y≈238; email-field top border design y≈426 vs app y≈412 (all at 390×844 logical, ±2). Bands 1–2 glow red from this alone. Fix: orchestrator-owned — compact `NestNavBar` must render the spec 60 dp block (4/12 vertical padding around the 44 dp slots) per `SHARED_REQUEST.md` item 3. P03 must not fork a private nav bar.
2. Headline wraps to different lines. Design: line 1 `Create your` / line 2 `family account`. App: line 1 `Create your family` / line 2 `account` (both themes; clearly visible in the diff heat-map). Same 20 px gutters, so the text block metrics differ (H1 size/weight/letter-spacing or available width a few px off). Fix: verify the H1 token application against SPACING_SPEC type scale (28/34 w900) and the scroll's horizontal padding; keep the design's break.
3. Bottom-CTA panel top edge 47 dp too high. Gutter-luminance scan: design paper→surface transition at y≈677 (surface 677–844 = 167 dp panel); app at y≈630 (630–844 = ~214 dp panel) — identical in light and dark. The privacy note's clearance above the bar is 39 dp in the design vs ~8 dp in the app, so the lower form is visibly cramped. Fix: deviation 1 accounts for ~16 dp; the remaining ~31 dp is deviation 4. Fix 4 first, then re-measure; residual offset needs the shared nav fix (1).
4. Legal caption line gap is ~2× the design. Design: `Terms` underline rows y≈762–768, `Privacy Notice` rows y≈780–788 — line gap ≈20 dp. App: the two links sit on rows ~44 dp apart (each `Wrap` child carries a full 44 dp-high link box, so the caption is 54–80 dp tall instead of ~38 dp). This is the same defect as review finding 2 and the dominant cause of band 6 (32.67% / 26.33%). Fix (P03 scope): render the caption as one fixed two-line-high `Text.rich` block with a `TapGestureRecognizer` per link (HTML `.link` behaviour: 44 dp hit area via overlap, not layout height) — no `Wrap` child may be 44 dp tall.
5. Recorded non-finding (do not fix): app fields are empty and the CTA is disabled-faded, while the design shows `sarah@example.co.uk` + dotted password and a solid-green enabled CTA. Empty/disabled is the correct initial state under `SEED=fresh` (plan §(b): `email ''`, submit enabled only when both fields validate); the design shows mock content. Likewise the OS status-bar time (design `9:41` vs simulator `12:06`/`12:07`) is ignored per the orchestrator status-bar rule, and the app correctly shows no mock home-indicator pill (surface runs to the edge per the OWNER rule; the design's mock pill + paper strip are superseded).

A designer would reject the screen as captured: the headline rewrap (2), the CTA riding 47 dp high with a cramped note (3), and the double-spaced legal line (4) are all visible at a glance in both themes, with bands 2 and 6 at 26–33% diff.

VERDICT: FAIL
