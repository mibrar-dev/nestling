# Fix list after iteration 3

## From 3_test.md
# P07 Paywall — test report (Stage 3, iteration 3)

## Summary

The iteration-3 build fixed P07-BUG-10 (the close trap), P07-BUG-11 (announced
`·` separators), P07-BUG-12 (a trial tap downgrading an active subscriber) and
the stacked legal row, and it un-skipped their proofs. **This stage's suite is
green**: `flutter test` reports `+770 ~3`, `dart format` is clean and the
analyzer is clean for every committed file.

Six tests were added this iteration for the behaviour the build introduced.
None of them found a new defect — but one **major bug is open in the screen**:
Stage 6's hunt filed P07-BUG-13 (the legal-link labels are top-aligned instead
of vertically centred, so the links no longer share the separators' baseline).
I reproduced and confirmed it below. Per the stage brief the screen is **not**
patched here, and `VERDICT: PASS` requires no bugs found, so this iteration is a
FAIL with a green suite — same shape as iteration 2.

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 370 files, 0 changed |
| `flutter analyze` (`paywall_view_test.dart`, `paywall_bloc_test.dart`) | **No issues found!** |
| `flutter analyze` (whole app) | 3 infos, all in `probe_iter3.dart` — see Notes |
| `flutter test test/features/paywall/paywall_bloc_test.dart` | **+30** all passed |
| `flutter test test/features/paywall/paywall_view_test.dart` | **+59** all passed |
| `flutter test test/features/paywall/p07_bugs_test.dart` (stage 6) | **+17 ~3** all passed |
| `flutter test test/features/paywall/` | **+106 ~3: All tests passed!** |
| `flutter test` (whole app) | **+770 ~3: All tests passed!** |

The 3 skips are recorded defects with proof tests (`6_bugs.md` convention:
skipped while the defect is open, un-skipped when fixed): `[P07-BUG-8]` and
`[P07-BUG-9]` (shared code — `SHARED_REQUEST.md`) and `[P07-BUG-13]`.

## Tests added this iteration (6)

All in `paywall_view_test.dart` and `paywall_bloc_test.dart`; no screen code
touched. The build stage had already added the event-level BUG-12 guard tests
and a legal-row geometry test; those were verified green, not rewritten.

| Test | What it pins |
|---|---|
| `the nav keeps its balance spacer while the trial is live` | with a live trial the nav holds **two** 44-wide boxes — the close tile and the balance spacer that mirrors it — so the bar stays visually centred |
| `an expired trial drops the close tile and its spacer` | P07-BUG-10's fix removes **both**: zero 44-wide boxes in the nav, so no dangling 44px of nothing behind the omitted control (ALIGNMENT owner rule). Also asserts the bottom bar and both working exits are untouched, and nothing was written |
| `Start free trial on a paying family never downgrades them to trial` | P07-BUG-12 end to end through the **real** Drift `readSubscription()`: `Seed.demo` is `active`; after tapping the CTA the status is still `active`, `trial_start` has not moved, `onboarding_complete` is true, and the family lands on `/today`. The `before` assertion proves the setup is genuinely active, so the assertion is not vacuous |
| `the legal separators are decoration, not links` | P07-BUG-11: `·` is painted twice (`find.text` → 2) but announced **zero** times, while all three links are still labelled — the first half is not vacuously true |
| `readSubscription is a one-shot read that never waits on a stream` | the mechanism BUG-12's guard depends on: the read completes inside a 1s budget (the interface default is `watchSubscription().first`, which stays pending inside a widget test — a regression fails on the budget instead of hanging), and the next read sees a write immediately. Complements the build's per-seed status test instead of duplicating it |
| (support) `_expireSubscription(db)` + `_navSpacers(tester)` helpers | write `subscription_status = 'expired'` and re-read the session — the only input the `trialExpired` guard reacts to (P07-BUG-8: nothing in the app writes it yet) — and a finder for 44-wide boxes inside the nav subtree |

Coverage note from writing them: the existing `parent tap targets are at least
44dp` test measures the **semantics node**, which the `ConstrainedBox` keeps at
44 even while the label inside it is mispositioned. That is exactly why BUG-13
slipped past the tap-target contract — target size and label geometry are two
different assertions.

## Bugs found

### P07-BUG-13 — major (confirmed, open) — legal-link labels are top-aligned, not centred

