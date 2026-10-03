# P07 Paywall — bug hunt (Stage 6, iteration 4)

Adversarial pass over the iteration-4 P07 build: `app/lib/features/paywall/**`
(view with the BUG-13 centring fix, action bloc with the active-subscription
guard, Drift repository, route), the router guard and session handoff, the
`NestType` letter-spacing change merged from main (`fd92d95`), and the design
sources (`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`,
`docs/screens/P07/ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`).

**Headline: no bugs found this iteration.** P07-BUG-13 is fixed and verified
(links and separators share one baseline, measured delta 0.0), all thirteen
proofs are unskipped and green, and the two shared items (P07-BUG-8 major,
P07-BUG-9 minor) remain open only because they live outside this feature and
are filed in `docs/screens/P07/SHARED_REQUEST.md`.

Proof file: `app/test/features/paywall/p07_bugs_test.dart` — 18 tests
unskipped and green (bugs 1–7, 10–13 + 4 verified-clean baselines), 2 skipped
(BUG-8/9 shared). No open bug proof remains in this file.

## Ledger

| ID | Finding | Outcome |
|---|---|---|
| P07-BUG-1 | blocker: screen not implemented | **fixed** (iter 2); proof green |
| P07-BUG-2 | blocker: no trial/restore path, onboarding dead end | **fixed** (iter 2); proofs green |
| P07-BUG-3 | major: bar could not render CTA → caption → legal row | **fixed** (iter 2); proof green |
| P07-BUG-4 | minor: caption dropped “the” | **fixed** (iter 2); proof green |
| P07-BUG-5 | minor: stray full stop, tag missing from data | **fixed** (iter 2); proofs green |
| P07-BUG-6 | minor: stale `errorMessage` survived a retry | **fixed** (iter 2); proof green |
| P07-BUG-7 | minor (latent): UPDATE-only writes | **fixed** (iter 2); proof green |
| P07-BUG-8 | major (shared): the 14-day trial never expires | **open, shared** — `SHARED_REQUEST.md` §1; proof skipped |
| P07-BUG-9 | minor (shared): kid-mode guard order during onboarding | **open, shared** — `SHARED_REQUEST.md` §2; proof skipped |
| P07-BUG-10 | major (latent): X could not leave the expired-trial paywall | **fixed** (iter 3); proof green |
| P07-BUG-11 | minor: `·` separators announced in semantics | **fixed** (iter 3); proof green |
| P07-BUG-12 | minor: trial CTA downgraded an active subscriber | **fixed** (iter 3); proof green |
| P07-BUG-13 | major: legal-link labels top-aligned, not centred | **fixed** (iter 4); proof green |

## Iteration-4 verification

- **P07-BUG-13 fixed.** `_LegalLink` now pads the label
  `(NestDevice.tapParent − 18) / 2 = 13` vertically inside its 44 px target
  (`paywall_view.dart:795-840`), so the paragraph line sits on the box centre.
  Measured in the probe: link baseline **757.25**, separator baseline
  **757.25**, delta **0.0** (was 13.0). The device shots
  `ui/app_light_4.png` / `ui/app_dark_4.png` show `Restore purchases · Terms ·
  Privacy` with the dots centred on the labels in both themes, and the
  `[P07-BUG-13]` proof is unskipped and green.
- **ORCHESTRATOR_NOTES iteration-4 items:**
  1. *Letter-spacing / benefit-4 wrap* — re-measured: every P07 text style
     renders `letterSpacing 0.0` (title, benefit, plan title, caption, legal
     link), and no call site adds tracking. P07’s CSS sets none (`.display`
     and `.status-time`, the only tracked classes, do not apply to this
     screen). The device shots show “Co-parent sharing, so James sees the
     same” on one line in light and dark; no text or copy was changed.
  2. *Separators* — the dots now share the links’ centred baseline (proof
     pins delta ≤ 1 px); they remain non-interactive 18 px boxes centred by
     the `Wrap`, which is visually identical to a 44 px centred box, and stay
     out of semantics (BUG-11).
  3. *Title orphan “days”* — accepted, no hard break inserted; the block
     height is unchanged and the copy string is untouched.
- **Standard hunt list re-checked on the changed build** (the only product
  change this iteration is the `_LegalLink` padding, plus the shared
  letter-spacing defaults): rapid double taps, close during an in-flight
  request, deep links/back navigation, kid-mode guard (onboarded →
  `/parental-gate`), restart persistence, dark-mode contrast (tokens
  unchanged; all P07 pairs ≥ 5:1), 320 dp × 1.3 text scale (no
  overflow/exception, legal row still present), async/dispose (bloc 9
  cancels emitters; no emit-after-close throw), expired gate (path
  `/paywall`, close control absent, CTA present, no exception). Money
  rounding and child-data edge cases remain N/A (no arithmetic, no child
  data on P07).
- **FONTS:** no `google_fonts`/`GoogleFonts` anywhere in the feature or its
  tests (grep clean).
- No scratch/probe files remain in `app/`; the iteration-4 probe was deleted.

## Carried open items (shared, filed — not fixable under RULES §1)

1. **P07-BUG-8 — major (shared):** the 14-day trial never expires; nothing in
   `app/lib` writes `subscription_status = 'expired'`, so the router’s
   `trialExpired → /paywall` redirect is dead code. Filed in
   `SHARED_REQUEST.md` §1 (owner: `core/data/app_session.dart` +
   `app/launch.dart`). The P07 side of the pair is ready: P07-BUG-10 fixed
   the expired-gate close behaviour, so landing expiry will not trap the
   parent. Proof `[P07-BUG-8]` stays `skip: true`.
2. **P07-BUG-9 — minor (shared):** kid-mode + onboarding-incomplete deep link
   to `/paywall` ends on `/welcome` instead of `/parental-gate` (guard
   ordering in `app/lib/app/router.dart`). Filed in `SHARED_REQUEST.md` §2.
   Proof `[P07-BUG-9]` stays `skip: true`.

Neither is P07-local; the screen, its handoff and the full suite land without
them, and the skips keep the suite green until the orchestrator lands the
shared batch.

## Verification (run this stage, `app/`)

- `flutter test test/features/paywall/p07_bugs_test.dart` → **+18 ~2**.
- `flutter test test/features/paywall/` → **+107 ~2**.
- Full `flutter test` → **+805 ~2, all pass** (2 skips: the shared
  P07-BUG-8/9 proofs).
- `flutter analyze` → `No issues found!`; `dart format` → 370 files, 0
  changed.
- No screen code touched; only `app/test/features/paywall/p07_bugs_test.dart`
  and this file.

## Verdict basis

No blocker or major screen-local bug remains. All thirteen findings have
proofs: 1–7 and 10–13 are fixed and green, and 8/9 are shared platform items
filed for the orchestrator, carried per the P08 iteration-4 precedent. The
iteration-4 orchestrator notes are all addressed and measured (baselines,
letter-spacing 0.0, one-line benefit 4, accepted title orphan). The standard
hunt list is clean.

VERDICT: PASS
