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

VERDICT: FAIL
