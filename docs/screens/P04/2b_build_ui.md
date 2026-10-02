# P04 · Privacy consent — STAGE 2b UI build (iteration 7)

Scope: `presentation/views/**` + view/widget tests in
`app/test/features/privacy_consent/`. No edits to `domain/`, `data/`,
`presentation/bloc/` (logic builder's layer).

## Situation on entry

FIXES_6.md embeds the stage-6 bug hunt written against the **iteration-4
tree** (its own header: "Re-hunted the iteration-4 tree"). Every UI item it
lists was already landed in this worktree by iteration 5 and verified by
iteration 6 (`2_build.md`, `6_bugs.md` suite tails). Verified line-by-line
this stage rather than re-applied:

| FIXES_6 item | State in this tree (verified) |
|---|---|
| P04-2 — wire `NestIcons.trash` into row 4 | Done: `privacy_consent_view.dart` row 4 `leadingAsset: NestIcons.trash`, `NestTileTint.peach`; no `TODO(P04)` anywhere in lib/test |
| P04-2 companion test flip | Done: contract test asserts all four `NestIcon`s (assets + light/dark inks), four painted `SvgPicture`s, row 4 = trash/`aPeach`; `[P04-2]` un-skipped, green |
| P04-7 — dark mode `NestPrivacyShield` | Done: view renders `NestPrivacyShield(semanticLabel: …)` (size defaults 84); no `flutter_svg`/baked asset left in the view; `[P04-7]` un-skipped, green |
| P04-7 companion shield test | Done: "the shield is 84x84 and labelled" asserts `find.byType(NestPrivacyShield)`, size 84, design alt text |
| Review cleanup 3 — four direct `NestList` children | Done: no local `showDivider`/`Stack`/single-`Column` in the view; shared `NestList` owns the overlay separators |
| Review cleanup 4 — `dividerOf(0)` result check | Done at two sites (`findsNothing` on row 1); remaining `byType(Stack)` uses are ancestor lookups measuring the shared overlay's geometry on rows 2–4, which is the intended result check |
| Review cleanup 5 — `2_build.md` test-tail quote | Done in iteration 6 (documentation) |
| Un-skip `[P04-2]`/`[P04-7]` | Done: `grep "skip: true"` over the P04 tests returns nothing; suite runs with 0 skips |

ORCHESTRATOR_NOTES items 1–4: met (trash glyph both themes; header offsets
pinned by `[P04-3]`; row heights/dividers Δ0 pinned by `[P04-4]` + the
separator-overlay contract; bottom-edge CTA surface + 20 px gutters pinned by
the alignment contract tests).

## Files changed this stage (all inside RULES §1)

The `1b2109e` main merge removed `google_fonts` from pubspec/lockfile
(bundled Inter/Nunito assets), leaving 4 P04 test files with unresolvable
imports — **16 compile errors, the feature test suite did not build**. Per
the FONTS orchestrator rule ("delete any such lines in your feature's
tests"), removed `import 'package:google_fonts/google_fonts.dart'` and every
`GoogleFonts.config.allowRuntimeFetching = false;` call from:

- `app/test/features/privacy_consent/privacy_consent_view_test.dart`
  (import, one pump-helper call, one now-empty `setUp` block)
- `app/test/features/privacy_consent/privacy_consent_view_contract_test.dart`
  (import, five call sites; refreshed the stale fonts header note)
- `app/test/features/privacy_consent/privacy_consent_copy_test.dart`
  (import, one call site)
- `app/test/features/privacy_consent/p04_bugs_test.dart`
  (import, one call site)

The last two sit outside a strict `view`/`widget` filename reading, but both
are view-pumping tests the FONTS rule assigns to "your feature's tests", the
logic builder's brief owns only `bloc`/`repository`/`data`-named files, and
leaving them would keep the suite unbuildable for everyone. No test logic,
assertions, or copy changed — deletions only.

No view/layout changes were needed: `privacy_consent_view.dart` already
implements the plan, both designs, and every owner rule (copy verified
character-by-character against `design/html-source/screens/P04-privacy.html`
— curly ’, em dashes, shield alt text; tokens only; no Pip slot; CTA surface
to the physical edge).

## Logic-builder contract check

Re-read `docs/screens/P04/2a_build_logic.md` before finishing: **CONTRACT
CHANGES: none** — event/state/repository names stable; nothing for the UI
layer to adapt. (The pre-existing optimistic-emit toggle noted there is the
P04-5/P04-8 fix the view already codes against.)

## Verification (feature scope only — no whole-app run, no simulator)

```
dart format --set-exit-if-changed lib/features/privacy_consent \
  test/features/privacy_consent        → 19 files, 0 changed
flutter analyze lib/features/privacy_consent \
  test/features/privacy_consent        → No issues found!  (was 16 errors)
flutter test test/features/privacy_consent/privacy_consent_view_test.dart \
             test/features/privacy_consent/privacy_consent_view_contract_test.dart \
             test/features/privacy_consent/privacy_consent_copy_test.dart \
             test/features/privacy_consent/p04_bugs_test.dart
  → 00:03 +87: All tests passed!   (87 passed, 0 skipped, 0 failed)
```

The 87 include the un-skipped `[P04-2]` and `[P04-7]` bug proofs, both green
against the current view.

## LEFT FOR NEXT ITERATION

Nothing in the UI layer. The integrator owns the whole-app `flutter test` +
simulator re-shoot/compare this iteration.

VERDICT: PASS
