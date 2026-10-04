# K02 · Kid PIN — Stage 6 bug hunt (iteration 4)

Adversarial pass over `/kid-pin` on the iteration-4 build (`8e5d255`, main
merged at `9a1f16d`, bringing the P17 gate and the shared batches). Every
proof lives in `app/test/features/kid_home/k02_bugs_test.dart` and runs
against the real in-memory Drift database (Seed.demo), the real repository,
or a feature-local fake. No screen code was changed by this stage; no
simulator was used (SIMULATORS rule).

```
flutter test test/features/kid_home/k02_bugs_test.dart --timeout 120s
  → +34: All tests passed!          (zero skips; finishes in 3 s)

flutter test test/features/kid_home/ --timeout 120s
  → +444 ~1: All tests passed!      (the ~1 is the sibling K01-BUG-7 park)
```

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

## Verified this pass

- **AVATAR INITIALS rule** — all three `kid_home` sites now route through the
  feature-local grapheme-safe helper `kidAvatarInitial`
  (`kid_pin_view.dart:168`, `kid_home_view.dart:364`,
  `profile_tile.dart:94`); no `name[0]` remains in the feature. New probes:
  a helper unit test (empty → `?`, custom fallback, `maya`/`M`,
  `🐝`/`🇬`/`𝒜`/`𠀀`/`Å`, and a well-formedness check over
  emoji/flag/math/CJK/ZWJ names that fails on any lone surrogate) plus the
  existing per-variant render probes (`_assertInitial`) and the K02-BUG-1
  regression.
- **Shared `nestAvatarInitial` not yet on main** — ORCHESTRATOR_NOTES (12:00)
  makes the remaining sites a shared batch item (`core/` + the `family` /
  `today` features, which still use `name[0]`); it is explicitly not a K02
  finding. K02 keeps the equivalent local helper (with a `TODO` to switch)
  until the shared one lands.
- **Iteration-4 token changes are value-preserving** — `NestRadii.allPill`
  is radius 999 (the literal it replaced) and `_KidPinBody.avatarDisc` is the
  named `.k2-ava` 128; the shape/geometry tests still bite and pass.
- **P17 gate exit** — the lock double-tap probe leaves the gate through its
  only post-merge exit, the 56 px ghost `Back to Pip`, and still lands back
  on `/kid-pin` with exactly one gate (the `pageBack()` fallback remains for
  an AppBar regression).
- **All earlier regressions still green**: keypad grid exact (centres
  113/195/277, tops 393/475/557/639), 24-char names at 320/1.3 and 390/1.3,
  the no-PIN latch releases (pair and null-child declines), the hidden
  wrong-code toast, and the kid-mode expired-trial → gate funnel.

## Checked clean (probes — all green)

| Category | Probe | Result |
|---|---|---|
| avatar initials | helper unit probes + `🐝 Bee`, `🇬🇧 Ben`, `𝒜da`, `Åsa` render whole, crash-free | pass |
| data edges | 0 children (Seed.empty): chooser + `Choose` tap action → K01; 1 child; 6 children (active child only, no roster leak); £0.00 / £999.99 / 9999 coins never render; no `£` | pass |
| long names | `Maximilian-Alexander` fits at 390/1.0, 390/1.3 and 320/1.0; the 24-char P05 maximum fits at 320/1.3 and 390/1.3 | pass |
| shared keypad grid | 11 key circles 72×72; centres 113/195/277; row tops 393/475/557/639 | pass |
| rapid double taps | 4th-digit double tap submits once (`kid_pin_view_test.dart`); Back double-tap returns once; Back-then-lock burst cannot stack a gate; lock double-tap opens exactly one gate (exits via `Back to Pip`) | pass |
| back nav + deep links | deep-link Back → picker; a passed PIN cannot be popped back to; a pushed route pops to the picker | pass |
| restart persistence | wrong attempt + restart: dots reset, toast gone, PIN still enforced | pass |
| mode guards | lock from loaded and failure states → P17 gate; kid mode + expired trial → gate; parent-mode `/kid-pin` renders and Back → picker (observed; matches K01/K03 notes); kid mode → parent-only is router-guarded | pass |
| dark contrast | greeting ≥3.0; caption over hill-front and meadow ≥4.5; mark pill, keypad key, avatar initial, dot border ≥4.5/3.0 | pass |
| 320 px + 1.3 | loaded screen + wrong-PIN toast, failure card, chooser: no overflow exceptions | pass |
| async gaps | pop while the PIN check hangs: no exception, no stale navigation (emit-after-close is a no-op in bloc 9.2.1) | pass |
| BST/GMT + money | whole visible text tree byte-identical across a BST→GMT clock change; no dates, no `£`; integer pence only (no money on K02) | pass |
| accessibility | digits / Delete / Back / lock expose `SemanticsAction.tap` and `performAction` drives the real state (`kid_pin_view_test.dart`); dots have no tap; failure `Try again` and chooser `Choose` expose tap and drive the real outcome; the awaiting label is present and non-interactive | pass |

## Observations (not defects)

1. **`context.read` before the `mounted` guard** — the no-PIN post-frame
   callback reads the bloc (`kid_pin_view.dart:77`) before checking
   `mounted` (`:79`). No shipped flow disposes the route inside that frame;
   moving the check first remains cheap hardening.
2. **Awaiting label merge** — `Semantics(label: 'Checking your code')` is a
   label-only node, so it merges into the screen's text node instead of
   replacing the dots node. The phrase is exposed and non-interactive;
   `container: true` would give it a distinct node if wanted.
3. **Parent-mode kid routes** — a parent-mode deep link to `/kid-pin`
   renders the kid screen (same as the K01/K03 notes); the boundary guarded
   today is the opposite direction (kid mode → parent-only stops at the
   gate).
4. **Shared `nestAvatarInitial` pending** — the four `name[0]` sites in
   `features/family/**` and `features/today/**` are the shared
   `shared/avatar_initial` batch (SHARED_REQUEST #3); K02's feature is fully
   converted to its local grapheme-safe helper.
5. **Rules N/A on K02** — no chip rows (`NestChipWrap`), no
   `text-wrap: balance` heading (`NestBalancedText`), no Pip on the screen
   (avatar initial only); the failure-card `PipAvatar(mochi, stage 1)` is
   K03's shared no-child fallback. Bottom-edge rule: no bottom bar on K02,
   the shared meadow runs to the edge.

## Verdict

All five findings (one major, four minor) remain fixed with green regression
proofs; the new grapheme-safe helper is probed directly and through the
screen; the iteration-4 token changes are value-preserving; no new bugs were
found and none are open. No major bugs.

VERDICT: PASS
