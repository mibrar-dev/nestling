# K08 Reward shop — bug hunt (Stage 6, iteration 2)

Adversarial pass over `kid_shop` / `/reward-shop` after iteration 2's build:
data edges (0/1/6 children, long UK names, 0 and 9999 coins, empty lists),
rapid double taps, back navigation and deep links, restart persistence,
parent/kid mode guards, dark mode, 320 px + 1.3 text scale, async gaps,
Europe/London/BST, integer coins, the new audience icon rule, owner rules,
accessibility actions and the ±2 px UI rule. No screen code was changed in this
stage. No simulator was used (only `5_ui` may use E7D5555E-378A-49DF-AAEE-16677AF4B9DB).

- Suite: `app/test/features/kid_shop/k08_bugs_test.dart` — 8 tests:
  7 run green (the iteration-1 proofs, now fixed) and 1 skipped (`K08-BUG-4`).
- Run the green suite:
  `cd app && flutter test --timeout 120s test/features/kid_shop/k08_bugs_test.dart`
- Run K08-BUG-4's proof (fails on the current code, on purpose):
  `cd app && flutter test --run-skipped --timeout 120s --plain-name K08-BUG-4 test/features/kid_shop/k08_bugs_test.dart`
- Full feature suite (including the test stage's new `shop_reward_icons_test.dart`,
  which pins the audience glyph rule):
  `flutter test --timeout 120s test/features/kid_shop/` → **150 pass, 1 skip,
  0 fail**; the single skip is this stage's K08-BUG-4 proof.

## Iteration-1 bugs — all fixed and verified

| ID | Severity | Fix landed in iteration 2 | Proof |
|---|---|---|---|
| K08-BUG-1 | Major (money) | `requestReward` makes payment a precondition of the `approved` row inside the single transaction (`kid_shop_repository_impl.dart:78-118`); a balance that no longer covers the price (or a missing child row) leaves the row `requested` instead of unpaid `approved` | green |
| K08-BUG-2 | Major (crash) | `_ShopGrid`'s odd filler is `const SizedBox.shrink()`, not `Spacer` (`reward_shop_view.dart:352-359`) | green |
| K08-BUG-3 | Minor (a11y) | `_ShopPrice` wraps the row in `Semantics(label: '$price coins', container: true, excludeSemantics: true)` (`shop_reward_card.dart:201-206`) | green |
| UI icon deviations | Major (UI check) | `shop_reward_icons.dart` forwards to the shared `rewardIconFor(key, audience: NestAudience.kid)` per `ORCHESTRATOR_NOTES` (14:31/15:08) | pinned by the test stage's new `shop_reward_icons_test.dart` |

The proofs for the three bugs are kept in `k08_bugs_test.dart` and now run
**un-skipped and green** (7 tests), so a regression re-opens them.

## Open bugs

### K08-BUG-4 — A reward left awaiting approval is announced as already owned (Minor)

**Severity: Minor (kid-facing copy).** The K08-BUG-1 fix correctly leaves a
raced instant reward `requested` when the balance no longer covers it, but the
bloc still toasts from the `needsOk` flag captured at tap time, so the child is
told “It’s yours — enjoy!” for a reward that is actually waiting for a grown-up.
The row status and the coins are correct; only the copy is wrong. The stage-2
integrator recorded this edge as accepted (`2_build.md` lines 33-39); this stage
records it as an open minor with a failing proof because the screen has no other
way to tell the child the request is pending.

Root cause: `KidShopRepository.requestReward` returns `Future<void>`
(`domain/kid_shop_repository.dart:13`), so `KidShopBloc._onRewardRequested`
cannot know that the repository wrote `requested` instead of `approved`; it
toasts from `item.needsOk` (`kid_shop_bloc.dart:99-106`).

Repro:
1. `Seed.demo`; set `r-screen.needsOk = false`; open `/reward-shop` (Maya has
   120 coins).
2. Tap “Get 30 min extra screen time” (50) and “Get Baking together” (100) in
   one frame — both cards are individually affordable.
3. Observed rows: `r-screen:approved`, `r-baking:requested`. The first toast
   (approved) is honest; after its 3 s snackbar, the second toast — for the
   `requested` row — still reads “It’s yours — enjoy!”.
4. Expected: the toast for a `requested` row reads “Mum will give it a
   thumbs-up soon.” (or the request fails with the existing
   “Hmm, that did not work. Try again.” toast).

