# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 6)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). All `ORCHESTRATOR_NOTES.md` items (04:05, 07:22, 07:58) are
verified below. No screen code was changed by this stage — only
`app/test/features/pocket_money/p06_bugs_test.dart` and this report.

Suite state: `flutter test test/features/pocket_money/p06_bugs_test.dart` →
**+27 ~1: All tests passed!** The one skip is the new minor finding; without it
the run is `+27 -1` with exactly the P06-BUG-13 assertion failing.

## Open bugs

### P06-BUG-13 (minor) — the "Coin value" label ellipsizes at 320dp × 1.3

**Where:** `_CoinValueRow` in
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart`
— one row, two flex children (`Expanded` label + `Flexible` value), no wrap
branch.

**Repro / evidence (real bundled fonts):** at 320dp with the accessibility
text scale at 1.3 the row's 196 dp of content split evenly gives the label
98 dp while Inter 16 × 1.3 needs ~105, so `Coin value` paints truncated with
an ellipsis (`RenderParagraph` 98×29, `didExceedMaxLines = true`). The
weekly-base rows handle the same 320 × 1.3 combination by wrapping
(`_WeeklyBaseRow._wrapWidth = 300`); the coin row has no equivalent. A
real-font sweep of every `Text` at 320/390 × 1.0/1.3 shows this is the only
unsanctioned truncation: 320 × 1.0 truncates only the trailing
`10 coins = 10p` (plan §5 explicitly sanctions that ellipsis), 390 truncates
nothing.

**Failing test:** `P06-BUG-13: the "Coin value" label must not ellipsize at
320dp × 1.3` (skipped; asserts `didExceedMaxLines == false` plus the day pill
still at 32 dp).

**Fix (screen scope):** give the coin row the same narrow-width treatment as
the weekly-base rows — under ~300 dp row width stack the label/value onto a
second line (or let the label wrap to two lines) so both render in full; keep
the trailing value's ellipsis as the last resort.

## Iteration-5 findings — fixed and verified

| # | Was | Fix | Guard now green |
|---|---|---|---|
| 11 (major) | `NestBalancedText` collapsed the H1 to one ellipsized line and pulled the card 34 px high | main's `shared/balanced_text_ellipsis` (no ellipsis when `maxLines == null`); view unchanged | `P06-BUG-11 (fixed)`: H1 = **331.2×68**, `didExceedMaxLines` false, line 1 ends after **"How does pocket money"**, card top **415** |
| 12 (minor) | stepper minus was `-` (U+002D) | `P06WeeklyStepper` (feature-private copy of `NestStepper`) renders `−` U+2212 next to `+`; shared component untouched | `P06-BUG-12 (fixed)`: minus `== '\u2212'`, plus `== '+'` |

## Independent geometry verification (real Inter/Nunito, light + dark)

The real-font guard now sweeps both themes and pins the design anchors from
`P06-pocket-money.png` ÷3 at 390×844 — every value within ±1:

| Anchor | Design | App (both themes) |
|---|---|---|
| H1 top / height | 107 / 68 (two lines) | 107 / 68 |
| settings card top / height | 415 / 270 | 415 / 270 |
| day pill top / height | 455 / 32 | 455 / 32 |
| last pill right | 354 (= card 16 px inset) | 354 |
| Weekly base label top | 503 | 504 |
| Maya / Leo text top | 534 / 578 | 535 / 579 |
| Coin value text top | 639 | 640 |
| gap chain | 6 / 17 / 13 / 22 / 39 / 23 | exact |
| 07:58 title-anchored offsets | 296 / 329 / 359 / 403 / 464 | exact |

## Attacks that hold (unchanged, all green)

Kid-mode deep link → `/parental-gate`; restart persistence on a file-backed DB;
6 children incl. “Maximilian-Alexander” at 320 × 1.3; 0 children caption;
£0.00/£20.00 exact; rapid stepper/day chains (BUG-01/01b/01c, 02/02b);
`NestChipWrap` ±5 px and gap taps; seed `onboarding_kids` from the DB in
insertion order; option-card 22/20 line heights; gold coin tile; async gap on
close; WCAG 4.5:1 in both themes; `P06WeeklyStepper` is byte-identical to the
shared stepper apart from the two glyphs (diff-checked).

## Notes, not bugs

- **`P06WeeklyStepper` is a feature-private copy of `NestStepper`** pending
  `SHARED_REQUEST.md` item 4 (glyph override on the shared component); the
  copy is faithful (diff-checked) and retires in one edit when the shared
  change lands. `_DayPill` similarly awaits item 5.
- **320 × 1.3 day labels** (`Mon`/`Wed`/`Thu`/`Sun`) ellipsize to two
  characters plus `…`. Noted since iteration 4; SPACING_SPEC §10.1 sanctions
  `maxLines: 1 + ellipsis` for chip text at large scales (the §10.3
  `scaleDown` alternative remains the nicer fix if the shared chip variant
  ever lands).
- **Empty-state copy** `Add children to set weekly amounts.` (renders only for
  `Seed.empty`/`Seed.fresh`) still awaits orchestrator ratification — review
  finding #11, carried forward untouched.

## Verdict rationale

Both iteration-5 findings are independently verified fixed, the full design
geometry now matches in light and dark within a pixel, and every earlier guard
still holds. One new minor finding remains — the "Coin value" label truncates
at the extreme 320dp × 1.3 combination, contained and with a one-branch fix
suggested. No major bug is open, so the stage passes.

VERDICT: PASS
