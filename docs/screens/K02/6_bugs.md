# K02 · Kid PIN — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/kid-pin` on the iteration-1 build (`7435738`, main
merged at `e01420a`). Every proof lives in
`app/test/features/kid_home/k02_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake. No screen code was changed by this stage; no simulator
was used (SIMULATORS rule).

```
flutter test test/features/kid_home/k02_bugs_test.dart
  → +21 ~4: All tests passed!        (K02-BUG-1..4 parked, skipped)

flutter test --run-skipped test/features/kid_home/k02_bugs_test.dart \
  --plain-name K02-BUG
  → 4 deterministic failures: K02-BUG-1, K02-BUG-2, K02-BUG-3, K02-BUG-4

flutter test test/features/kid_home/
  → +418 ~5: All tests passed!      (the 4 parked proofs + K01-BUG-7)
```

## Findings

| # | Severity | Status |
|---|---|---|
| K02-BUG-1 | major | **OPEN** — an emoji-leading nickname throws during avatar render |
| K02-BUG-2 | minor | **OPEN** — the greeting clips at 320 px + 1.3 scale |
| K02-BUG-3 | minor (latent) | **OPEN** — the no-PIN auto-advance can skip a PIN |
| K02-BUG-4 | minor | **OPEN** — the wrong-code toast outlives a successful retry |

---

### K02-BUG-1 — major — a nickname starting with an emoji breaks the avatar

**Mechanism.** `kid_pin_view.dart:140` builds the avatar initial with
`nickname[0].toUpperCase()`. For a non-BMP first character (any emoji, e.g.
🐝 = U+1F41D) `[0]` slices the UTF-16 surrogate pair and returns an unpaired
high surrogate. Flutter's text layout then throws
`Invalid argument(s): string is not well-formed UTF-16` while laying out
`NestAvatar`'s `Text`, so the avatar disc renders broken and the error
surfaces as a framework exception (debug: error paint; release: dropped
text plus a console error).

**Repro.** P05 accepts any non-empty nickname ≤24 characters
(`family_bloc.dart:78-85`) and applies no character filter, so a parent can
save "🐝 Bee". Deep-linking `/kid-pin` with that child active (and, once the
picker has the same fix, tapping their tile) renders K02 with the exception.
The failing proof seeds `nickname = '🐝 Bee'` on Maya and pumps `/kid-pin`;
it asserts `NestAvatar.initial == '🐝'` and `takeException() == null`.

**Failing test.** `K02-BUG-1: a nickname starting with an emoji throws in
the avatar initial` (skipped; bug id in the test description).

**Suggested fix (small).** Take the first *rune* instead of the first code
unit:

```dart
final initial = nickname.isEmpty
    ? '?'
    : String.fromCharCode(nickname.runes.first).toUpperCase();
```

(`nickname.characters.first` is the fuller grapheme fix, but `characters` is
not a direct dependency yet.) The same `nickname[0]` expression exists at
`profile_tile.dart:96`, `kid_home_view.dart:364`, `kid_card_grid.dart:68`
and `child_profile_body.dart:108` — a shared `kidInitial()` helper
(SHARED_REQUEST) closes the whole class; the K02 fix alone stops this
screen's exception.

---

### K02-BUG-2 — minor — the greeting clips at 320 px + 1.3 scale

**Mechanism.** The greeting is
`Text('Hi $nickname! Enter your secret code', maxLines: 2)` with no
ellipsis. At 320 px content width (280) and text scale 1.3 (26 px Nunito
800), a 20-character nickname (P05's limit is 24) needs a third line;
`RenderParagraph.didExceedMaxLines` is true and the tail of the sentence is
silently dropped mid-glyph.

**Repro.** Nickname `Maximilian-Alexander`, width 320, scale 1.3:
`didExceedMaxLines == true`. The same name fits at 390/1.0, 390/1.3 and
320/1.0 — those combinations are green probes in the same file.

**Failing test.** `K02-BUG-2: a 20-char nickname clips the greeting at
320 px + 1.3 scale` (skipped; bug id in the test description).

**Suggested fix (small).** Let the say line grow with the accessibility
scale (e.g. `maxLines: 3` when
`MediaQuery.textScalerOf(context).scale(20) > 20`, or drop `maxLines` —
the ListView scrolls), or at minimum `overflow: TextOverflow.ellipsis` so
the cut is legible. Keep the design's single-line break for short names.

---

### K02-BUG-3 — minor (latent) — the no-PIN auto-advance can bypass a PIN

**Mechanism.** The first `BlocListener` (`kid_pin_view.dart:57-70`)
navigates when a loaded no-PIN child arrives, but the actual
`context.go(home)` runs in a post-frame callback and never re-checks the
child. If a second home emission replaces the no-PIN child with a
PIN-protected one before that callback runs, K02 still navigates home —
the PIN is skipped.

**Repro (deterministic fake).** `_StreamPairRepo` emits
`Leo (pinSet: false)` and then `Maya (pinSet: true)` in one event-loop
turn; after settling, the path is `/kid-home` and Maya's PIN screen never
rendered.

**Reachability.** No shipped flow writes `app_state.active_child_id` twice
inside one frame (K01 writes once, before pushing, and routes no-PIN
children straight to `/kid-home`), so this is a latent hardening hole like
K01-BUG-7 rather than a user-visible defect today — hence minor, not major.

**Failing test.** `K02-BUG-3: a no-PIN child followed by a PIN child in one
stream turn navigates home without the PIN` (skipped; bug id in the test
description).

**Suggested fix (small).** In the post-frame callback, read the bloc state
again and only `go(home)` when the current child is still non-null and
`!pinSet`; or navigate directly in the listener (it fires outside build, so
the post-frame hop is unnecessary).

---

### K02-BUG-4 — minor — the wrong-code toast outlives a successful retry

**Mechanism.** `showNestToast` uses the root `ScaffoldMessenger` (3 s
duration). A wrong attempt followed by a correct one within that window
navigates to `/kid-home` with "That didn't work. Try again." still on
screen — telling the child the code failed after it succeeded.

**Repro.** Enter `9999`, pump 200 ms (toast visible), enter `1234`, settle:
`currentPath == /kid-home` and the toast text is still found.

**Failing test.** `K02-BUG-4: the wrong-code toast is still visible on
/kid-home after a correct retry` (skipped; bug id in the test description).

**Suggested fix (small).** `ScaffoldMessenger.of(context)
.hideCurrentSnackBar()` in the pass listener before `context.go`, or hide
it when a new digit is pressed.

---

## Checked clean (probes — all green)

| Category | Probe | Result |
|---|---|---|
| data edges | 0 children (Seed.empty): chooser + `Choose` tap action → K01; 1 child; 6 children (active child only, no roster leak); £0.00 / £999.99 / 9999 coins never render; no `£` on the screen | pass |
| long names | `Maximilian-Alexander` fits at 390/1.0, 390/1.3 and 320/1.0 | pass (320/1.3 = K02-BUG-2) |
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

1. **Keypad pitch** — this worktree still has `NestKeypad`'s 24 px columns /
   16 px rows; the design CSS `.keypad` is 10/10. This is the known shared
   deviation tracked by SHARED_REQUEST #2 and ORCHESTRATOR_NOTES (07:13);
   the UI stage owns it, not this hunt.
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

## Verdict

One major (K02-BUG-1) and three minor open bugs. All four proofs are
deterministic under `--run-skipped`; the plain suite stays green with them
parked. A screen with a crash-class defect cannot pass the bug stage.

VERDICT: FAIL
