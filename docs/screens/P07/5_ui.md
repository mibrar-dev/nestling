# P07 Paywall — UI check (Stage 5, iteration 1)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_1.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya`
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_1.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya`
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_1.png docs/screens/P07/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_1.png docs/screens/P07/ui/cmp_dark_1.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `docs/DESIGN_SPEC.md` §5 P07, `docs/design/SPACING_SPEC.md` §§1–2/8/10–11, `docs/screens/P07/1_plan.md`, `docs/screens/P07/ORCHESTRATOR_NOTES.md` (item 1 mandatory).
- Status bar differences ignored per orchestrator STATUS BAR rule (OS draws real bar; `NestStatusBar` reserves height only).

## Mean diff

- Light: **9.92%** (bands: 0 0–105: 3.07% · 1 105–211: 9.54% · 2 211–316: 13.29% · 3 316–422: 6.92% · 4 422–527: 5.05% · 5 527–633: 8.31% · 6 633–738: 28.75% · 7 738–844: 4.56%)
- Dark: **9.44%** (bands: 0 0–105: 3.28% · 1 105–211: 10.66% · 2 211–316: 9.77% · 3 316–422: 7.26% · 4 422–527: 5.22% · 5 527–633: 8.89% · 6 633–738: 25.35% · 7 738–844: 5.12%)
- The low mean is misleading: both sides share large empty paper areas, so background pixels match while **every designed element is missing**. The app under test is still the foundation placeholder (`paywall_view.dart:9-42`: `AppBar('P07 Paywall')` + `ListTile`), consistent with `2_build.md` / `4_review.md` (no implementation in this loop). Band 6 peaks (28.75% light / 25.35% dark) where the design has the plan card + `NestBottomCta` and the app has empty paper.

## Deviations (design value → app value)

1. Nav / close — design: compact nav `minHeight 52`, padding `4,12,12`, 44×44 close button surface-2 radius 12 with 24px X, semantics `Close and go back`, 44-wide balance spacer. App: Material `AppBar` titled `P07 Paywall`, no close control. Fix: build `_PaywallNav` per `1_plan.md` §a.
2. Hero — design: `350×148`, `margin-top 4`; lilac-tint circle 170×170 at (90,−5); nest 150×150 at (100,41); `PipAvatar(style: mochi, skin: sunny, stage: 4)` 120×120 at (115,20) (orchestrator PIP rule for P01–P07, never `pip_stage_*.svg`); 3 coins 30/26/24px at specified positions/rotations with sh-1. App: absent. Fix: build `_PaywallHero` with `PipAvatar` exactly as planned.
3. Title — design: `Try Nestling free for 14 days`, `NestType.h1` (Nunito 28/34 w900) centred, `margin-top 26`, maxLines 3. App: absent (only AppBar `P07 Paywall`). Fix: add title widget.
4. Benefits — design: 4 rows, `margin-top 18`, gap 10; 24×24 leaf-tint tick (`NestIcon(check, 16, leafInk)`, `margin-top −1`) + Inter 15/24 w400 ink text `softWrap/anywhere`; exact copy `Unlimited children & quests` · `Pip’s full evolution & seasonal outfits` (curly ’ U+2019) · `Pocket money ledger & payout day` · `Co-parent sharing, so James sees the same`. App: absent. Fix: build `_BenefitList`.
5. Plan card — design: `margin-top 24`, `NestCard` (radius 24, sh-1, padding 16) + local 2px leaf border; radio 22 selected (`margin-top 10`); title Nunito 800 18/24 `Annual — £29.99/year` (em dash U+2014); sub Inter 15/20 `Just £2.50 a month, billed yearly`; tag Inter 13/18 w600 leaf-ink `One price, the whole family` with `margin-top 4`. App: unstyled `ListTile` (title `Annual — £29.99/year`, subtitle concatenated detail), no card/border/radio/tag/shadow. Fix: build `_PlanCard` per plan.
6. Timeline + family note (below fold) — design/HTML: `What happens next` card (`margin-top 48`, padding 16, 3 `tl-item`s with 24px dots + 2px connectors) + centred note `One subscription covers the whole family.` (`margin-top 20`). App: absent (no scroll body at all). Fix: build `_TimelineCard` + `_FamilyNote`; verify with a scrolled shot.
7. Bottom CTA — design: `NestBottomCta` (surface + top hairline, padding `16/20`, gap 8); `NestButton.primary` 52h `Start free trial` full-width; caption `£29.99/year after the 14-day trial. Cancel anytime in Settings.` (note `the` — HTML wins over DESIGN_SPEC paraphrase); legal row `Restore purchases · Terms · Privacy` (Inter 13 w600 sky, underline offset 2, `·` U+00B7, each min 44×44). App: absent. Fix: wire `NestBottomCta` + CTA + caption + `_LegalRow` per plan.
8. Bottom edge (OWNER RULE) — design/rule: surface colour from the bottom bar runs to the physical edge; no paper/meadow strip under bar or home indicator, light or dark. App: no bottom bar exists, so the rule cannot hold. Fix: add `NestBottomCta` wrapping `SafeArea(top: false)`; never add page-colour padding below it.
9. Alignment (OWNER RULE) — design: consistent 20px side gutters, cards/bars on same edges. App: Material defaults (AppBar + ListTile insets), not 20px gutters. Fix: `ListView(padding: fromLTRB(20,0,20,32))` + shared 20px edges.
10. Colours / radii / shadows / icons / dark mode — design: paper/surface/surface-2, leaf border + leaf-tint ticks/dots, leaf CTA, sky links, r24 cards + pill CTA, sh-1, Lucide-style 2px-stroke icons; dark tokens per SPACING_SPEC §0. App: placeholder Material greys, no cards, no ticks, no CTA, no links. Fix: tokens only, verify both themes.
11. Copy defect (already filed as P07-BUG-3) — design caption `£29.99/year after the 14-day trial.` App `ListTile` detail `£29.99/year after 14-day trial.` (drops `the`). Fix: insert `the` at repository source.
12. Orchestrator mandatory item 1 — trial/Restore must call `AppSession.startTrialNow()` (+ `completeOnboarding()`) / `setSubscription('active')` (+ `completeOnboarding()`) then go `/today`. App: no CTA exists, no events/state (`PaywallTrialStarted`/`PaywallRestoreRequested` absent), so the handoff is unmet. Fix: implement plan §b–c (via `GetIt.instance<AppSession>()`, not `context.read`).
13. Status bar — app shows live `21:08/21:09` vs design mock `9:41`. Not a finding per orchestrator rule; ignored.

No spacing ±2px check is possible — there are no corresponding elements to measure. No overflow/clipping to assess for the same reason. DATA OVER MOCKS / PERIODS / CHILD ORDER: not exercised (P07 shows no DB numbers; copy fixity `James` holds trivially since no child names render).

## Verdict basis

Stage 5 passes only with no visible deviation a designer would reject. The screen is the untouched placeholder: hero, title, benefits, plan card, timeline, family note, CTA, caption, and legal row are all missing in light and dark. The mean diffs (9.92% / 9.44%) confirm wholesale mismatch, peaking at the CTA band.

VERDICT: FAIL
