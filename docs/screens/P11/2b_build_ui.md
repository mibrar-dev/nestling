# P11 · Approvals — Stage 2b build UI (iteration 1)

Re-read `2a_build_logic.md` before finishing — **CONTRACT CHANGES: none**
(events/states are exactly `1_plan.md` §2). No block on the UI layer.

## What I changed

No `lib/` change was required: the view/widget layer written in the previous
iteration already implements `1_plan.md` §1. I re-verified it line by line
against `1_plan.md`, `design/html-source/screens/P11-approvals.html` and the
design PNGs, then added the two proof suites the UI check needs:

- `app/test/features/approvals/approvals_view_geometry_test.dart` (NEW, 7
  tests) — real-font layout anchors, pinned to the design within ±2 px.
- `app/test/features/approvals/approvals_view_test.dart` (MODIFIED, +5 tests)
  — `SemanticsAction.tap` on every control plus `performAction(tap)` driving
  the real database/state.

Nothing outside `presentation/views`, `presentation/widgets`,
`test/features/approvals` and `docs/screens/P11` was touched. No bloc,
entity, model or repository edit.

## Verification of the existing implementation (plan ↔ code ↔ HTML ↔ PNG)

| plan / HTML | code | status |
|---|---|---|
| no `AppBar`, no tab bar (route is top-level) | `ApprovalsView` = `Scaffold(paper)` + `Column` | ✓ |
| `NestStatusBar` (reserves 47) + compact `NestNavBar` 'Waiting for you (N)' | `approvals_view.dart` 58–75 | ✓ |
| back = `canPop ? pop : go('/today')`, label 'Back to Today' | same, `'/today'` inlined with comment | ✓ |
| `.scroll` padding 0 20px **16px** + 16 between rows | `ApprovalsLoadedBody` `ListView.builder` + explicit `top: s4` pads | ✓ |
| `.helper` leaf-tint, `r-m` 16, pad 12/14, 14/20 leaf-ink | `ApprovalsHelperBanner` | ✓ |
| `.appr` surface, `r-l` 24, `sh-1`, pad 16 | `NestCard` standard | ✓ |
| `.avatar.s44` + `a-lilac`/`a-peach` | `NestAvatar` default `s44` + `approvalAvatarColor()` | ✓ (Maya lilac, Leo peach in `Seed.demo`) |
| `.who` 16/22 w700 truncate | `bodyStrong(ink).copyWith(height: 22/16)`, 1 line, ellipsis | ✓ |
| `.tm` 13/18 ink-2 `margin-top:2`, `.money` w700 + tnum | `Text.rich`, `fontFeatures: tabularFigures()` | ✓ |
| `.appr .row` gap **10**, `margin-top 14`, buttons `min-h 48 / 15 / pad 0 12` | `SizedBox(gap14)` + `Row(spacing: gap10)` + two `Expanded(NestButton(48, 15, s3))` | ✓ |
| `.bottom-cta .btn` `min-height 52`, label 'Approve all (N)' | `NestBottomCta` + `NestButton` default 52 | ✓ |
| empty / loading / failure / action-error states | `ApprovalsEmptyState`, leaf spinner, `Try again`, `SnackBar(tokens.danger)` | ✓ |
| `.qn` quote row | **omitted** — no data source (plan §0, `SHARED_REQUEST.md`) | ✓ documented |

## Measured anchors — design vs app (logical px, 390×844)

Design values measured off `design/screens/light/P11-approvals.png` by row/column
profile (helpers in the header of the geometry test); app values from
`approvals_view_geometry_test.dart` at 390×844 @3x with the bundled Inter /
Nunito faces loaded via `FontLoader`.

| element | design | app | Δ |
|---|---|---|---|
| status-bar reserve | 0–47 | 0–47 | 0 |
| compact nav bar | 47–107 | 47–107 | 0 |
| nav title box (18/24 w800) | — | 61–85, centred on 195 | ✓ |
| helper banner | 107–171 (h 64, 2 lines) | 107–171 (h 64, 2 lines) | 0 |
| card 1 top | 187 | 187 | 0 |
| card 2 top | 375 (design) / 341 (quote-less) | 341 | 0 vs plan |
| card 3 top | 563 (design) / 495 (quote-less) | 495 | 0 vs plan |
| card height | 172 (design) / 138 (no quote row) | 138 | 0 vs plan |
| card left / right | 20 / 370 | 20 / 370 | 0 |
| `.hd` avatar | x 36, 44×44 | x 36, 44×44 | 0 |
| `.who` | x 90, h 22 | x 90, h 22 | 0 |
| `.row` buttons | h 48, gap 10 (design y 295–343) | h 48, gap 10, 16 above card bottom | 0 (y differs by the 34 px `.qn`) |
| bottom CTA pill | 734–786 (design) | 776–828 | +42 — see below |
| bottom edge | paper strip 810–844 | surface to 844 | owner override |

**No uniform vertical shift**: every anchor above is exact. The two intentional
deltas are both in the brief:

1. **Quote-less cards** — the design's `.qn` line has no data source
   (`quest_completions` has no message column), so card *tops* and every other
   rect still match and each card is 34 px shorter. Do not "fix" this by
   hard-coding the mock quotes.
