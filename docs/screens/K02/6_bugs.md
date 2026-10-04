# K02 · Kid PIN — Stage 6 bug hunt (iteration 2)

Adversarial pass over `/kid-pin` on the iteration-2 build (`060d869`, main
merged at `c094fd5`, which brought the shared keypad grid `b1bfb4e`/`9cac0c6`
and `NestKeypadFit`). Every proof lives in
`app/test/features/kid_home/k02_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake. No screen code was changed by this stage; no simulator
was used (SIMULATORS rule).

```
flutter test test/features/kid_home/k02_bugs_test.dart
  → +30 ~1: All tests passed!        (K02-BUG-5 parked, skipped)

flutter test --run-skipped test/features/kid_home/k02_bugs_test.dart \
  --plain-name K02-BUG-5
  → 1 deterministic failure: Expected '/kid-home', Actual '/kid-pin'
    (stuck on the loading spinner)

flutter test test/features/kid_home/
  → +435 ~2: All tests passed!       (K02-BUG-5 + K01-BUG-7 skips)

Iteration-2 build gate (context): `flutter test` → +2978 ~2: All tests
passed! with the four proofs already un-skipped.
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K02-BUG-1 | major | **FIXED (iteration 2), regression green** — emoji-leading initial renders whole |
| K02-BUG-2 | minor | **FIXED (iteration 2), regression green** — greeting no longer clips at 320 px + 1.3 |
| K02-BUG-3 | minor | **FIXED (iteration 2), regression green** — the no-PIN auto-advance re-checks the child |
| K02-BUG-4 | minor | **FIXED (iteration 2), regression green** — the wrong-code toast is hidden before `go(home)` |
| K02-BUG-5 | minor (latent) | **OPEN** — the no-PIN latch is never released when its navigation is declined |

---

### K02-BUG-5 — minor (latent) — OPEN

**Mechanism.** The iteration-2 fix for K02-BUG-3 re-checks the child inside
the post-frame callback and declines the navigation when the child is now
PIN-protected — but it leaves `_noPinHandled = true`
(`kid_pin_view.dart:71-83`). The listener's `_noPinHandled` early return then
blocks every later no-PIN auto-advance, so if the active child becomes a
no-PIN child again, K02 renders `_KidLoading` (the `!child.pinSet` branch,
`:116-120`) with no keys and no way forward except Back.

**Repro (deterministic fake).** `_StreamPairRepo` in the test file:
emit `Leo (pinSet: false)` + `Maya (pinSet: true)` in one event-loop turn →
the re-check declines and Maya's PIN screen shows (K02-BUG-3 stays fixed).
Emit `Leo` again → expected `/kid-home`, actual stays `/kid-pin` on the
spinner. Verified: path `/kid-pin`, `CircularProgressIndicator` present,
Leo's PIN body never renders.

**Reachability.** Needs the active child to change no-PIN → PIN → no-PIN
while the route is mounted; no shipped flow writes `active_child_id` that
way today (K01 writes once and routes no-PIN children straight to
`/kid-home`), so this is a latent hardening hole like K01-BUG-7 — minor,
not a user-visible defect.

**Failing test.** `K02-BUG-5: a no-PIN child after a PIN child is stuck on
the loading spinner` (skipped; bug id in the test description).

**Suggested fix (one line).** In the post-frame callback's decline path,
release the latch: set `_noPinHandled = false` when the re-check does not
navigate (or latch the handled child id and compare), so a later no-PIN
state can advance again.

---

## Verified fixed this pass (regression proofs run un-skipped)

- **K02-BUG-1** — `kid_pin_view.dart:156-158` now builds the initial from
  the first rune (`String.fromCharCode(nickname.runes.first).toUpperCase()`);
  `🐝 Bee` renders `🐝` with `takeException() == null`. Probe: `🇬🇧 Ben`,
  `𝒜da`, `Åsa` initials all render whole and crash-free.
