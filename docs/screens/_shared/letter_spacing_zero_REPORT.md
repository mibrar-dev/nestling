# Shared letter_spacing_zero report

Branch: `shared/letter_spacing_zero` (from `main`).

## Root cause

`design/html-source/components.css` sets `letter-spacing` only on `.display`
and `.status-time` (`-.01em`). Every other class uses the browser default of
0. `NestType._inter` / `_nunito` passed `letterSpacing: null` by default, so
every style without an explicit value inherited the Material 3 theme /
`DefaultTextStyle` spacing (e.g. 0.25, 0.5, 0.1) and rendered wider than the
design (P04 option title 242.5 px design vs 250.2 px app, wrapping a line).

## Files changed

| File | What / why |
|---|---|
| `app/lib/core/design_system/tokens/typography.dart` | `_inter` / `_nunito` default to `letterSpacing ?? 0`, so all 26 public styles carry an explicit value matching the CSS (0 unless the CSS sets it). The three pre-existing explicit values verified against CSS and kept (see table). No other metric changed. |
| `app/lib/core/design_system/components/nest_avatar.dart` | Hand-built `TextStyle` for the avatar initial gains `letterSpacing: 0` (`.avatar` sets none; null would inherit ambient spacing). |
| `app/lib/core/design_system/components/nest_pet_stage.dart` | Hand-built `TextStyle` for the speech bubble gains `letterSpacing: 0` (`.speech` sets none). |
| `app/test/core/design_system/letter_spacing_test.dart` | New shared test (26 static + 4 widget tests, see below). |
| `app/lib/app/**` | Checked, no change: no `textTheme`, `Typography.material2021`, or button/chip/input theme sets letter spacing. `NestTheme` builds its entire `TextTheme`, button/chip/segmented text styles, and input decoration styles from `NestType`, so the token fix covers them. |
| Other core components (`NestButton`, `NestChip`, `NestTextField`, `NestListRow`, keypad, stepper, …) | Checked, no change: all text goes through `NestType` (`.copyWith` preserves the now-explicit 0). |

## NestType letterSpacing: old → new + CSS source

Old `null` rendered as the inherited Material 3 value; new `0` renders as
the design's browser default. The three explicit values were already correct.

| Style | Old | New | CSS source |
|---|---|---|---|
| display | -0.34 | -0.34 (kept) | `components.css .display letter-spacing:-.01em` × 34 px |
| h1 | null | 0 | `components.css .h1` sets none |
| h2 | null | 0 | `components.css .h2` sets none |
| h3 | null | 0 | `components.css .h3` sets none |
| body | null | 0 | `components.css .body` sets none |
| bodyStrong | null | 0 | `.body` sets none |
| bodySmall | null | 0 | `components.css .body-s` sets none |
| bodySmallStrong | null | 0 | `.body-s` sets none |
| caption | null | 0 | `components.css .caption` sets none |
| fieldLabel | null | 0 | `components.css .field label` sets none |
| sectionLabel | 0.78 | 0.78 (kept) | `P16-settings.html .sect` / `P08-today.html .qgroup letter-spacing:.06em` × 13 px |
| chipLabel | null | 0 | `components.css .chip` sets none |
| chipSmall | null | 0 | `components.css .badge-count`, P08 `.status-chip` set none |
| navCompact | null | 0 | `components.css .nav-bar.compact .nav-title` sets none |
| tabLabel | null | 0 | `components.css .tab` sets none |
| buttonLabel | null | 0 | `components.css .btn` sets none |
| money | null | 0 | `components.css .money` sets none |
| statusTime | -0.15 | -0.15 (kept) | `components.css .status-time letter-spacing:-.01em` × 15 px (`.status-bar` font-size) |
| kidBody | null | 0 | `components.css .kid-body` sets none |
| kidTitle | null | 0 | `components.css .kid-title` sets none |
| kidHero | null | 0 | `components.css .kid-hero` sets none (P12 `.hero .amt` is a separate screen override, see follow-ups) |
| kidName | null | 0 | K03 header name sets none |
| kidCaption | null | 0 | K03 copy under the name sets none |
| kidChipLabel | null | 0 | K03 status chip label sets none |
| buttonKid | null | 0 | `components.css .btn-kid` sets none |
| coinPill | null | 0 | `components.css .coin-pill` sets none |

Screen-CSS `letter-spacing` values with no `NestType` counterpart are
screen-wins overrides the owning screen applies at its call site (see
follow-ups): P12 `.hero .amt` −.01em (−0.4 at 40 px), P08 `.greet-text h1`
−.01em (−0.22 at 22 px), P08 `.greet-text .date` −.01em (−0.15 at 15 px),
K02 `.k2-hi .mark` +.08em (+1.28 at 16 px). Store/marketing pages
(`design/html-source/store/**`, `play/**`) are out of scope for the app type
scale. `design-system.html`'s doc-table header (`.04em`) is dev-docs only.

## Tests added (`app/test/core/design_system/letter_spacing_test.dart`)

- Static (26): one per public `NestType` style asserting `letterSpacing`
  equals the CSS value from the table above.
- Widget (4, pumped in the real app theme via `pumpNest` → `NestTheme`):
  `NestButton label resolves to 0`, `NestChip label resolves to 0`,
  `NestTextField labels resolve to 0`, `body text resolves to 0 in the app
  theme`. Each collects every `RenderParagraph` (`RichText`) and asserts each
  span's inherited-resolved `letterSpacing` is 0 (null counts as 0, since it
  renders as no extra spacing).

## Verification

- `cd app && dart format .` — clean (0 changed at final pass).
- `flutter analyze` — `No issues found!`, no new ignores.
- `flutter test` (full suite) — all pass (`+694: All tests passed!`). No
  shared test needed fixing; no feature test broke, so no feature code was
  touched.

## Follow-ups for screens

None broken (full suite passes). When building these screens, apply the
screen-wins CSS spacing at the call site via
`NestType.<style>(…).copyWith(letterSpacing: …)` — do not change the shared
token:

- P12 (money ledger): hero amount `.hero .amt` needs `letterSpacing: -0.4`
  (Nunito 40/44 w900 is `kidHero` geometry but `kidHero` is correctly 0 per
  `.kid-hero`; add the override where the hero amount is built).
- K02 (kid PIN): `.k2-hi .mark` pill needs `letterSpacing: 1.28`.
- P08 (today): already handled (`today_loaded_body.dart` carries `-0.22` /
  `-0.15` for the greeting + date). No action.
- All screens: text now renders narrower (Material tracking removed). If a
  golden or geometry test was tuned to the old widths, re-check it against
  the design PNG rather than restoring spacing.

VERDICT: PASS