2. **Bottom CTA pill +42 px** — the design's `.bottom-cta` ends 34 px above the
   physical edge (its home-indicator strip is paper) which puts the pill at
   734–786. `NestBottomCta` runs `surface` to the edge per the OWNER
   bottom-edge rule, so the pill always sits 16 above the physical bottom
   (776–828). Same accepted deviation as P06/P12; the surface fill is asserted
   so a coloured strip can never come back.

### The finding that made the geometry test necessary

Pumped **without** the bundled faces, the helper copy wraps to **3** lines
(the flutter_test fallback font is ~10 % wider than Inter), the banner grows
84 high and every card slides down 20 px: card tops 207/361/495 instead of
187/341/495. That is precisely the "uniform vertical shift = FAIL" case the UI
VERDICT RULE forbids, and it is invisible to any test that does not load the
real fonts. `approvals_view_geometry_test.dart` therefore loads Inter + Nunito
through `FontLoader` (pattern copied from P10's `p10_bugs_test.dart`) and the
2-line banner is asserted directly (`_near(40)` text height), so the 20 px
slide can never come back unnoticed. The 5_ui stage should read the app
positions from that test and compare them with the PNG.

## Owner / orchestrator rules applied

- **DATA OVER MOCKS** — rows come from `state.items`; the design's
  "Tidy your bedroom" / "Yesterday 5:40pm" are never hard-coded. Tests assert
  the seeded rows (`Maya · Empty the dishwasher / Today 8:12am / 15 coins`,
  `Maya · Lay the table / …10 coins`, `Leo · Make your bed / …5 coins`).
- **BOTTOM EDGE** — `NestBottomCta` paints `surface` to the physical edge and
  is removed when the inbox empties; asserted (`cta.bottom == screen.bottom`,
  bar fill `== tokens.surface`) in both the view and geometry tests.
- **ALIGNMENT** — one gutter grid: banner, all three cards and the CTA pill
  are asserted to sit on exactly 20 / 370.
- **CHILD ORDER** — nothing to sort: the bloc emits newest-first and children
  arrive in creation order (Maya, Leo).
- **COPY** — banner is byte-exact (`U+201C`, `U+201D`, em dash `U+2014`);
  card copy uses `U+00B7` with single spaces. Asserted against the exported
  `approvalsHelperCopy` plus "no straight quote / no `--`" checks.
- **LETTER SPACING** — nothing added (P11's CSS sets none; `NestType`
  defaults to 0).
- **BALANCED HEADINGS / CHIP ROWS / TRIAL / FONTS / PIP / STATUS BAR** — none
  apply: no `text-wrap: balance`, no chips, no subscription state, no
  `PipAvatar` (initial avatars only), no `google_fonts`, status bar is
  height-only.
- **UI CHECK MEASURES SHAPES** — `BoxDecoration` shape assertions (leafTint +
  `allM` banner, three `surface` + `allL` cards) in light **and** dark, plus
  pill geometry (48 high, equal widths, 10 px apart, 16 above the card bottom)
  and the CTA pill rect.
- **ACCESSIBILITY ACTIONS** (new this iteration) — `hasAction(
  SemanticsAction.tap)` asserted for back, both row buttons, the CTA and
  "Try again"; `performAction(tap)` is then shown to change real state: card
  Approve removes that card and renumbers to `(2)`, "Not yet" removes the card
  **and leaves the `quest_bonus` ledger total unchanged** (queried from the
  test database), back navigates `/approvals → /today`, Try again re-subscribes
  (`attempts == 2`) and renders the rows.

## Tests (mine)

- `approvals_view_test.dart` — 16 tests (11 previous + 5 semantics).
- `approvals_view_geometry_test.dart` — 7 tests (light + dark anchors).
- `approval_card_widget_test.dart` — 16 tests (unchanged): pure time helpers,
  avatar colour, card internals, 16 px rhythm, empty state.

**Verification run**

- `dart format --output=none --set-exit-if-changed lib/features/approvals
  test/features/approvals` → 19 files, 0 changed.
- `flutter analyze lib/features/approvals test/features/approvals` →
  **No issues found!** (no ignores, no suppressions).
- `flutter test test/features/approvals` → **57/57 pass**.
- Whole-app `flutter test` and the simulator were left to the integrator per
  the stage rules; **no simulator was booted, installed on or captured**.

## LEFT FOR NEXT ITERATION

- Stage 5 (`5_ui`) owns the screenshots: `shot.sh` for `/approvals` in light +
  dark on `E7D5555E-378A-49DF-AAEE-16677AF4B9DB` and `compare.py`. The expected
  app positions are in the table above; the two accepted deltas are the
  quote-less cards and the +42 px CTA pill.
- The `.qn` quote row stays omitted until
  `docs/screens/P11/SHARED_REQUEST.md` lands (`quest_completions` has no
  message column). If `note TEXT DEFAULT ''` + seed values arrive,
  `ApprovalCard` needs one 17/24 w700 line at `margin-top: 10` between `.hd`
  and the 14 px button row.
- Open item for the logic builder (already reported in the previous 2b note,
  now fixed on their side): `approveAll()` had to stop using
  `watchItems().first`, which never delivers under `testWidgets` fake async.
  Re-check that `approvals_view_test.dart`'s end-to-end path still holds if
  they change it again — the geometry/semantics tests above must stay green.

VERDICT: PASS