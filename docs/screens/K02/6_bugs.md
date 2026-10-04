# K02 · Kid PIN — Stage 6 bug hunt (iteration 3)

Adversarial pass over `/kid-pin` on the iteration-3 build (`cd6e6fa`, main
merged at `a967441`, bringing the shared `kid_trial_gate` + `unique_ids`
batches and P09). Every proof lives in
`app/test/features/kid_home/k02_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake. No screen code was changed by this stage; no simulator
was used (SIMULATORS rule).

```
flutter test test/features/kid_home/k02_bugs_test.dart --timeout 120s
  → +33: All tests passed!          (zero skips; file finishes in 3 s)

flutter test test/features/kid_home/ --timeout 120s
  → +441 ~1: All tests passed!      (the ~1 is the sibling K01-BUG-7 park)
```

The mandatory ORCHESTRATOR_NOTES (10:32) hang fix is verified: the file that
previously ran for over an hour now finishes in seconds, under the required
per-test timeout.

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K02-BUG-1 | major | **FIXED (iter 2), regression green** — emoji-leading initial renders whole |
| K02-BUG-2 | minor | **FIXED (iter 2), regression green** — greeting no longer clips at 320 px + 1.3 |
| K02-BUG-3 | minor | **FIXED (iter 2), regression green** — the no-PIN auto-advance re-checks the child |
| K02-BUG-4 | minor | **FIXED (iter 2), regression green** — the wrong-code toast is hidden before `go(home)` |
| K02-BUG-5 | minor (latent) | **FIXED (iter 3), regression + null-decline extension green** |

**No open findings on K02.**

---

## Verified fixed this pass

- **K02-BUG-5 (iteration-3 fix).** `kid_pin_view.dart:79-87` now releases the
  latch on the declined path: when the post-frame re-check does not navigate
  (PIN'd child or null child), `setState(() => _noPinHandled = false)` runs
  inside the `mounted` guard, so a later no-PIN state advances again.
  Proofs: the un-skipped pair regression (`Leo → Maya → Leo` reaches
  `/kid-home` with no K02 spinner) plus a new extension probe
  (`Leo → null → Leo` also advances — the null-child decline releases the
  latch too).
- **Mandatory hang fix (ORCHESTRATOR_NOTES 10:32).** The stage-3 fix is in
  place (multi-cycle tests call `setUpTestScope()` between cycles instead of
  leaking the previous app's Drift work into the fake-async queue). Verified:
  `--timeout 120s` plain run, `+33` in 3 s, exit 0; feature suite `+441 ~1`
  in 13 s.
- **All iteration-1/2 regressions still green**: emoji initial (`🐝`, plus
  `🇬🇧`, `𝒜`, `Å` variants), `maxLines: 3` + 24-char P05 maximum at 320/1.3
  and 390/1.3, the no-PIN pair re-check, the hidden wrong-code toast, and
  the shared keypad grid (11 keys 72×72 at centres 113/195/277 and row tops
  393/475/557/639 — exactly the design).

## Shared merges checked against K02

- **`kid_trial_gate`** — new probe: in kid mode with an expired trial,
  `/kid-pin` funnels to `/parental-gate` with no redirect loop and no
  exception. The expiry is driven through `AppSession` (`startTrialNow` +
  aged `trialStart` + `refresh`), never by writing `subscription_status`
  directly.
- **`unique_ids`** — N/A on K02: the feature creates no text-id rows; the
  only insert in its flow is a `quest_completions` row whose id is an
  autoincrement int. No clock-derived id anywhere in `kid_home`.

## Checked clean (probes — all green)

| Category | Probe | Result |
|---|---|---|
| data edges | 0 children (Seed.empty): chooser + `Choose` tap action → K01; 1 child; 6 children (active child only, no roster leak); £0.00 / £999.99 / 9999 coins never render; no `£` on the screen | pass |
| long names | `Maximilian-Alexander` fits at 390/1.0, 390/1.3 and 320/1.0; the 24-char P05 maximum fits at 320/1.3 and 390/1.3 | pass |
| non-BMP initials | `🐝 Bee`, `🇬🇧 Ben`, `𝒜da`, `Åsa` render whole, crash-free | pass |
| shared keypad grid | 11 key circles 72×72; centres 113/195/277; row tops 393/475/557/639 | pass |
| rapid double taps | 4th-digit double tap submits once (`kid_pin_view_test.dart`); Back double-tap returns once; Back-then-lock burst cannot stack a gate; lock double-tap opens exactly one gate | pass |
| back nav + deep links | deep-link Back → picker; a passed PIN cannot be popped back to; a pushed route pops to the picker | pass |
| restart persistence | wrong attempt + restart: dots reset, toast gone, PIN still enforced | pass |
| mode guards | lock from loaded and failure states → P17 gate; kid mode + expired trial → gate (new); parent-mode `/kid-pin` renders and Back → picker (observed; matches K01/K03 notes); kid mode → parent-only is router-guarded | pass |
| dark contrast | greeting ≥3.0; caption over hill-front and meadow ≥4.5; mark pill, keypad key, avatar initial, dot border ≥4.5/3.0 | pass |
| 320 px + 1.3 | loaded screen + wrong-PIN toast, failure card, chooser: no overflow exceptions | pass |
| async gaps | pop while the PIN check hangs: no exception, no stale navigation (emit-after-close is a no-op in bloc 9.2.1) | pass |
| BST/GMT + money | whole visible text tree byte-identical across a BST→GMT clock change; no dates, no `£`; integer pence only (no money on K02) | pass |
| accessibility | digits / Delete / Back / lock expose `SemanticsAction.tap` and `performAction` drives the real state (`kid_pin_view_test.dart`); dots have no tap; failure `Try again` and chooser `Choose` expose tap and drive the real outcome; the awaiting label is present and non-interactive | pass |

## Observations (not defects)

1. **`context.read` before the `mounted` guard** — the no-PIN post-frame
   callback reads the bloc (`kid_pin_view.dart:77`) before checking
   `mounted` (`:79`). No shipped flow disposes the route inside that frame,
   so there is no repro; moving the `mounted` check first remains cheap
   hardening.
2. **Awaiting label merge** — `Semantics(label: 'Checking your code')` is a
   label-only node, so it merges into the screen's text node instead of
   replacing the dots node. The phrase is exposed and non-interactive;
   `container: true` would give it a distinct node if wanted.
3. **Parent-mode kid routes** — a parent-mode deep link to `/kid-pin`
   renders the kid screen (same as the K01/K03 notes); the boundary guarded
   today is the opposite direction (kid mode → parent-only stops at the
   gate).
4. **K02-TEST-BUG-A (stage 3, feature-level, not this screen)** — the
   emoji crash class is still live on K01/K03 sibling sites
   (`profile_tile.dart:96`, `kid_home_view.dart:364`); K02's own site is
   fixed and proven. Tracked as SHARED_REQUEST #3; the sibling loops own
   their screens.
5. **Rules N/A on K02** — no chip rows (`NestChipWrap`), no
   `text-wrap: balance` heading (`NestBalancedText`), no Pip on the screen
   (avatar initial only); the failure-card `PipAvatar(mochi, stage 1)` is
   K03's shared no-child fallback. Bottom-edge rule: no bottom bar on K02,
   the shared meadow runs to the edge.

## Verdict

All five findings (one major, four minor) are fixed with green regression
proofs; the mandatory test-hang item is resolved; the shared `kid_trial_gate`
and `unique_ids` merges are checked against K02. No open bugs, no major
bugs.

VERDICT: PASS
