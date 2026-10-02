# P04 · Privacy consent — test notes (STAGE 3, iteration 3)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 3), `4_review.md`,
`5_ui.md`, `6_bugs.md`, `FIXES_2.md`, `SHARED_REQUEST.md` and the mandatory
`ORCHESTRATOR_NOTES.md` (including the 13:42 UPDATE: the shared batch with
`ic_trash.svg`, the themed shield and the first-run settings row is **not** in
this worktree yet).

## Test inventory — 108 P04 tests (105 run, 3 skipped shared-blocked proofs)

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 11 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 30 | states through the real router, every tap destination, optimistic switch, failure captions, row glyphs, nav geometry, dialog stress, short screens, row geometry |
| `privacy_consent_copy_test.dart` | 5 **(new)** | copy fidelity against the HTML design source (orchestrator COPY rule) |
| `p04_bugs_test.dart` | 15 | adversarial proofs from stages 4/6 (7 fixed & green, 3 shared-blocked & skipped, clean-behaviour guards) |

## Tests added this iteration

### 1. Copy fidelity against the design source (orchestrator COPY rule)

New file `privacy_consent_copy_test.dart`. It reads the **real** design source
(`design/html-source/screens/P04-privacy.html`, resolved by walking up from
the package root), decodes its entities (`&rsquo; &mdash; &hellip; &nbsp; …`)
and asserts that every string P04 draws is byte-for-byte the decoded design
text — nothing transcribed by hand, so a design copy edit fails the test
instead of drifting:

- `every string drawn on screen matches the HTML source` — h1, standfirst,
  the 4 list titles + 4 subs, opt title/sub, `Continue`, the footnote, and the
  three `aria-label`s (shield alt, toggle, `Back`). Captures are guarded
  against being empty or leaking markup, so the test cannot pass vacuously.
- `the design typography characters survive into the app` — pins the code
  points: U+2019 in `Your family’s privacy`, U+2014 in `Exactly what we store —
  and nothing else.` and `No ads or tracking — ever`, and no straight quote,
  ASCII hyphen, left double quote or soft hyphen anywhere in the rendered copy.
- `a non-breaking space in the design would survive the copy` — the decoder
  preserves U+00A0, so if the design ever wraps a phrase in `&nbsp;` the rule
  bites instead of being silently dropped.
- Two widget tests pin the screen-owned failure captions (product copy from
  plan §d, not in the HTML): the OFF wording uses U+2019/U+2014 and no ASCII
  hyphen, and the ON wording (failed OFF write, opt-in still stored) renders
  while the OFF wording does not.

**Teeth check:** temporarily corrupting the decoder (U+2019 → ASCII `'`) made
the file fail with `Expected: 'Your family’s privacy' / Actual: "Your family's
privacy"`, then it was reverted. The test is not passing by construction.

### 2. BLoC — the P04-8 revert contract

`a failed write reverts to the stored value, not an optimistic one`: two
toggles, **both** writes failing, stored consent ON → the bloc must come back
ON (and keep the items mirror untouched). The old behaviour reverted to the
last optimistic value and left the switch OFF, i.e. it would have told the
parent their opt-out was saved when nothing was written. `[P04-8]` in
`p04_bugs_test.dart` covers the same path through the view; this pins the bloc
contract directly.

### 3. Widget — the shared null-title nav path the build now relies on

`the compact nav has no title and keeps the 60px design bar`: asserts
`NestNavBar.title == null` (the local `title: ''` workaround was removed this
iteration), the bar is exactly 60 px (`.nav-bar.compact` = min 52 + padding
4/12/12 around the 44 px button), **no empty `Text` node** is left in the bar
(nothing for screen readers to announce), and `Back` is still there.

### 4. Re-verified (no change needed)

- Bloc: loading→loaded, empty stream, stream error, items without a `crash`
  row, `CrashToggled` on/off, both write-failure directions, optimistic emit,
  no optimistic revert, error cleared by the next emission, Drift ON→OFF.
