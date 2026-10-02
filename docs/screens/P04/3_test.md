# P04 · Privacy consent — test notes (STAGE 3, iteration 2)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 2), `5_ui.md`,
`6_bugs.md`, `FIXES_1.md`, `SHARED_REQUEST.md` and the mandatory
`ORCHESTRATOR_NOTES.md`.

## Test inventory (98 P04 tests: 95 run + 3 skipped shared-blocked proofs)

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 19 | every event/state path of `PrivacyConsentBloc` (19 after iteration 2) |
| `privacy_consent_repository_test.dart` | 11 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 29 | states through the real router, every tap destination, optimistic switch, failure captions, row glyphs, dialog stress, short screens, promise-row geometry |
| `p04_bugs_test.dart` | 12 | adversarial bug proofs from stage 6 (4 fixed & green, 3 shared-blocked & skipped, 5 clean-behaviour guards) |

## What changed in the tests this iteration

### New bloc coverage (the iteration-2 optimistic emit)

- `a failed first write does not strand the switch after a later success` —
  two toggles with two in-flight writes where the **first** fails: the final
  state must match the last write. It does (the `watchItems` re-emit settles
  it), so this is now a pinned guarantee rather than an open risk.
- `a stream emission after a failure clears the error` — after a failed
  write, the next healthy emission returns `loaded` with `errorMessage ==
  null` (the `copyWith` sentinel + `onData: errorMessage: null`).

### New repository coverage (the P04-1 upsert)

- `the first-run upsert creates one row and reuses it` — ON → OFF → ON on a
  `Seed.fresh` database always leaves exactly one `fam1` settings row.
- `the inserted row takes the settings table defaults` — only
  `crashReportConsent` is written; `kidGateEnabled`/notifications/
  `pocketMoneyMode`/`payoutDay`/`coinValuePencePerCoin` keep the schema
  defaults, never demo-seed values.
- `re-writing the stored value changes nothing` — idempotent write.
- `concurrent first-run writes still leave exactly one row` — three racing
  writes still produce one row (`insertOrIgnore` fallback).

### New widget coverage

- **Optimistic switch (P04-5 contract)**: `the switch answers on the next
  frame, before Drift replies` — with a 400 ms in-flight write, one `pump()`
  after the tap already shows ON, the repository recorded the write and the
  bloc state matches.
- **State-aware caption (P04-6 contract)**: both variants are green —
  a failed OFF write from an ON state says *"Crash reports are still on.
  Continue anyway."* and reverts the switch to ON; a failed ON write from an
  OFF state says *"…Continue anyway; it stays off."* and keeps it OFF.
- **Row glyphs (orchestrator note item 1)**: `rows 1-3 render their own
  tinted glyph; row 4 is the gap` asserts each shipped row's **asset path**,
  24 px size, **tile ink colour**, the real `SvgAssetLoader` and a non-null
  `ColorFilter` — so a wrong-asset or invisible-glyph regression cannot slip
  through. A second test re-runs it in light **and** dark against the dark
  palette. Row 4 is asserted as the known gap, matching the skipped `[P04-2]`
  proof.
- `the failure state keeps Continue and the screen usable` — caption + a
  44 px+ `Continue` that still reaches `/add-children`.

### Un-skipped proof

- `[P04-3]` (compact nav height, orchestrator note item 2) — the shared
  merge `shared/onboarding_header_and_seed` landed `min 52 + padding
  4/12/12` (60 px) and the null/empty-title fix, so the proof is now green:
  back-chevron centre **y 73** and h1 line-box top **y 107**, the design
  values from `design/screens/light/P04-privacy.png` ÷3. Header comment and
  the bug index in `p04_bugs_test.dart` updated.

## Results

```
dart format --output=none --set-exit-if-changed .  → 357 files, 0 changed
flutter analyze                                    → No issues found! (ran in 3.7s)
flutter test test/features/privacy_consent/        → 00:03 +95 ~3: All tests passed!
flutter test (whole app)                           → 00:12 +582 ~3: All tests passed!
```

Zero failures. The 3 skips are the shared-blocked proofs below; running them
deliberately (`--run-skipped`) reproduces their failures exactly:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 00:01 +9 -3   (P04-2, P04-4, P04-7 fail; P04-3 now passes)
```

## Bugs found this iteration

**None.** No new defect was found in the iteration-2 tree. The four bugs the
iteration-1 test stage raised (P04-1) plus the three the bugs stage raised
that are fixable in scope (P04-3, P04-5, P04-6) are now fixed and pinned by
green tests.

## Remaining defects — all outside RULES §1, tracked, not fixable by P04

| Id | Severity | Defect | Evidence / blocker |
|---|---|---|---|
| P04-2 | major | Promise row 4 "Delete everything anytime" renders an **empty** peach tile; the design draws a trash glyph. | Needs `app/assets/icons/ic_trash.svg` + `NestIcons.trash` — both in `core`/assets, which RULES §1 forbids P04 from editing. `SHARED_REQUEST.md` §1 (Blocks: yes). Proof `[P04-2]` skipped; the row-glyph test above pins the three shipped glyphs and documents row 4 as the gap. |
| P04-4 | major | `NestList` renders real 1 px `Divider`s, so the promise list is 3 px taller than the design's overlay separators and everything below drifts. | Divider height is owned by shared `NestList`; re-implementing the list would break the "never re-implement design-system components" rule. `SHARED_REQUEST.md` §6. Proof `[P04-4]` skipped. |
| P04-7 | minor | `privacy_shield.svg` bakes the light sky tint + white body, so dark mode renders the light artwork. | Shared asset. `SHARED_REQUEST.md` §2. Proof `[P04-7]` skipped. |

Orchestrator notes 2 and 3 are now satisfied or formally filed; note 1 is
covered by tests to the limit of RULES §1 (see P04-2 above). Owner rules
re-verified: gutters 20 px and CTA surface to the physical edge in both
themes (asserted), no misalignment, no coloured strip under the bar.

## Notes for the next build stage (not defects)

- `views/privacy_consent_view.dart:38-42` still passes `title: ''` with the
  now-obsolete `TODO(P04)` about the shared null-title crash. The shared
  fix landed, so the workaround and its comment can be dropped (renders
  identically either way; `SHARED_REQUEST.md` item 3 marked RESOLVED).
- Two test-harness gotchas worth remembering: a widget test must never leave
  a `Future.delayed` pending (teardown asserts), and awaiting Drift inside
  `testWidgets` needs `tester.runAsync` — both are already encoded in the
  helpers in `privacy_consent_view_contract_test.dart`.
- Test-font geometry: widget tests run without the bundled Inter/Nunito
  faces, so the block test font makes every line full-em wide and the opt
  card sits below the fold although it fits on a 390×844 device. Helpers
  scroll with `ensureVisible` before tapping the toggle.

VERDICT: PASS