Failing test (skipped so the suite stays green):
- `K08-BUG-4 — a raced request is announced as already owned a reward left awaiting approval is not announced as "yours"`
  (`Expected: no matching candidates / Actual: Found 1 widget with text
  "It’s yours — enjoy!"` while the last redemption is `requested`).

Suggested fix (feature-local: domain + data + bloc): make `requestReward`
return the status it wrote — e.g. `Future<String>` (`'approved'`/`'requested'`)
or a small enum — and have the bloc toast from that outcome instead of from
`needsOk`. Alternative: when the balance is short, throw so the existing
failure toast fires and no `requested` row is created; but the fallback row is
the kinder behaviour, so returning the outcome is preferred.

## Verified clean this iteration (new adversarial probes)

| Category | Probe | Result |
|---|---|---|
| money: concurrent repo writes | `Future.wait` of two instant requests (100 + 50 at 120 coins) → exactly one `approved` (100) and one `requested`; coins never negative; approved value ≤ spent | pass |
| money: burst | all six rewards instant, six concurrent requests on 120 coins → approved value **equals** coins spent (120), no overdraft, no unpaid approval | pass |
| money: three cards, one frame | r-screen + r-film + r-baking tapped before any rebuild → invariant holds (`approvedValue ≤ spent`) | pass |
| money: exact price | 100 coins, “Baking together” (100) → `approved`, coins exactly 0 | pass |
| rapid double tap, same card | unchanged: one row, one deduction | pass (test stage) |
| odd reward counts | 1 and 5 rewards render with the empty grid cell; widths 167/132 at 390/320 | pass |
| price accessibility | price announces “50 coins”, its own node, name/button labels unaffected | pass |
| restart (Drift persistence) | buy “Baking together”, re-open the app → 20 coins and the new affordabilities | pass |
| icons | shared kid-audience glyphs resolve for all six seeded keys; fallback `gift` | pass (new icons test) |
| 0 children | children deleted, rewards left → chrome intact, no crash (shared fallback; observation 1) | pass |
| 0 coins / empty rewards / 9999 coins @ 320+1.3 / long titles / text scale 2.0 / dark mode / leave mid-request / double-tap Back | unchanged from iteration 1, still green in the feature suite | pass |

## Observations (unchanged, not defects)

1. **0 children / deleted active child**: `watchActiveShop` falls back to the
   literal `'maya'` (`kid_shop_repository_impl.dart:26`); the chrome stays and
   no write is reachable (P14 enforces min price 5, so no 0-price reward can
   exist). Repo-wide convention (`kid_jar`, `pip`, `pocket_money`, `badges`).
2. **Parent-mode deep link `/reward-shop`** renders the kid screen (only
   parent-only routes are guarded from kid mode, not the reverse). Shared
   product-level question, same as K03's note.
3. **Pluralisation**: at 1 coin the footer and pill announce “1 coins”
   (app-wide “N coins” convention). Cosmetic.
4. **£0.00 / £999.99 / rounding**: N/A — K08 is coins-only, integer coins
   throughout, never formats £.
5. **Europe/London / BST**: K08 shows no dates or times; `requestReward` stores
   a UTC instant + the family zone id (`appNowUtc` + `familyZoneId`). Nothing to
   break at a DST boundary.
6. **`.k8-get.off`**: the unaffordable “Save up!” button still uses the
   `NestKidButtonColor.white` + `Opacity(0.45)` fallback instead of the design's
   flat `surface-2`/`ink-2`; tracked, non-blocking, in `SHARED_REQUEST.md` §1.
7. **Stale “success” toast for a reward deleted between emission and tap** is
   unreachable on a single-device app (parent and kid modes are exclusive).

## Summary

| ID | Severity | Status |
|---|---|---|
| K08-BUG-1 | Major (money integrity) | fixed iteration 2 — proof green |
| K08-BUG-2 | Major (odd counts crash the grid) | fixed iteration 2 — proof green |
| K08-BUG-3 | Minor (price a11y) | fixed iteration 2 — proof green |
| K08-BUG-4 | Minor (toast honesty in the K08-BUG-1 fallback) | **open — 1 skipped proof** |

No major bugs remain open. The iteration-1 money and crash defects are fixed
and covered by un-skipped proofs; the one new finding is a minor, child-facing
copy issue in a raced fallback, recorded with a failing test and a feature-local
fix.

VERDICT: PASS
