# Shared requests — P12 Money (ledger)

Three items from `docs/screens/P12/FIXES_1.md` are cross-screen and live
outside `app/lib/features/pocket_money/**`. P12 is fixed locally where it can
be (see `2b_build_ui.md`); these three need the orchestrator.

---

## 1. `nest_list_row.dart` — the standard tile is 4 px too square

**Need.** `core/design_system/components/nest_list_row.dart:65` applies the
**compact** 36 px tile radius (12 px, `P02-value-tour.html:25`
`.pg-rows .icon-tile{…border-radius:12px}` — the doc comment at
`nest_list_row.dart:32` already attributes 12 to the compact variant) to the
**standard** 40 px tile as well. `components.css:110` is
`.icon-tile { width:40px; height:40px; border-radius: var(--r-m) }` and
`tokens.css:77` is `--r-m:16px`. Scanning the design PNG's first P12 history
tile reproduces r = 16 to < 0.2 px over 15 rows (predicted vs measured left
edge at y+1, +3, +8, +12: 46.43/46.33, 42.67/42.67, 38.14/38.00, 36.51/36.67);
r = 12 is off by up to 3.1 px.

**Fix.** Split the radius from the size — one `tileRadius` (or `compact`
variant flag) on `NestListRow`, defaulting to `NestRadii.allM` for the
standard 40 px tile and 12 only for the compact 36 px one. Every screen using
`NestListRow` with the standard tile is currently 4 px off.

**Files.** `app/lib/core/design_system/components/nest_list_row.dart`

**Blocks.** No — P12's `MoneyHistoryRow` is fixed locally (it pins
`NestRadii.allM` and a geometry test asserts the painted radius). This is for
the other screens.

---

## 2. `NestPageTitle` — `.ptitle` is a private class on four screens

**Need.** `.ptitle` (`P12-money.html:3`: `font-family:var(--font-display);
font-weight:900;font-size:28px;line-height:34px;padding-top:8px`) appears in
`P10-quest-library.html`, `P12-money.html`, `P13-payout.html` and
`P16-settings.html` — four screens, one private re-implementation per screen.
Iteration 1's P12 defect was exactly this class of drift: an extra spacer
above the title pushed the whole screen 16 px down because each screen
re-derived the `.ptitle` top spacing instead of sharing one component.

**Fix.** Add a shared `NestPageTitle` to the design system — `NestType.h1`
(28/34 w900) + `padding-top: 8` + `Semantics(header: true)` + `maxLines: 1`
with ellipsis — and have the four screens use it.

**Files.** `app/lib/core/design_system/components/` (new), then the four
screens' private `_PageTitle` widgets.

**Blocks.** No — P12 keeps its private `_PageTitle` (correct geometry, now
pinned by `money_ledger_geometry_test.dart`).

---

## 3. `NestSegmented` — options collapse below 44 px with six children at 320 dp

**Need.** `core/design_system/components/nest_segmented.dart` divides its
width equally between options. With six children at 320 dp the five 4 px gaps
plus 4 px track padding leave 280 px for six options: **42 px each**, under the
parent-mode 44 px tap-target rule, and long names truncate to ~5 characters
(`Maximili…`). At 390 dp the same roster gives 53.7 px, so it is a 320 dp-only
collapse. `p12_bugs_test.dart` P12-BUG-04 is the reproducer (kept `skip: true`
— see below).

**Fix.** Make the control scroll horizontally (or wrap to a second row) when
`width / options.length` would drop below `NestDevice.tapParent`.

**Files.** `app/lib/core/design_system/components/nest_segmented.dart`

**Blocks.** No for `/money` (P05 is the only roster screen; this is a
narrow-width edge case, not a blocker) — but P12 must **not** fork the shared
control locally, so P12-BUG-04 stays skipped until the shared fix lands.

---

## Not requested here (deliberately)

* **`NestType.bodyStrong` 16/24 → a 22 px line box variant.** P12's
  `.goal .t` (`font-weight:700;font-size:16px;line-height:22px`) needed 22 and
  is pinned at the call site with `copyWith(height: 22 / 16)`, following the
  precedent of `.hero .amt`'s −0.4 tracking. If more screens need a 16/22
  strong body, add it as a named style; P12 does not need it today.
* **`.hero .lab`'s 17 px line box.** Same reasoning: the CSS sets no
  line-height, so it resolves to the font's `normal` for 14 px Inter
  (16.94 ≈ 17) and is pinned at the call site. Too screen-specific for the
  design system.
* **Raw `error.toString()` in `errorMessage` (4_review.md finding 7).** The
  mapping belongs in `pocket_money_bloc.dart`, which this stage does not own.
  Handed to the logic builder in `2b_build_ui.md`.