- **K02-BUG-2** — the greeting is `maxLines: 3` (`:246-253`). The 20-char
  name fits at 320/1.3; a 24-char name (P05's maximum) fits at 320/1.3 and
  390/1.3 (`RenderParagraph.didExceedMaxLines == false`).
- **K02-BUG-3** — the post-frame callback re-reads
  `context.read<KidHomeBloc>().state.child` and only `go(home)` while the
  child is still `!pinSet` (`:74-82`); the Leo→Maya pair stays on
  `/kid-pin` with Maya's PIN screen.
- **K02-BUG-4** — the pass listener calls
  `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before
  `context.go(home)` (`:87-92`); the wrong-code toast is gone on
  `/kid-home`.
- **Review finding 2** — `_onKey` reverts the 4th digit when the bloc's
  child is momentarily null (`:43-49`), so the keypad cannot sit at four
  filled dots with no pending outcome.
- **Review finding 4** — `_BottomInset`
  (`max(viewPadding.bottom, NestDevice.homeH)`) replaces the mock indicator
  reserve in `_KidLoading` / `_KidFailure` / `_NoActiveChild`.
- **ORCHESTRATOR_NOTES 07:13 closed** — K02 passes
  `fit: NestKeypadFit.shrinkWrap` (`:283-288`). The new unit probe measures
  all 11 key circles 72×72 at column centres **113 / 195 / 277** and row
  tops **393 / 475 / 557 / 639** — exactly the design grid (±0.5 px), so
  the iteration-1 keypad drift (columns ±14, rows +20) is gone.

## Checked clean (probes — all green)

| Category | Probe | Result |
|---|---|---|
| data edges | 0 children (Seed.empty): chooser + `Choose` tap action → K01; 1 child; 6 children (active child only, no roster leak); £0.00 / £999.99 / 9999 coins never render; no `£` on the screen | pass |
| long names | `Maximilian-Alexander` fits at 390/1.0, 390/1.3 and 320/1.0; the 24-char P05 maximum fits at 320/1.3 and 390/1.3 | pass |
| non-BMP initials | `🐝 Bee` (regression), `🇬🇧 Ben`, `𝒜da`, `Åsa` render whole, crash-free | pass |
| shared keypad grid | 11 key circles 72×72; centres 113/195/277; row tops 393/475/557/639 | pass |
| rapid double taps | 4th-digit double tap submits once (`kid_pin_view_test.dart`); Back double-tap returns once; Back-then-lock burst cannot stack a gate; lock double-tap opens exactly one gate | pass |
| back nav + deep links | deep-link Back → picker; a passed PIN cannot be popped back to; a pushed route pops to the picker | pass |
| restart persistence | wrong attempt + restart: dots reset, toast gone, PIN still enforced | pass |
| mode guards | lock from loaded and failure states → P17 gate; parent-mode `/kid-pin` renders and Back → picker (observed; matches K01/K03 notes); kid mode → parent-only is router-guarded | pass |
| dark contrast | greeting ≥3.0; caption over hill-front and meadow ≥4.5; mark pill, keypad key, avatar initial, dot border ≥4.5/3.0 | pass |
| 320 px + 1.3 | loaded screen + wrong-PIN toast, failure card, chooser: no overflow exceptions | pass |
| async gaps | pop while the PIN check hangs: no exception, no stale navigation (emit-after-close is a no-op in bloc 9.2.1) | pass |
| BST/GMT + money | whole visible text tree byte-identical across a BST→GMT clock change; no dates, no `£` | pass |
| accessibility | digits / Delete / Back / lock expose `SemanticsAction.tap` and `performAction` drives the real state (`kid_pin_view_test.dart`); dots have no tap; failure `Try again` and chooser `Choose` expose tap and drive the real outcome; the awaiting label is present and non-interactive | pass |

## Observations (not defects)

1. **`context.read` before the `mounted` guard** — the no-PIN post-frame
   callback reads the bloc (`kid_pin_view.dart:77`) before checking
   `mounted` (`:79`). No shipped flow disposes the route inside that frame,
   so there is no repro; moving the `mounted` check first is cheap
   hardening.
2. **Awaiting label merge** — `Semantics(label: 'Checking your code')` is a
   label-only node, so it merges into the screen's text node instead of
   replacing the dots node. The phrase is exposed and non-interactive;
   `container: true` would give it a distinct node if wanted.
3. **Parent-mode kid routes** — a parent-mode deep link to `/kid-pin`
   renders the kid screen (same as the K01/K03 notes); the boundary guarded
   today is the opposite direction (kid mode → parent-only stops at the
   gate).
4. **Rules N/A on K02** — no chip rows (`NestChipWrap`), no
   `text-wrap: balance` heading (`NestBalancedText`), no Pip on the screen
   (avatar initial only); the failure-card `PipAvatar(mochi, stage 1)` is
   K03's shared no-child fallback. Bottom-edge rule: no bottom bar on K02,
   the shared meadow runs to the edge.
5. **SHARED_REQUEST #1 / #3 remain orchestrator-owned** — the shared
   `NestType.kidSay` / `kidMark` styles (local metric-matched TODOs) and the
   grapheme-safe initial helper for the six sibling sites in other features;
   K02's own site is fixed.

## Verdict

All four iteration-1 bugs (including the major emoji crash) are fixed with
green regression proofs, and the ORCHESTRATOR_NOTES keypad mandate is
verified at the unit level. One new minor latent finding (K02-BUG-5, a
no-PIN latch that a declined navigation leaves set) is open with a one-line
fix; it needs a no-PIN → PIN → no-PIN active-child sequence that no shipped
flow produces. No major bugs.

VERDICT: PASS