Found by Stage 6's hunt in iteration 3 and **confirmed by me** with the same
proof; recorded, not patched (stage 3 may not edit the screen).

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:818-829`
— `_LegalLink`'s `Padding(horizontal: 6)` → `ExcludeSemantics` → `Text`. The
iteration-3 fix for the stacked legal row removed the expanding `Center` that
used to sit between the `InkWell` and the text, and with it went the vertical
centring. The design
(`design/html-source/screens/P07-paywall.html`, `.legal-row .link`) is
`display: inline-flex; align-items: center; justify-content: center;
min-height: 44px` — the label is centred in its 44px target.

**Repro:**
```
cd app
flutter test test/features/paywall/p07_bugs_test.dart \
  --run-skipped --plain-name 'P07-BUG-13'
```
→ `Expected: 757.25 (±1.0) / Actual: 744.25` — the label sits 13px above where
the design puts it (design label box 767–780, app 754–766), so the three
underlined links and the two `·` separators do not share a baseline.

**Rule impact:** the owner's ALIGNMENT rule ("nothing a few px off") — 13px is
far more than a few, and the row is the last thing on the screen.

**Suggested fix (build stage):** centre the label inside the target without
letting it expand the `Wrap` run — `Align(alignment: Alignment.center)` (not
`Center`) or `Padding` with symmetric vertical insets inside the existing
`ConstrainedBox`, keeping `softWrap: false` so the link still sizes to its text.
Then un-skip `[P07-BUG-13]`.

## Verified clean this iteration

- Everything iteration 2 proved still holds: the design surface and its copy
  character-by-character, `PipAvatar(mochi, sunny, stage 4, inNest)` on the
  120px slot, light + dark × 320/390/430 × text scale 1.0/1.3 with no overflow,
  20px gutters, the bottom edge reaching the physical edge in both themes
  (painted-pixel proof, including a 34px home-indicator inset), every tap
  navigating to the right route (`/pocket-money-setup`, `/today`), the
  ORCHESTRATOR_NOTES 1 handoff on both paths, `initial`/`loading`/`loaded`/
  `failure` + Retry, an empty plan list that is never an empty state, and an
  identical screen under `Seed.demo`/`empty`/`fresh` with no seeded child names.
- The action paths: failure toasts in place and retries, `working` disables the
  CTA and the restore link, a second tap never starts a second trial, and a
  restore never shows the trial spinner.
- `google_fonts` / `GoogleFonts.*` appear nowhere in this feature's `lib/` or
  `test/` (the FONTS rule).

## Notes

1. **Open shared findings.** `[P07-BUG-8]` (the trial never expires) and
   `[P07-BUG-9]` (kid-mode guard order) live in `core/` and `app/` — outside
   RULES §1, filed in `docs/screens/P07/SHARED_REQUEST.md`. P07-BUG-10's fix is
   the screen half of that pair, so it is ready for the day they land.
2. **Concurrent stages in this worktree.** Stage 6 (bugs) is running
   concurrently: `app/test/features/paywall/probe_iter3.dart` is its temporary
   scratch file (its own header says it is deleted before that report lands; it
   has no `_test` suffix so `flutter test` never collects it, but it accounts
   for all 3 `flutter analyze` infos), and `p07_bugs_test.dart` is being edited
   mid-run — an unused-import info there appeared and cleared during this
   stage. Neither is a P07 defect and neither was touched here.

## Verdict basis

All tests pass (`+770 ~3`), formatting is clean and the committed test files
analyze clean, but a major defect is open in the screen — P07-BUG-13, a 13px
vertical misalignment of every legal link, confirmed here with a repro. Stage 3
may only pass when no bugs are found, so the build stage should centre the
legal-link labels and un-skip `[P07-BUG-13]`.


## From 5_ui.md
# P07 Paywall — UI check (Stage 5, iteration 3)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_3.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame, EXIT 0
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_3.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya` → stable frame, EXIT 0
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_3.png docs/screens/P07/ui/cmp_light_3.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_3.png docs/screens/P07/ui/cmp_dark_3.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `1_plan.md`, SPACING_SPEC §§1–2/8, `ORCHESTRATOR_NOTES.md`. Pixels are logical (÷3). Status-bar text ignored per rule.

## Mean diff

