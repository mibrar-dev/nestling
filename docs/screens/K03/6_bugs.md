# K03 Kid home — bug hunt (Stage 6, iteration 7)

Adversarial pass over `kid_home` K03 after the iteration-7 integration:
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods, integer money, the owner rules, CHILD ORDER, COPY,
fonts and the newly landed shared components. No screen code was changed in
this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 51 tests:
  46 run green, 5 skipped (`K03-BUG-13` ×3 widths, `K03-BUG-14`,
  `K03-BUG-15`).
- Run the skipped proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG"`.

## Open bugs

### K03-BUG-13 — Pet slot off-centre at every width, clipped at 320 (Major, shared)

Unchanged since iteration 6 and now **quantified by the iteration-7 build**:
the explicit `NestPetStage` mode reserves `stageW = nestW / 0.62` (419.35 px)
and lays the scene out against that nominal width, while the content box is
350 px (390 − 2×20) — every child shifts right by 34.68 px; at 320 px the
shift is 69.68 px and the nest overflows its slot by 59.7 px, cut by the
Stack (≈40 px past the screen edge). A 260×236 nest at the design's visible
size is unreachable from K03 without the shared component also gaining a
`nestHeight`/ratio change, so the build filed it rather than hacking:
SHARED_REQUEST #13 (with the arithmetic table) plus a real-font pin in
`kid_home_geometry_test.dart` (currently skipped) that reproduces the device
captures: nest centre 229.68 (+34.68 vs 195), hearts 494.0 (+46 vs 448),
first card 615.0 (+56 vs 559).

Failing tests (skipped so the suite stays green):
- `K03-BUG-13: the pet slot stays centred at 320px` / `390px` / `430px`

### K03-BUG-14 — Pet block 276 px vs the design's 236 px (Moderate)

The same mode renders a 260 px square nest; `PipNestFallback` is 276 px tall
instead of the design `.k3-pet` 236 px, shifting the whole lower stack down
(hearts ~505 instead of the ≈443 target). Same fix family as K03-BUG-13.

Failing test (skipped):
- `K03-BUG-14: the pet block keeps the design 236 px slot height`
  (`Expected within 2 of 236, Actual 276`).

### K03-BUG-15 — "Try again" stacks live stream subscriptions (Minor, new)

**Where:** `kid_home_bloc.dart` `_onLoadRequested` + the default
`watchHome()`/`switchMapStream` chain. Each failed load leaves its source
subscriptions live; the failure screen's "Try again" adds another chain.

**Repro (new proof):** a repository whose child/items streams error on
listen after being counted; add `KidHomeLoadRequested` three times on the
failure path. Actual: **peak = 3 concurrent source subscriptions** and
`active = 3` at the end, i.e. nothing is released; expected ≤ 2 (one child +
one items) with 0 live after the failure. This independently confirms review
finding 6 (the iteration-7 logic rewrite that fixed it was reverted).

Failing test (skipped):
- `K03-BUG-15: retry does not stack live stream subscriptions`
  (`Expected ≤ 2, Actual 3`).

Suggested fix: in `_onLoadRequested`, early-return while a load subscription
is live (the review's smaller alternative), or make `switchMapStream` cancel
its source/inner subscriptions when the consumer cancels after an error
(SHARED_REQUEST #14 — the helper sits in `domain/`).

## Fixed / verified this iteration

- **Iteration-7 UI landed and probed:** `NestBalancedText` renders the
  `.kid-title` with the 20 px left edge; quest tiles carry the per-quest
  tints (dishwasher `skyTint`, reading `lilacTint`, tidy `peachTint`, others
  neutral) — SHARED_REQUEST #1 closed; all three dock buttons have
  `wrapLabel: false` — SHARED_REQUEST #9 closed.
- **Earlier bugs 1–12 remain fixed and green** (period semantics, tap
  latches, celebration mapping, bottom edge light+dark, child order, fonts
  bundled with zero tracking, copy character-for-character).

## Carried items (owned elsewhere)

| Source | Severity | Item |
|---|---|---|
| 5_ui iteration 7 | Moderate | `NestSpeechBubble` is 46 px vs design 35 px — SHARED_REQUEST #15 |
| 5_ui iteration 7 | Moderate (dark only) | dark meadow band behind lower content still unverified (no simulator in this stage) |
| geometry pin | — | `kid_home_geometry_test.dart` stays skipped until SHARED_REQUEST #13 lands |

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| iteration-7 UI | balanced title + 20 px edge; per-quest tile tints; dock labels never wrap | pass |
| child order | `watchProfiles()` = Maya, Leo; six children in one second keep insertion order | pass |
| fonts | bundled Nunito, `letterSpacing: 0`, no `google_fonts` | pass |
| copy | strings match the HTML character-for-character | pass |
| bottom edge | light + dark surface to the physical edge under a 34px inset | pass |
| alignment | 20px gutters on bar, cards and dock | pass |
| periods | day/week boundaries, daily/weekly/once, BST switch days | pass |
| taps | same-frame double taps → one row / one route; silent no-op retry | pass |
| data edges | 0 / 1 / 6 children; long name + 9999 coins at 320/1.3; no `£` | pass |
| back nav / deep links / restart / guard / contrast / money / async gap | earlier probes | pass |

## Observations

1. Period rollover computes at stream-map time (no injectable clock).
2. Test wall-clock coupling (seed pinned, `DateTime.now()` not).
3. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
4. Static `PipAvatar` fallback omits accessories (no seed child equips one).

## Summary

| ID | Severity | Status |
|---|---|---|
| K03-BUG-13 | **Major (owner ALIGNMENT)** | **open (shared; SHARED_REQUEST #13, geometry pin)** |
| K03-BUG-14 | Moderate | **open (same fix family)** |
| K03-BUG-15 | Minor | **open (retry-stacked subscriptions; SHARED_REQUEST #14)** |
| K03-BUG-1..12 | Major..Moderate | fixed, proofs green |

The screen's functional behaviour remains in good shape (all iteration-1..6
fixes hold, the iteration-7 UI work is verified), but the pet slot is still
visibly off-centre at every width and clipped at 320 px — a major under the
owner ALIGNMENT rule — with the height knock-on and a small retry
subscription leak alongside it.

VERDICT: FAIL
