# P08b · Today empty — Stage 5 UI check (iteration 1)

Route `/today-empty` · parent · seed `new_family` (per SCREENS.tsv + ORCHESTRATOR_NOTES item 8, which override the stage brief's `empty`) · child `maya` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Worktree already contains `Seed.newFamily` and `/today-empty` in the Today `StatefulShellBranch` (p08b_shell content present), so the check is valid. Tab bar renders with Today active in both shots.

Shots: `docs/screens/P08b/ui/app_light_1.png`, `app_dark_1.png` (1170×2532, absolute out-path — relative `OUT` breaks because `shot.sh` `cd`s into `app/` before `cp`).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

## Mean diff

- Light: **5.81%** (bands: 0–105: 10.31 · 105–211: 2.58 · 211–316: 5.65 · 316–422: 7.31 · 422–527: 10.54 · 527–633: 4.55 · 633–738: 3.13 · 738–844: 2.50)
- Dark: **5.51%** (bands: 0–105: 10.56 · 105–211: 2.52 · 211–316: 4.70 · 316–422: 7.20 · 422–527: 8.14 · 527–633: 4.79 · 633–738: 3.62 · 738–844: 2.61)

Band 0 is dominated by OS status-bar glyphs/time (ignored per STATUS BAR rule) plus findings 1–2 below. All geometry measured in logical px (pixels ÷ 3).

## Measured positions (design → app, logical px)

| Element | Design | App (light + dark identical) | Δ |
|---|---|---|---|
| Screen title top ("Good morning, Sarah") | 53.0 | 61.0 | **+8** |
| Empty-card top | 121.0 | 129.0 | **+8** |
| "Add a quest" button rect | y 423–475, h 52, x 40–350 | y 431–483, h 52, x 40–350 | **+8**, size exact |
| Tip card top | ~556 | ~566 | +8–10 (same shift; corner radius adds ±2 detector tolerance) |
| Tab-bar top | 727.0 | 727.0 | 0 (shell chrome exact) |
| Card gutters | x 20–370 | x 20–370 | 0, aligned |

## Findings (must fix)

1. Date-line suffix wrong — copy bug, not DB-driven content. Design: `A fresh nest`. App: `Happy week: 4 days` (both themes; day part `Mon 5 Oct` itself is legitimately DB-driven — seed anchored to today — and excluded). A brand-new family with zero quests showing "Happy week: 4 days" is nonsense a designer would reject. Root cause chain (read-only): `today_bloc.dart:65-66` gates the suffix on `summaries.isEmpty`, but `watchSummaries()` (`today_repository_impl.dart:59-83`) emits one summary per child even with zero quests, and `happyDays` comes from the seeded child column (`kid.happyDays`), which is 4 for Maya because `Seed.newFamily` reuses `_childrenDemo` (`seed.dart:110,236-270`). Fix: gate the suffix on `items.isEmpty` (no active quests — the same condition that selects the empty branch) so any quest-less nest shows the static `A fresh nest` suffix; the 2-child message variant already renders correctly.
2. Body content shifted +8 px vertically (table above: title, card, button, tip all +8; exceeds the ±2 px rule; a uniform shift of body content is explicitly a FAIL). Tab bar is exact, so this is a body-only top inset — likely the status reserve (47) plus a second 8 pt inset (SafeArea/status padding stacking, or scroll top padding applied on top of the greet's own `padding-top: 8`). Fix: remove the extra 8 pt top inset in the empty greeting/scroll path so the title lands at y 53; P08 populated path must not move.
3. "Browse ideas" underline colour wrong. Design: sky underline (pixel scan: underline row all sky-blue, zero dark pixels). App: ink/dark underline under sky text (light: 73-px dark run `(16,16,48)` at y 522 with zero blue pixels; dark theme shows a white-ish underline the same way). Text colour/weight correct in both. Fix: set `decorationColor` to the sky token on the link `TextStyle` (the CSS has no `text-decoration-color`, but the design PNG renders the UA-default sky underline — match the PNG).

## Checked and passing

- Presence/order: greeting (no `+`, no avatar) → empty card (art, h2, message, 8 px spacer, primary button, link row) → inset tip → tab bar (Today active leaf). No overflow, no clipping, no ellipsis anywhere.
- Copy byte-exact vs HTML source: `Your nest is quiet`; two-sentence message with `Maya and Leo` in creation order (orchestrator 2-child variant); tip title/body with curly quotes, em dash (`each — "Make`), en dash (`Reading – 20 minutes`); `Add a quest`; `Browse ideas`; greeting `Good morning, Sarah` (real-clock morning, parent name from DB).
- Button shape: h 52, x 40–350, pill, leaf fill, white (light) / dark (dark) label — rect exact apart from the +8 y shift.
- Tip card: inset variant, r 24, no shadow, correct padding/typography both themes.
- Bottom edge (owner rule): app runs the tab-bar surface (`#FFFFFF` light) to the physical screen edge (sampled y 815–843 all surface). The design PNG's cream strip + pill under the tab bar predates the owner rule — the app correctly follows the rule, not the PNG. PASS aspect.
- Dark mode: identical geometry to light; card/inset/button/link colours match dark tokens (leaf `#3CC98A`-family button with dark label, sky link); no colour deviation found.
- Tab bar icons/labels: Today active leaf, Quests/Money/Family ink-3 — exact, top at 727 like the design.

## Explicit non-findings (do not "fix")

- Pip art differs from the PNG (v1 egg SVG vs rendered PipAvatar mochi·sunny stage 1, 140 px): MANDATED by the PIP orchestrator rule — the app is correct, the PNG is overridden.
- Money tab glyph differs (design credit-card vs app banknote): shared `NestIcons.money` (`nestling_assets.dart:69`), identical on every parent screen (P08/P10/P12/P15/P16/P08b) — not a P08b deviation; flagged for the orchestrator as possible shared design-system follow-up, not a P08b fix (this stage may not touch `core/`).
- Status-bar time/glyphs (`03:29/03:30` vs `9:41`, icon shapes): OS-drawn, ignored per rule.
- Date day-part (`Mon 5 Oct` vs `Sat 4 Oct`): DB-driven (seed anchored to today via `Seed.anchorDay`), excluded per DATA OVER MOCKS / UI VERDICT RULE. Only the suffix (finding 1) is a bug.

No code edited (read-only inspection plus `shot.sh`/`compare.py` outputs). Temporary icon crops removed; `ui/` contains only the four required PNGs.

VERDICT: FAIL