- Light: **5.48%** (was 11.43% at iteration 2; bands: 0 0–105: 1.60% · 1 105–211: 3.52% · 2 211–316: 7.72% · 3 316–422: 7.37% · 4 422–527: 5.74% · 5 527–633: 10.06% · 6 633–738: 2.49% · 7 738–844: 5.32%)
- Dark: **5.28%** (was 9.78%; bands: 0: 1.57% · 1: 2.47% · 2: 7.82% · 3: 7.65% · 4: 5.84% · 5: 9.32% · 6: 2.45% · 7: 5.12%)
- Iteration 2's blockers are fixed: the legal row is horizontal and the CTA is compact — band 6 fell 28.69% → 2.49%, and the CTA button sits at y 646–698 vs design 646–697 (pixel-perfect). Remaining drift is band 5 (plan card shift), band 2 (title wrap, unchanged) and band 7 (separator offset).

## Deviations (design value → app value + fix)

1. **Major — benefit row 4 wraps to 2 lines, pushing the plan card 24 px down so its tag line is clipped by the CTA.** Design: `Co-parent sharing, so James sees the same` on one line (ink spans x 55–365 = 310 px in a 315 px slot: gutter 20 + tick 24 + gap 10, 5 px to spare); plan-card leaf borders at y 521–522 / 625–626, fully above the CTA panel (top ≈630). App: the same string wraps after `the` (`…sees the` ends at x 332; per-char width matches the design to ~1%, but the bundled Inter measures ~1–2% wider overall, so the 310 px line no longer fits the 315 px slot); plan top border lands at y 545–547 (+24 = exactly one wrapped line) and the card bottom (~649) slides ~19 px under the CTA panel — the tag `One price, the whole family` is half-covered at top-of-scroll. All layout inputs match the spec (gutter 20, tick 24, gap 10, Inter 15/24 explicit per plan §a), so this is font-metrics fidelity, not a layout bug; no token-compliant nudge exists (sizes/copy must not change). Fix: accept as engine-level rendering, or address at the design-system level (e.g. verified Inter metrics/tracking); do NOT shrink text or edit copy — both would break tokens/tests. The clipped tag keeps this a FAIL until resolved.
2. **Major — legal `·` separators sit ~10 px below the link baseline.** Design: links and separators share one baseline (link band y 767–779, seps y 771–772). App: links on one band (y 754–763, horizontal ✓) but both separators render at y 764–772, visibly dropped below the text (see compare crop). Cause: the 44 px-tall `_LegalLink` boxes vs the 18 px sep `Text` share one `Wrap` run — the link glyphs render top-weighted in their min-height boxes while the short sep line boxes settle lower in the run, so `WrapCrossAlignment.center` never brings the dot onto the link baseline. Fix: give the separators the identical 44 px box as the links (e.g. wrap each sep in `SizedBox(height: tapParent, child: Center(child: Text('·', …)))` and ensure link content is likewise centered, so both glyph families — same 13/18 metrics — centre identically). Keep the `Wrap` fallback for 320 dp / 1.3× overflow.
3. **Minor (unchanged) — title wraps with orphan “days”.** Design (`text-wrap: balance`): `Try Nestling` / `free for 14 days`. App: `Try Nestling free for 14` / `days`. Identical 2-line block height, no layout shift. Fix is constrained: copy tests require the exact single string, so no hard break may be inserted; accept or add balance support in the design system.

## Verified matches (no action)

- Nav/close (44×44 surface-2 r12), hero geometry (circle/nest/Pip slot/coins align; hero ink rows identical to design), title block position, benefits 1–3 (row 3 text at y 448 vs 447), plan-card geometry (borders, 2 px leaf ring, radio, radius, shadow), plan copy incl. em dash, CTA button (52 px, y 646–698) + caption (with `the`) + horizontal legal links, 20 px gutters throughout.
- **BOTTOM EDGE: PASS** — last row is CTA surface both themes (light 255,255,255; dark 31,28,46 = `#1F1C2E`); no paper/meadow strip. The design PNGs' own paper strip is correctly not reproduced (owner rule overrides).
- **COPY: PASS** — curly ’, em dashes, `·` separators, `£` all exact vs HTML. **DARK: PASS** — no theme-specific deviation. **FONTS: PASS** — no `google_fonts`/`GoogleFonts` in view or feature tests. **PIP:** `PipAvatar(mochi, stage 4, inNest)` vs PNG's v1 SVG is the mandated override, not a finding.

## Verdict basis

Iteration 3 fixed the vertical legal stack and the oversized CTA, halving the diff. What a designer would still reject: the wrapped 4th benefit with the plan-card tag sliding under the CTA, and the dropped `·` separators. Both are visible in light and dark at top-of-scroll.


