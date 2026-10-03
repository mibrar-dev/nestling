# P05 · Add children — test notes (STAGE 3, iteration 8)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/add_children_test.dart` plus these notes — no product
code touched, no simulator used (SIMULATORS rule: stage 5 only).

Suite green: **+1160 passing, 0 failures, 0 skips** full app,
**+135** in `test/features/family/`. `flutter analyze` → No issues found,
`dart format` clean.

The two new mandatory components landed and the build stage wired both in:
`NestChipWrap` in `add_child_form_card.dart` and `NestBalancedText` for the
`.h1` in `add_children_view.dart`. **P05-BUG-11 is closed** — its proofs are
un-skipped and pass, and the feature dir now has no `skip:` at all (previous
iterations' single skip is gone).

## Tests added (5)

### BALANCED HEADINGS rule — 2 tests, group *P05 balanced headings*
The rule is mandatory and structural: `.h1` has `text-wrap: balance`
(`components.css:29`), so the heading renders through `NestBalancedText` with
the same copy, style and `maxLines` — and `.h2/.h3/.body/.caption` never do.
Nothing pinned either half, so both are now guarded:

1. **the h1 is balanced, with its copy, style and maxLines kept** — exactly one
   `NestBalancedText` on the screen (the `.h3` "Add a child" and the caption are
   *not* balanced, and a stray extra node would balance the wrong string), the
   copy is `Who’s in your nest?` with U+2019, `style == NestType.h1(color:
   tokens.ink)`, `maxLines == 3`, `overflow == ellipsis`, `textAlign == left`,
   and the plain `Text` inside it is the only node painting that string.
2. **the h1 never overflows across the matrix (width, scale, theme)** — all 12
   combinations of 320/390/430 × scale 1.0/1.3 × light/dark: the rendered height
   stays within 3 line boxes (`fontSize × height` × the matrix scale) and no
   ellipsis appears, so the heading is balanced rather than clipped.

### CHIP ROWS + "measure shapes, not text" — 3 tests, group *P05 chip tap area*
3. **the chip row is a NestChipWrap (CHIP ROWS rule)** — the behavioural ±5 px
   taps already pass, but they only exercise the block's two outer edges. A
   structural guard stops a refactor back to `Wrap`/`Row` from silently
   reintroducing the clipping: exactly **two** `NestChipWrap` rows (age chips and
   the avatar swatches — the build wrapped both), every chip and swatch sits
   inside one, and no plain `Wrap`/`Row` sits between the wrap and any item.
4. **the widened swatch row target stops before label and caption** — the swatch
   row is now a `NestChipWrap` too, so its hit area overhangs the 44-px discs.
   Pinned: 4 px below `.lbl` (`margin-top: 4px`), 6 px above the caption
   (`gap6`), and a tap at the "Avatar colour" label centre or the caption centre
   selects **nothing** while the draft default (peach) stands. A tap 5 px above
   the row also selects nothing — measured, not assumed: `NestChipWrap` forwards
   its widened hit test to the nearest **`NestChip`**, so it never reaches
   already-44-px swatch boxes. That is correct (the discs meet the ≥44 rule on
   their own) and is the exact behaviour a UI check would want. Tapping the disc
   dead centre selects it and single-selects.
5. **the swatch fill is a 44-px disc with the design row geometry** — the
   swatch-side answer to "P05 passed a UI check with chips whose pills had
   collapsed to text width". For all five colours the **painted** `DecoratedBox`
   rect equals the whole 44×44 box (a solid disc, not a dot inside a target),
   `.swatches { gap: 8px }` holds between them, the row starts on the card
   content edge and sits 4 px under "Avatar colour". Measuring the paint (not the
   tap box) is what makes this non-vacuous: a collapsed fill would fail it.

## Existing mandatory proof, re-verified

`[P05-BUG-11] the 44-px tap target reaches 6 px above and below the run` (and its
sibling in `p05_bugs_test.dart`) now pass un-skipped: taps 5 px above the first
run and 5 px below the last select their chip, and a tap 7 px below — outside
the 44-px target — changes nothing, so the widened hit test has not swallowed
the card. The 32-px layout assertion in *P05 tap targets* stays, with the reason
spelling out that the 44 px is overlaid and that the functional proof is the
±5 px test: with the overlay, the ≥44 rule can only be proven by taps, and
`SPACING_SPEC` §10.6 wants "keep visual size".

## Results

```
dart format .        clean (391 files, 0 changed)
flutter analyze      No issues found!
flutter test         00:22 +1160: All tests passed!
  test/features/family/   135 tests, 0 failures, 0 skips
```

No skips remain in the feature: the previous iteration's single mandated
`skip: true` (P05-BUG-11) is gone now the shared fix has landed. Coverage is
unchanged and green for the rest of the matrix — bloc event/state paths, light +
dark, 320/390/430 × scale 1.0/1.3, `Seed.demo`/`empty`/`fresh`/`onboarding_kids`,
loading/error/retry, every tap → route, semantics labels, tap targets, form-card
rhythm vs the HTML, copy character-exact, child order, bottom edge and
alignment. Every app-pumping test ends with `disposeApp(tester)`.

## Bugs found

**None.** No P05-owned test failed and no defect was found in the screen.

Two things I measured and deliberately did **not** file as bugs:

* The swatch row's 5-px overhang is inert (test 4). A shared-component nuance,
  not a P05 defect — recorded as a follow-up note in `SHARED_REQUEST.md` so the
  component docs mention that the widening targets `NestChip` children.
* The gap above the chip row is 4 px, not the ≥6 px the iteration-7 note
  assumed. Reachability depends on the ancestors' boxes, not on clear space, and
  no ancestor is tight (proven by *P05 chip row hit-area preconditions*), so the
  44-px target is fully reachable anyway.

`SHARED_REQUEST.md` is updated: the P05-BUG-11 entry is marked **RESOLVED** with
the landed proofs named, and the durable `createdAt` CHILD ORDER request stays
open (it lands with the schema v3 core ordering, already on main).

## Rules re-audited

* **FONTS** — `google_fonts` appears nowhere in `app/lib` or `app/test`.
* **LETTER SPACING** — pinned by the sweep test that fails on any positive
  tracking; `NestBalancedText` brings the h1's `NestType.h1` style through
  unchanged, so it adds none.
* **CHIP ROWS** — both interactive rows are `NestChipWrap` (test 3).
* **BALANCED HEADINGS** — the h1 is balanced, nothing else is (tests 1–2).
* **UI CHECK MEASURES SHAPES** — the pill background (text + 14 px a side, 32
  high, painted rect == chip box) and now the swatch disc (44×44 painted) are
  measured as backgrounds, not text positions.
* **CHILD ORDER** — Maya-first group, including the rename proof that stays green
  after the durable `createdAt` ordering lands.
* **COPY** — code-unit assertions (U+2019 in the balanced heading, em dash, en
  dashes, UK `colour`).
* **BOTTOM EDGE / ALIGNMENT** — CTA-to-edge and 20-px gutters at every width in
  both themes.
* **PIP** — no Pip slot on this screen (avatar discs + initials), so N/A.
* **TRIAL / PERIODS** — P05 writes no `subscription_status` and has no quests.
* **SIMULATORS** — none used by this stage.

VERDICT: PASS
