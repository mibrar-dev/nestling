# P04 · Privacy consent — build notes (STAGE 2 INTEGRATE, iteration 7)

Feature `privacy_consent` · route `/privacy` · parent mode.
Two builders worked in parallel on this iteration: `2a_build_logic.md` (domain,
data, bloc, DI/routes + bloc/repository tests) and `2b_build_ui.md` (views +
view/widget tests). This file is the integration pass — its only job was to
make the combined result compile and pass.

## Verdict up front: nothing to integrate

Both halves landed **no production changes**. `git diff` over
`app/lib/features/privacy_consent/**` is empty — the whole feature (domain,
data, bloc, views) is exactly the tree that iteration 6 verified and that
iterations 5–6 gated green. So there was no seam to repair:

- **No contract seam.** 2a reports `CONTRACT CHANGES: none`; the public names
  (`PrivacyConsentLoadRequested`, `PrivacyConsentCrashToggled(value)`,
  `PrivacyConsentState(status/items/crashConsent/errorMessage)`,
  `PrivacyConsentRepository`, `registerPrivacyConsent`,
  `PrivacyConsentRoutePaths.privacy`) are unchanged, so the view coded by 2b
  and the bloc coded by 2a type-check against each other as-is.
- **No import/member seam.** The only breakage introduced by the `1b2109e`
  main merge (`google_fonts` removed, Inter/Nunito bundled) lived in the test
  layer; 2b removed the `google_fonts` import and every
  `GoogleFonts.config.allowRuntimeFetching = false` call from the four
  affected P04 test files, exactly as the FONTS orchestrator rule prescribes.
  I verified the removal is complete app-wide, not just in P04:
  `grep -rln "google_fonts\|GoogleFonts" app/lib app/test` → no matches.
- **No failing test.** No mismatched BLoC states/events, no renamed members,
  no test that the merge of the halves turned red. I made **no code change at
  all** this stage — the smallest possible change set, verified rather than
  rewritten.

The only overlapping edit surface between the two builders was
`p04_bugs_test.dart` (2a flagged it as outside its file-name scope and left
it; 2b removed the `google_fonts` import from it). That file is view-pumping
and imports the view, so 2b's call was the right one and it is the only place
the halves touched the same file — with no conflicting hunks.

## Summary of 2a (logic)