## From 6_bugs.md
# P07 Paywall — bug hunt (Stage 6, iteration 3)

Adversarial pass over the iteration-3 P07 build: `app/lib/features/paywall/**`
(view, action bloc with the new active-subscription guard, Drift repository
with `readSubscription()`, route), the router guard and session handoff, and
the design sources (`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`, `docs/screens/P07/1_plan.md`,
`SHARED_REQUEST.md`).

**Headline: iteration-1/2 bugs 1–12 are all fixed with green proofs.** The
iteration-3 hunt found **one new major bug — P07-BUG-13**: the legal-link
labels are top-aligned inside their 44 px targets, so they sit ~13 px above
the design and above the centred `·` separators (a visible misalignment the
ALIGNMENT owner rule says to fail). The two shared items (P07-BUG-8 major,
P07-BUG-9 minor) remain open and filed. Because P07-BUG-13 is major, this
iteration cannot pass.

Proof file: `app/test/features/paywall/p07_bugs_test.dart` — 17 tests
unskipped and green (bugs 1–7, 10–12 + 4 verified-clean baselines), 3 skipped
(BUG-8/9 shared, BUG-13 open). `--run-skipped` fails each skipped proof for
the documented reason.

## Ledger

| ID | Finding | Iteration-3 outcome |
|---|---|---|
| P07-BUG-1 | blocker: screen not implemented | **fixed** (iter 2); proof green |
| P07-BUG-2 | blocker: no trial/restore path, onboarding dead end | **fixed** (iter 2); proofs green |
| P07-BUG-3 | major: bar could not render CTA → caption → legal row | **fixed** (iter 2); proof green |
| P07-BUG-4 | minor: caption dropped “the” | **fixed** (iter 2); proof green |
| P07-BUG-5 | minor: stray full stop, tag missing from data | **fixed** (iter 2); proofs green |
| P07-BUG-6 | minor: stale `errorMessage` survived a retry | **fixed** (iter 2); proof green |
| P07-BUG-7 | minor (latent): UPDATE-only writes | **fixed** (iter 2); proof green |
| P07-BUG-8 | major (shared): the 14-day trial never expires | **open** — `SHARED_REQUEST.md` §1; proof skipped |
| P07-BUG-9 | minor (shared): kid-mode guard order during onboarding | **open** — `SHARED_REQUEST.md` §2; proof skipped |
| P07-BUG-10 | major (latent): X could not leave the expired-trial paywall | **fixed** (iter 3) — close tile omitted on the expired gate; proof green |
| P07-BUG-11 | minor: `·` separators announced in semantics | **fixed** (iter 3) — `ExcludeSemantics`; proof green |
| P07-BUG-12 | minor: trial CTA downgraded an active subscriber | **fixed** (iter 3) — bloc one-shot active guard, fail-open; proof green |
| P07-BUG-13 | **major: legal-link labels top-aligned, not centred** | **open** — this iteration; proof skipped |

Evidence: `flutter test test/features/paywall/p07_bugs_test.dart` → `+17 ~3`;
all ten earlier proofs unskipped and passing.

## Iteration-3 finding

