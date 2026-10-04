# K08 Reward shop — bug hunt (Stage 6, iteration 3)

Adversarial pass over `kid_shop` / `/reward-shop` after iteration 3's build
(K08-BUG-4's outcome-based toast, K08-BUG-5's per-name semantics nodes, the
`.k8-get.off` switch to the shared `NestKidButtonColor.muted`, and both
`SHARED_REQUEST` items closed on `shared_batch8`). Hunted: data edges
(0/1/6 children, long UK names, 0 and 9999 coins, empty lists), rapid double
taps, back navigation and deep links, restart persistence, parent/kid mode
guards, dark mode, 320 px + 1.3 text scale, async gaps, Europe/London/BST,
integer coins, the audience icon rule, owner rules, accessibility actions and
the ±2 px UI rule. No screen code was changed in this stage. No simulator was
used (only `5_ui` may use E7D5555E-378A-49DF-AAEE-16677AF4B9DB).

- All bug proofs now run **un-skipped and green** — nothing is skipped in the
  feature's tests.
- `app/test/features/kid_shop/k08_bugs_test.dart` — 9 tests, all green: the
  K08-BUG-1/2/4 proofs plus this stage's two post-fix invariants (the
  return-status contract and the concurrent-request money invariant).
- `app/test/features/kid_shop/shop_reward_a11y_test.dart` — 7 tests, all
  green: the K08-BUG-3 price node, the K08-BUG-5 per-name nodes, and the
  button / coin-pill tree.
- Feature suite: `flutter test --timeout 120s test/features/kid_shop/` →
  **168 pass, 0 fail, 0 skips**.
- Whole app (iteration-3 build, after `shared_batch8`):
  `flutter test --timeout 120s` → **3795 pass, ~4 skip (pre-existing kid_home
  matrix), 0 fail**.

## All five bugs fixed — final state

| ID | Severity | Fix | Proof |
|---|---|---|---|
| K08-BUG-1 | Major (money) | `requestReward` makes payment a precondition of the `approved` row inside one transaction; a short balance leaves the row `requested`; concurrent transactions serialize on the balance | green — `k08_bugs_test.dart` |
| K08-BUG-2 | Major (crash) | `_ShopGrid`'s odd filler is `const SizedBox.shrink()`, not `Spacer` | green — `k08_bugs_test.dart` |
| K08-BUG-3 | Minor (a11y) | `_ShopPrice` wraps the row in `Semantics(label: '$price coins', container: true, excludeSemantics: true)` | green — `shop_reward_a11y_test.dart` |
| K08-BUG-4 | Minor (copy) | `requestReward` returns the status it wrote (`Future<String?>`); `_onRewardRequested` toasts `approved` → “It’s yours — enjoy!”, anything else → “Mum will give it a thumbs-up soon.”, `null` → the retry copy | green — `k08_bugs_test.dart` |
| K08-BUG-5 | Minor (a11y) | `.k8-n` name and `.k8-note` each carry `Semantics(container: true)`, so every card's name is its own announcement instead of one grid-wide run | green — `shop_reward_a11y_test.dart` |

## Iteration-3 verification (independent probes, all green)

| Probe | Result |
|---|---|
| return contract: instant + covered → `'approved'` + deduction; instant + short balance → `'requested'` + no deduction; unknown id → `null` + no row; rows match the returned statuses | pass (now pinned in `k08_bugs_test.dart`) |
| **concurrency**: all six rewards made instant, six `Future.wait` requests on 120 coins → transactions serialize, `approvedValue == coins spent`, balance never negative, approved count == returned `'approved'` count | pass (now pinned) |
| `.muted` disabled “Save up!”: `SemanticsAction.tap` absent, `enabled:false`, still reported as a button (full opacity is the design's disabled look) | pass |
| per-name nodes: each of the six titles is its own semantics node and carries no other card's title; the café price (“150 coins”) and note (“30 more to go”) keep their own nodes | pass |
| prior-iteration probes (0 children, 0 coins, 9999 coins @ 320/1.3, long titles, text scale 2.0, dark mode, restart, leave mid-request, double-tap Back, same-card double tap) | pass — feature suite |

No new defect was found this iteration.

## Observations (unchanged, not defects)

1. **0 children / deleted active child**: `watchActiveShop` falls back to the
   literal `'maya'` (`kid_shop_repository_impl.dart`); chrome stays, no write
   is reachable (P14 enforces min price 5). Repo-wide convention (`kid_jar`,
   `pip`, `pocket_money`, `badges`).
2. **Parent-mode deep link `/reward-shop`** renders the kid screen (only
   parent-only routes are guarded from kid mode, not the reverse). Shared
   product-level question, same as K03's note.
3. **Pluralisation**: at 1 coin the footer and pill announce “1 coins”
   (app-wide “N coins” convention). Cosmetic.
4. **£0.00 / £999.99 / rounding**: N/A — K08 is coins-only, integer coins
   throughout, never formats £.
5. **Europe/London / BST**: K08 shows no dates or times; `requestReward`
   stores a UTC instant + the family zone id. Nothing to break at a DST
   boundary.
6. **Stale “success” toast for a reward deleted mid-flight**: fixed by
   K08-BUG-4's outcome contract (the repository returns `null`, the bloc shows
   the retry copy, no row is written). Kept here only as history.

## Summary

| ID | Severity | Status |
|---|---|---|
| K08-BUG-1 | Major (money integrity) | fixed iteration 2 — proof green |
| K08-BUG-2 | Major (odd counts crash the grid) | fixed iteration 2 — proof green |
| K08-BUG-3 | Minor (price a11y) | fixed iteration 2 — proof green |
| K08-BUG-4 | Minor (toast honesty in the payment fallback) | fixed iteration 3 — proof green |
| K08-BUG-5 | Minor (merged reward-name announcements) | fixed iteration 3 — proof green |

No bug is open. The money invariant holds under sequential, one-frame and
fully concurrent requests; odd reward counts render; the card price, name and
note are individually announced; the disabled “Save up!” keeps its design
colourway and offers no tap. Feature suite 168/168 green, whole-app suite
3795 pass / 0 fail.

VERDICT: PASS