- Repository: default OFF (ICO), 5 rows, crash row mirrors the setting, other
  columns untouched, first-run upsert creates exactly one row / reuses it /
  idempotent / race-safe, `Seed.empty` and `Seed.demo`.
- Widget: light + dark, 320/390/430 at text scale 1.0 and 1.3, 320×568 short
  screen, empty/loading/error/first-run states through the real router, every
  tap destination (back with and without history → `/create-account`,
  `Continue` → `/add-children` in loaded/loading/failure, toggle stays on
  `/privacy`, dialog opened and dismissed by `Close` and barrier), semantics
  on the icon buttons (`Back`, notice link, shield, toggle) with ≥ 44 px
  targets, 20 px gutters at three widths, bottom-CTA surface to the physical
  edge in both themes.
- Row glyphs: rows 1-3 assert asset path, 24 px size, tile ink, real
  `SvgAssetLoader` and non-null `ColorFilter` in light and dark; row 4 stays
  the documented gap.

## Results

```
dart format --output=none --set-exit-if-changed .  → 358 files, 0 changed
flutter analyze                                    → No issues found! (ran in 3.1s)
flutter test test/features/privacy_consent/        → 00:02 +105 ~3: All tests passed!
flutter test (whole app)                           → 00:11 +592 ~3: All tests passed!
```

Zero failures. The 3 skips are the shared-blocked proofs; run deliberately,
they fail exactly as documented and nothing else:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 00:02 +12 -3   (P04-2, P04-4, P04-7)
```

## Bugs found this iteration

**None.** No new defect surfaced in the iteration-3 tree.

## Remaining defects — outside RULES §1, tracked, still open

| Id | Severity | Defect | Blocker |
|---|---|---|---|
| P04-2 | major | Promise row 4 renders an **empty** peach tile; the design draws a trash glyph. | Needs `app/assets/icons/ic_trash.svg` + `NestIcons.trash` (shared batch, not yet in this worktree — `ORCHESTRATOR_NOTES.md` 13:42 UPDATE). RULES §1 keeps `app/assets/**` and `core/**` off limits. `SHARED_REQUEST.md` §1. Proof `[P04-2]` skipped; the flip instructions (`leadingAsset: NestIcons.trash`, un-skip, `findsNWidgets(4)`) are encoded in the proof and the row-glyph test. |
| P04-4 | major | `NestList`'s real 1 px `Divider`s make the promise list 3 px taller than the design's overlay separators. | Shared `NestList` owns the divider height; rebuilding it locally would re-implement a design-system component. `SHARED_REQUEST.md` §6. Proof `[P04-4]` skipped. |
| P04-7 | minor | `privacy_shield.svg` bakes the light sky tint + white body, so dark mode renders the light artwork. | Shared asset (themed shield in the same shared batch). `SHARED_REQUEST.md` §2. Proof `[P04-7]` skipped. |

Orchestrator notes: item 1 is covered by tests as far as RULES §1 allows; item 2
is verified pixel-exact (`[P04-3]` green: chevron centre 73, h1 top 107); item 3
is measured and formally filed (P04-4 above); item 4 owner rules are asserted
in both themes. Owner rules re-checked this iteration: 20 px gutters, CTA
surface to the physical edge, no coloured strip, no misalignment.

## Notes (not defects)

- Test harness: widget tests run without the bundled Inter/Nunito faces, so the
  block test font widens every line and pushes the opt card below the fold
  although it fits on a 390×844 device; helpers scroll with `ensureVisible`
  before tapping the toggle. Drift reads inside `testWidgets` need
  `tester.runAsync`, and a `Future.delayed` must never outlive the test.
- `privacy_consent_copy_test.dart` fails loudly if the design source cannot be
  found (it lists the searched paths) rather than silently passing — if the
  app is ever tested outside the repo, fix the checkout, do not skip the file.

VERDICT: PASS
