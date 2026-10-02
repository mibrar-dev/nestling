# K03 Kid home — test notes (Stage 3, iteration 4)

Iteration 4 re-tests the screen after the iteration-4 build fixed
K03-BUG-10 (the dock surface now wraps the `SafeArea`, so the bar's own
colour runs to the physical screen edge) and extends the bottom-edge/owner
coverage to the new chrome structure. No screen bug was found this iteration.

## Files

- `app/test/features/kid_home/kid_home_view_test.dart` — 44 → 47 tests.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — 20 tests
  (unchanged this iteration; all green).
- `app/test/features/kid_home/k03_bugs_test.dart` — bug-hunt proofs,
  including the now-un-skipped `K03-BUG-10` proof (green).
- No `app/lib/**` change in this stage; nothing outside RULES §1 touched.

## New tests (this iteration, +3) and extensions

Bottom edge (owner rule, both themes via the existing light/dark loop):
- the bar spans the **full width to the edge** with a 34 px bottom inset
  (`left 0`, `right 390`, `bottom 844`) and its buttons stay **above** the
  inset (the bar runs to the edge, its content does not slide under the OS
  home indicator);
- 430 px: the bar still runs to the edge with an inset and the cards keep the
  20 px gutter;
- a 59 px **top** inset reserves the status bar (STATUS BAR rule: the widget
  only reserves height, content starts below the OS inset) and leaves the
  bottom edge intact — no overflow at a real iPhone inset pair.

Alignment (owner rule) — the previous single-edge check was extended to:
- both edges: header avatar (left), lock (right), quest cards, the kid
  progress bar and the section count chip all sit on the 20 px gutters;
- the three dock buttons are equal-width, with 12 px gaps and outer edges on
  the same gutters as the cards (vertical heights are deliberately not
  compared: the fallback test font wraps "My jar" — see notes).

## Results

- `dart format --set-exit-if-changed .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — `+476 ~1`: 476 pass, 1 skip (the shared motion-flag proof,
  conditional on the dart-define by design).
- K03 alone: 103 pass + 1 skip (bloc 20, view 47, bug proofs 36).

## Bugs found

None in the K03 screen this iteration. K03-BUG-10 (the bottom-edge violation
found in iteration 3) is fixed: both light/dark proofs now assert the dock
surface at `bottom 844` with a 34 px inset and pass, as does the feature's
`K03-BUG-10` proof in the bug suite.

## Shared item (not a K03 screen bug, still open)

**K03-BUG-7 (`DISABLE_ANIMATIONS=1`) remains unfixed in shared code.** This
branch's main still reads
`kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`, which
parses `"1"` as false, so the documented flag does not disable motion. Proof:
`flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"
test/features/kid_home/k03_bugs_test.dart` → `Expected: true; Actual:
<false>`. The proof is conditionally skipped in the plain suite (by design),
so it is not a K03 failure; the fix belongs to `core/data` + `app/`
(SHARED_REQUEST #5). No K03 screen change can affect it.

## Verified green this iteration

- BOTTOM EDGE rule: dock surface covers the inset to the physical edge, full
  width, both themes, at 390 and 430 px; buttons stay above the inset; the
  home-indicator zone uses the bar's own colour (no meadow/sky strip).
- ALIGNMENT rule: header, cards, progress bar, section chip and dock all
  share the 20 px side gutters; the three dock buttons are equal-width with
  12 px gaps.
- STATUS BAR rule: a 59 px top inset is reserved, no overlap, no overflow.
- All iteration 1–3 coverage still green: the 12-cell light/dark ×
  320/390/430 × scale 1.0/1.3 matrix, empty/loading/error states, every tap
  destination (card → `/quest-detail`, check → `/quest-complete`, lock →
  `/parental-gate`, dock → `/pip` `/reward-shop` `/my-jar`, Choose → picker,
  Try again), semantics labels, kid tap targets ≥ 56, the PipAvatar mandate
  (Maya/Leo/accessorised/empty/failure, no v1 `pip_stage_*.svg`), PERIODS
  (daily/weekly/once + fresh completion for a new period), and the
  celebration/latch behaviour.

## Notes / observations (not bugs)

1. The fallback test font renders each glyph wider than Nunito, so in
   `flutter test` the "My jar" dock label can wrap and that button measures
   ~80 px tall versus ~72 px for its siblings. This is a font-substitution
   artifact of the test environment (no runtime Google Fonts fetching), not
   a layout difference, so the alignment test compares widths/gaps/edges only.
2. The dock-top ~6 px residual vs the design rows is shared-component
   geometry (the `NestKidButton` shadow reserve), documented by the
   iteration-4 build as a standing minor; the test only asserts the inset
   accounting, which is exact.
3. Period tests derive their boundaries from
   `londonDayStartUtc/londonWeekStartUtc(DateTime.now())`, so they stay
   deterministic while the machine clock shares the pinned anchor's London
   week (the coupling the bug suite documents).
4. Harness notes unchanged: direct Drift work inside a `testWidgets` body
   must use `tester.runAsync`; set insets via `tester.view.padding` /
   `viewPadding` (physical px at 3×) before pumping; avoid `pumpAndSettle`
   while a loading spinner can be on screen; use `tester.getSemantics` for
   merged card labels.

VERDICT: PASS
