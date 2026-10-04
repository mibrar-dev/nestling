# List row trailing — REPORT (branch `shared/list_row_trailing`)

Scope: fix `NestListRow` so the trailing takes its intrinsic width at the
right edge (P16 truncation + mid-row chevron) and lock the row height to
the CSS. Minimal, backward-compatible shared change: one widget swap, one
new public constant, no public API change, no screen-code edits. Screen
branches merge without edits.

## Files changed

- `app/lib/core/design_system/components/nest_list_row.dart` — the
  trailing changed from `Flexible(child: tail)` (equal flex share: the
  `Expanded` text column got half the free width — 129 px at 390 instead
  of the design's ≈187 px — and the chevron parked mid-row) to a plain
  child after the `Expanded` column wrapped in
  `ConstrainedBox(maxWidth: trailMaxWidth)` (`.list-trail {
  flex-shrink: 0 }`, `components.css:119`). The `Row(spacing: s3)` gap is
  unchanged and is already the design's 12 px gap. New
  `NestListRow.trailMaxWidth = 120`: overflow guard only, not a layout
  target — while the trailing fits, the text column keeps the remainder;
  only a wider trailing is clamped (text keeps ≥ 68 px even at 320 wide).
  120 covers the widest known trailing (`Change ›` at 70.7 px, per the P15
  measurement) with headroom; every current caller (chevron `›`, `+ Add`,
  coin pills, 44 px icon button) is far under it, so nothing reflows.
- Tests: NEW `app/test/design_system/list_row_trailing_test.dart`
  (4 tests, real Inter/Nunito via `FontLoader` exactly as
  `test/features/auth/typography_test.dart` does — `flutter test`'s
  fallback glyphs are ~2× the design advances, so the ellipsis assertions
  are meaningless without it).

## What / why

`Flexible` defaults to `flex: 1`, so the row distributed free space
evenly between the text column and the trailing: the subtitle slot was
halved (probe before the fix: text column 129 px wide,
`didExceedMaxLines == true` on `Pip: Fledgling · 120 coins`; chevron rect
right at 241 vs content right 354). After the fix the column is 242 px,
the subtitle fits, and the chevron's right edge == content right edge
exactly. `ConstrainedBox` (not `Flexible`/`Expanded`) keeps the trailing
out of the flex distribution while bounding pathological widths.

ROW HEIGHT finding: no code change was needed. `.list-row`
(`components.css:107`) is padding `10px 16px 10px 12px` + min-height 56,
i.e. title 22 + sub 18 + padding 20 = 60 with a subtitle, 56 binding only
for short tile-less rows. The component already lays out exactly that
(probed 60.0 before and after the fix). Design-side check on
`design/screens/light/P16-settings.png` ÷ 3: divider rows at 197/257
(card rows 137/197/257), 425/485 (rows 365/425/485), 726 — uniform pitch
60 everywhere, matching the component's 60. (The brief's "221, 281, 341"
does not match the design PNG; those look like app-render positions, but
the pitch is 60 either way.) The new height test locks 60/56 so any
future drift fails loudly. The P16 "+2 px" was therefore not in the
shared row geometry — likely P16-local composition; P16 should re-shot
after merging this branch and confirm its rows land on the 60 grid.

## Tests added (`list_row_trailing_test.dart`)

P16-like row at the real list width (350 = 390 − 2 × 20 scroll gutters),
`NestIcons.lock` tile, P15-style `›` trailing:

- `subtitle renders in full at 390` — `Pip: Fledgling · 120 coins`
  (and the title) `didExceedMaxLines == false`.
- `chevron right edge meets the row content right edge` — chevron right
  vs row-box right − 16 within ±1 (measured exactly 0 after the fix).
- `row height matches the CSS (60 with sub, 56 title-only)` — 60 for
  title + subtitle with tile; 56 for a tile-less title-only row
  (min-height binds: 22 + 20 = 42 < 56). Note: WITH a 40 px tile a
  title-only row is 60 in both CSS and Flutter — the tile, not the
  min-height, binds.
- `a long trailing word stays intact` — trailing `Change` unellipsized
  and the subtitle still fits beside it.

No test asserts placeholder view texts; all assertions use the test's
own copy, `RenderParagraph.didExceedMaxLines`, and box rects.

## Local workarounds found in `app/lib/features` (NOT edited)

- `family/presentation/widgets/child_profile_row.dart` (P15
  `ProfileRow`) — the direct workaround for THIS bug: reproduces
  `.list-main flex:1 / .list-trail shrink-0` locally and says to delete
  itself when the shared fix lands. P15 can now delete it and go back to
  `NestListRow` (keeping its `leading` builder only if the shared
  `leadingAsset` still cannot render the coloured coin illustration —
  see its `SHARED_REQUEST.md` §2).
- `pocket_money/presentation/widgets/money_history_row.dart` (P12
  `.hrow`) — local row for its own CSS class (no dividers, no tap,
  signed amounts, coin illustration); not this bug, permanent.
- `onboarding/presentation/widgets/value_tour_preview_row.dart` (P02
  `.pv-row`) — different metrics (38 px compact pager rows), explicitly
  permanent; not this bug.
- `privacy_consent/presentation/views/privacy_consent_view.dart` (~l230)
  — mirrors `NestListRow` geometry with P04 wins (7 px vertical padding,
  wrapping title/sub); unaffected by this change (it never used the
  shared trailing path).
- `pocket_money/presentation/views/pocket_money_setup_view.dart` (~l762)
  display-only coin-value row, `rewards/presentation/widgets/
  p14_reward_card.dart` (`.rw` with its own 98 px middle column) —
  independent local layouts, not this bug.

## Follow-up screens must do

- P15: optionally delete `child_profile_row.dart` and return to
  `NestListRow` (see above); no action required — `ProfileRow` keeps
  passing (its geometry already matches the fixed shared row).
- P16: re-shot light + dark after merging; rows should sit on the 60
  grid with `Pip: Fledgling · 120 coins` in full and the chevron at the
  content right edge. If any row still measures off-grid, the cause is in
  P16 composition, not the shared row (locked at 60/56 here).
- Gallery (`design_system_gallery`): unchanged output expected
  (`overflow_test` + gallery suites green); the long-title demo row
  still truncates by design (maxLines 1 + ellipsis on the title).

## Verification

- `cd app && dart format .` — clean (test file formatted).
- `flutter analyze` — `No issues found!` (no new ignores).
- `flutter test` (full suite) — all passed (2714 +0 −1 skip, skip is
  pre-existing).

VERDICT: PASS
