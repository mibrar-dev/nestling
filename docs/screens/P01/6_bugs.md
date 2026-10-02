# P01 Welcome — bug hunt (Stage 6, iteration 3)

Adversarial re-test of `/welcome` (parent mode, feature `onboarding`) on
`screen/P01` at `ca45deb` (main merged through `045d190`). All iteration-1/2
bugs have landed fixes; this pass re-verified every proof, added an
end-to-end restart proof for the last one, and re-ran the adversarial probes.
No new bugs found.

Proofs live in `app/test/features/onboarding/p01_bugs_test.dart` — **7 tests,
0 skips**: BUG-1, BUG-2, BUG-3, BUG-3b, BUG-4, **BUG-4b (new)**, BUG-5.

Gates: `dart format` 342 files clean · `flutter analyze` No issues found ·
`flutter test test/features/onboarding` **49 passed, 0 skipped, 0 failed** ·
full suite **356 passed, 0 skipped, 0 failed** (no skipped test anywhere in
the repo).

---

## Fixed, enforced and re-verified

| # | Bug | Fix | Proof |
|---|---|---|---|
| BUG-1 | Scene cropped, not scaled, below 390dp | `welcome_view.dart:98-111` — `OverflowBox` lays the Stack out at full 350×388, only paint scales | `sceneStack.size == Size(350, 388)`, no paint clip at 320dp; 4 width regressions |
| BUG-2 | OS bottom inset counted twice | `763192d` — `NestHomeIndicator` no-op, `NestBottomCta`'s `SafeArea` owns the inset once | baseline 672.0 → inset 638.0 (−34), caption bottom 794, indicator 0×0 |
| BUG-3 / 3b | Kid mode entered the onboarding flow un-gated | `71d2400` + `ded8eb9` — onboarding/parent routes redirect to `/parental-gate` | `/welcome` and `/value-tour` proofs land on the gate |
| BUG-4 | Fresh install never created the `app_state` row | `045d190` — `MigrationStrategy.beforeOpen` inserts row 1 (`insertOrIgnore`) | row exists on a brand-new DB; `OnboardingRepository.completeOnboarding()` persists (`true` after `refresh`) |
| BUG-5 | Coin `--sh-1` shadow clipped by the scene Stack | `welcome_view.dart:111` — `Stack(clipBehavior: Clip.none)` | `clipBehavior == Clip.none` |

### New this iteration — BUG-4b (end-to-end restart proof)

`BUG-4b fresh install restart lands on Today after onboarding`: on an
unseeded in-memory DB (the release first-launch shape), launch 1 redirects
`/today` → `/welcome`; the real repository write completes onboarding; a
second launch (simulated restart, same DB) stays on `/today`. This closes the
loop the bug caused, which the persistence-only proof could not show on its
own.

Also probed the iteration-3 headline cap (mandatory `ORCHESTRATOR_NOTES` #3):
the headline render box is 300 wide at 390dp (constraint `maxWidth: 300`) and
correctly parent-capped to **280** at 320dp with text scale 1.3 — no
overflow, no exception. Stage 5 confirmed the design break visually:
`Chores that feel` / `like a game.` in both themes, band 4 **5.9% → 0.6%**.

---

## Verified sound (probes)

| Area | Result |
|---|---|
| Rapid double tap | single `/value-tour`, no exception |
| Data edge cases (0/2/6 children, "Maximilian-Alexander", 9999 coins, £999.99 goal) | P01 renders no child/money data; screen unchanged, no exception |
| Back navigation / deep links | `/welcome` root route unchanged in parent mode; kid-mode deep link now gated (BUG-3) |
| State after restart | **BUG-4b passes** (see above) |
| Parent/kid guard | all 17 parent routes gated (shared parameterized test) |
| Dark/light contrast | headline 16.30/15.45:1, body 10.84/8.31:1, caption 9.82/8.87:1, primary 8.43/4.96:1 — all ≥4.5 |
| Text scale 1.3 × width 320 (+390/430, light/dark) | 12-case matrix green; headline capped to 280; no overflow/ellipsis |
| Async gap / emit after close | bloc closed mid-load cancels cleanly |
| Timezone (Europe/London) / money rounding | P01 renders no dates or money — N/A by construction |
| PipAvatar / semantics | mandated mochi·sunny·stage 2·idle in the 168×168 @ (91,120) slot; one labelled semantics node, HTML alt text intact |

## Open, non-blocking (not defects / not blockers)

1. **Shared request — fonts + first-frame warm-up.** Inter/Nunito still load
   from the Google-Fonts CDN at first paint, and nothing calls
   `NestlingImages.precache` (it lists webp rasters while screens render SVG).
   Non-blocking; the only remaining cause of the `shot.sh` repaint warning.
2. **Shared, low priority — inset-0 bottom band.** On devices reporting no
   bottom inset, the CTA panel sits flush with the edge (no 34dp band). On the
   reference (home-indicator) device it is exact; the orchestrator's chrome
   rule accepts it. Optional shared floor filed.
3. **Test quality — the headline-width assertion is cap-agnostic** (review
   finding 2): it guards against cap removal but cannot validate the design
   break; a metric-based assertion needs bundled fonts (item 1).
4. **`ORCHESTRATOR_NOTES` item 5 wording** vs the enforced proof (review
   finding 1): the note says "identical"; the shipped contract is "moves up by
   exactly the inset" (measured −34, design-verified). Owner: orchestrator
   (amend the note or land the floor in item 2).

Docs corrected this pass: `2_build.md` (BUG-4 is fixed, suite 356/0/0),
`1_plan.md` (headline cap supersedes the uncapped plan), `SHARED_REQUEST.md`
(BUG-2/3/4 closed; remaining items are the non-blockers above).

## Summary

| # | Severity | Status |
|---|---|---|
| BUG-1 | blocker | fixed, proof enforced |
| BUG-2 | major | fixed, proof rewritten + enforced |
| BUG-3/3b | major | fixed, proofs enforced |
| BUG-4 / BUG-4b | major | fixed, persistence + restart proofs enforced |
| BUG-5 | minor | fixed, proof enforced |

No major bugs remain; every proof is enforced, the suite has zero skips, and
the one design item the orchestrator called out (headline break) is visually
verified in both themes.

VERDICT: PASS