No files changed. Verified in place and green: transactional upsert
(`data/privacy_consent_repository_impl.dart`), optimistic toggle +
state-aware failure + revert-to-stored (`presentation/bloc/privacy_consent_bloc.dart`),
and the stable DI/route contract. 2a's own check: `flutter analyze
lib/features/privacy_consent` → No issues found; bloc + repository tests → 33
passed.

## Summary of 2b (UI)

The real work of the iteration: the `1b2109e` merge left **16 compile errors**
across 4 P04 test files (unresolvable `package:google_fonts/google_fonts.dart`
imports), i.e. the feature suite did not build. 2b deleted the import and the
`GoogleFonts.config` calls from `privacy_consent_view_test.dart`,
`privacy_consent_view_contract_test.dart`, `privacy_consent_copy_test.dart` and
`p04_bugs_test.dart` — deletions only, no test logic, assertion or copy
changed. No view/layout change was needed: `privacy_consent_view.dart`
already implements `1_plan.md`, both designs and every owner rule. 2b's own
check: `flutter analyze` over the feature → No issues found; the 4 rebuilt test
files → `00:03 +87: All tests passed!`.

## FIXES_6 items — all done, none left

`FIXES_6.md` embeds the stage-6 bug hunt written against the **iteration-4**
tree; every item it lists had already landed in iterations 5–6. Re-verified
line by line on the integrated tree:

| Id | Item | State | Evidence on this tree |
|---|---|---|---|
| P04-1 | first-run opt-in silently dropped | **DONE** (it. 2) | transactional upsert; `[P04-1]` green |
| P04-2 | row 4 empty peach tile | **DONE** (it. 5) | `privacy_consent_view.dart` row 4 `leadingAsset: NestIcons.trash`; no `TODO(P04)` anywhere; contract test asserts the asset + `aPeach` ink; `[P04-2]` green |
| P04-3 | compact nav 16 px short | **DONE** (shared merge, it. 2) | `[P04-3]` green (60 px bar) |
| P04-4 | dividers inflated the list by 3 px | **DONE** (it. 4 + shared `NestList`) | four direct `NestList` children; `[P04-4]` green |
| P04-5 | double-tap wrote the same value twice | **DONE** (it. 2) | optimistic emit; `[P04-5]` green |
| P04-6 | failed OFF claimed "it stays off" | **DONE** (it. 2) | state-aware caption; `[P04-6]` green |
| P04-7 | dark mode rendered the light-baked shield | **DONE** (it. 5) | `NestPrivacyShield(semanticLabel: …)`; no `flutter_svg`/baked asset left in the view; `[P04-7]` green |
| P04-8 | failed toggle reverted to an unpersisted value | **DONE** (it. 3) | revert to `_crashFrom(items)`; `[P04-8]` green |
| P04-9 | overlapping first-run writes kept the earlier value | **DONE** (it. 4) | single transaction; `[P04-9]` green |
| review finding 3 | delete the local divider `showDivider`/`Stack` | **DONE** (it. 5) | not present in the view; shared `NestList` owns the overlay |
| review finding 4 | `dividerOf(0)` result check instead of `byType(Stack)` | **DONE** (it. 5) | present at both sites; remaining `byType(Stack)` uses measure the shared overlay's geometry |
| review finding 5 | quote the real test tail | **DONE** (it. 6) | quoted verbatim below |

**Left for later iterations:** nothing in P04 scope. Zero bug proofs remain
skipped (`grep "skip: true"` over the P04 tests → no matches), so
`--run-skipped` is now a no-op and nothing can hide behind a skip.

ORCHESTRATOR_NOTES items 1–4 remain met (four tinted row glyphs in both
themes; header offsets Δ0; row heights/dividers Δ0; bottom-edge CTA surface
plus 20 px gutters). COPY still locked against
`design/html-source/screens/P04-privacy.html`; CHILD ORDER N/A; PIP N/A.

## Gates (app/, integrator run)

```
dart format .
→ Formatted 372 files (0 changed) in 1.38 seconds.

flutter analyze
→ Analyzing app...
→ No issues found! (ran in 4.4s)

flutter test test/features/privacy_consent
→ 00:05 +156: All tests passed!        (156 passed, 0 skipped, 0 failed)

flutter test                            (whole app)
→ 00:16 +806: All tests passed!        (806 passed, 0 skipped, 0 failed)
```

`All tests passed!` (not `All other tests passed!`) is itself the proof that
**zero tests are skipped** app-wide.

Bug-proof proof, run explicitly (`p04_bugs_test.dart`, expanded reporter) —
all nine adversarial proofs green:

```
[P04-1] first run: the toggle tap is actually stored
[P04-2] every promise row renders its leading glyph
[P04-3] header block matches the 60px design bar
[P04-4] dividers do not add height to the promise list
[P04-5] double-tapping the switch toggles twice
[P04-6] a failed OFF write never claims "it stays off"
[P04-7] dark mode renders the themed shield, not the baked asset
[P04-8] a double-failed rapid toggle reverts to the stored value
[P04-9] overlapping first-run writes keep the last value
→ 00:02 +16: All tests passed!
```

## Files changed by the integrator

None (code). `docs/screens/P04/2_build.md` (this file) is the only write, per
the stage brief.

## Hand-off note for STAGE 5 (UI)

No simulator shot was taken this stage. Two reasons: the integrator brief
scopes the job to compile + pass, and `git diff` shows **zero** production
pixel-affecting changes, so the tree renders identically to the iteration-6
shot. Caveat worth carrying forward: `ui/app_{light,dark}_6.png` predates the
`1b2109e` main merge, which bundled the real Inter/Nunito builds (the
`google_fonts` removal), so **STAGE 5 must re-shoot and re-measure** rather
than reuse the iteration-4/6 diff numbers.

VERDICT: PASS