### P07-BUG-13 — Major (ALIGNMENT owner rule) — the legal-link labels are top-aligned

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:795-836`
(`_LegalLink`). The iteration-3 fix for the stacked legal row removed the
expanding `Center` from the link subtree but did not replace the vertical
centring: `ConstrainedBox(minWidth/minHeight 44)` forces the label
`RenderParagraph` to 44 px tall, and a paragraph paints its text at the top of
its box. The `Wrap` then centres the 44 px link boxes against the 18 px `·`
separators, so the labels sit at the top while the dots sit in the middle.

**Evidence (measured):**

- Widget probe: `Terms` paragraph box `66.3×44`, intrinsic text height 18,
  alphabetic baseline 12.25 px from the box top; `·` paragraph `13.3×18`,
  baseline 12.25. Link baseline y = 744.25, dot baseline y = 757.25 → **13 px
  apart**.
- Device shot `docs/screens/P07/ui/app_light_3.png` vs
  `design/screens/light/P07-paywall.png` (sky-pixel scan, logical px): app
  link band **754.3–766.3**, design **767.3–779.7** — the labels render 13 px
  above the design, with the dots hanging low; the design centres both
  (`.legal-row .link { align-items: center; min-height: 44px }`).
- Visible in both themes; a designer comparing the two PNGs would reject the
  row (ALIGNMENT owner rule: “Treat visible misalignment as a UI failure”).

**Repro:** `cd app && flutter test
test/features/paywall/p07_bugs_test.dart --run-skipped --plain-name
'[P07-BUG-13]'` → `Expected: 757.25 (±1.0) / Actual: 744.25`.

**Failing test:** `[P07-BUG-13] the legal links share the separators’ baseline`
(`skip: true`).

**Suggested fix:** keep the 44×44 tap target and the non-expanding width but
centre the label vertically, e.g. inside the `InkWell` use
`Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment:
CrossAxisAlignment.center, children: [Text(label, …)])`, or give the label
`Padding(vertical: (44 − 18) / 2)`. A bare `Center()` expands to the Wrap run
(the original regression) and `Center(widthFactor: 1)` collapses to the child,
so neither works. After the fix, unskip the proof.

## Carried open items (shared, filed — not fixable under RULES §1)

1. **P07-BUG-8 — major (shared):** the 14-day trial never expires; nothing in
   `app/lib` writes `subscription_status = 'expired'`, so the router’s
   `trialExpired → /paywall` redirect is dead code. Filed in
   `SHARED_REQUEST.md` §1 (owner: `core/data/app_session.dart` +
   `app/launch.dart`). Proof `[P07-BUG-8]` stays `skip: true`. The P07 side of
   the pair is now ready: P07-BUG-10 fixed the expired-gate close behaviour,
   so landing expiry will not trap the parent.
2. **P07-BUG-9 — minor (shared):** kid-mode + onboarding-incomplete deep link
   to `/paywall` ends on `/welcome` instead of `/parental-gate` (guard
   ordering in `app/lib/app/router.dart`). Filed in `SHARED_REQUEST.md` §2.
   Proof `[P07-BUG-9]` stays `skip: true`.

## Verified clean this iteration

- **Iteration-3 fixes audited in code and by test:** the expired gate renders
  no close control and stays on `/paywall` with the CTA (probe: nav 52 px,
  `close=0`, no exception; the normal screen still has the 44 px close tile
  and its balance spacer); the separators are out of semantics (proof green);
  the bloc’s `_alreadySubscribed()` reads once, fails open to the legacy trial
  path on read errors, keeps the `working` double-tap guard, and emits
  `success(request: restore)` for an active family (proof green).
- **All 1–12 proofs green**, including the trial/restore handoff, close
  navigation, bar order, copy pins and the upsert path.
- **Standard hunt list re-checked on the changed build:** rapid double taps
  (trial/restore/close), close during an in-flight request, deep links and
  back navigation, kid-mode guard (onboarded → `/parental-gate`), restart
  persistence, dark-mode contrast (tokens unchanged; all P07 pairs ≥ 5:1),
  320 dp × 1.3 text scale (no overflow/exception), async/dispose (bloc 9
  cancels emitters; no emit-after-close throw). Money rounding and child-data
  edge cases remain N/A (no arithmetic, no child data on P07).
- **FONTS:** no `google_fonts`/`GoogleFonts` anywhere in the feature or its
  tests (grep clean).
- One full-suite run hit a transient native-asset race (`libsqlite3.dylib`
  missing while a concurrent stage built in the same worktree); the re-run is
  green. Environment, not a product finding.

## Verification (run this stage, `app/`)

- `flutter test test/features/paywall/p07_bugs_test.dart` → **+17 ~3**.
- `flutter test test/features/paywall/` → **+106 ~3**.
- Full `flutter test` → **+770 ~3, all pass** (3 skips: BUG-8, BUG-9,
  BUG-13).
- `flutter analyze` → `No issues found!`; `dart format` → 369 files, 0
  changed.
- The new proof fails exactly as documented with `--run-skipped`; the scratch
  probe used for the hunt was deleted.
- No screen code touched; only `app/test/features/paywall/p07_bugs_test.dart`
  and this file.

## Verdict basis

Iteration-1/2 bugs 1–12 are fixed with green proofs, and the three
iteration-3 fixes are correct in code and test. But P07-BUG-13 is a real,
measured, visible misalignment: the legal-link labels render 13 px above the
design and above the centred separators, which the ALIGNMENT owner rule
classifies as a UI failure. Per the stage rule — PASS only if no major bugs —
this iteration fails; the next build should centre the labels (small,
screen-local) and unskip the proof.

