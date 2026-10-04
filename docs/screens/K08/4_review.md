# K08 · Reward shop — QA code review (stage 4, iteration 2)

Review of `git diff main...HEAD` after the iteration-2 build (merge of
`main` brought `shared/audience_glyphs` — K08 now forwards to
`rewardIconFor(audience: NestAudience.kid)`; the K08-BUG-1/2/3 fixes plus the
`.k8-get.off` UI state were applied). Scope clean: delta is `kid_shop` feature
code, `test/features/kid_shop/**`, and `docs/screens/K08/**` only.

## Architecture (docs/ARCHITECTURE.md)

- Feature-first shape maintained: domain = `KidShopData` entity + abstract
  `KidShopRepository` (`watchActiveShop`/`requestReward`); data holds the Drift
  impl; presentation holds one bloc per screen with
  Initial/Loading/Loaded/Failure; routes/DI still per-feature, no cross-feature
  nesting. VERDICT: PASS on structure.
- BLoC: guarded manual subscription (K03-BUG-15), `close()` cancels `_sub`;
  `KidShopDataReceived`/`KidShopStreamFailed` internal events only.
  `KidShopRewardRequested` still rejects unknown/unaffordable/duplicate ids.
- Iteration-2 repository fix mirrors P14's `approveRedemption` pattern:
  balance-check-then-write inside one transaction. Data invariant restored.
- `watchShop` kept on the impl (documented) for the shared foundation test.

## RULES / design system / spec

- Edited only allowed paths (verified `--name-status`).
- No hard-coded colours/sizes/fonts in K08 UI — tokens everywhere;
  `NestKidButton`, `NestCoinPill`, `NestEmptyState`, `KidScope`,
  `NestBalancedText`, `NestIconButton` reused, not re-implemented.
- `shop_reward_icons.dart` is now a thin forwarder to shared
  `rewardIconFor(..., audience: NestAudience.kid)` — satisfies the ICONS
  orchestrator ruling; both audience branches match their own design SVGs.
- §5 K08 copy verified char-by-char against the HTML: "Reward shop", intro,
  "Get it"/"Save up!", "N more to go" format, footer with live balance;
  DB-driven six rewards in creation order; no hard-coded design numbers.
- UK spelling/formatting in copy. BALANCED headings via `NestBalancedText` —
  kept from iteration 1, unchanged.

## Accessibility

- BUG-3 fix verified: `_ShopPrice` now `Semantics(label: '$price coins',
  container: true, excludeSemantics: true)` around the row
  (`shop_reward_card.dart:198-231`), so each card announces "50 coins"
  instead of a bare "50". Tests assert the unit.
- All buttons expose tap actions; "Save up!" disabled state reports
  `enabled: false` with no tap action (correct per §8).
- Decorative art is `ExcludeSemantics`; no `excludeSemantics` wrapper
  without `onTap`.

## Performance / lifecycle

- Streams disposed on cancel/error/close; `_switchMap` cancels both on
  `onCancel`; BlocBuilder scope is the routed body only; toast via
  `BlocListener` keyed on `noticeSeq`. BUG-2 crash fixed — grid no longer
  nests `Expanded(Spacer())`; odd counts lay out (`const SizedBox.shrink()`).

## Error handling / data integrity

- Stream failure → explicit failure body + retry; request failure →
  honest toast. BUG-1 fix: unpaid instant purchases no longer write
  `approved`; an uncovered `KidShopRewardRequested` now writes a `requested`
  row inside the same transaction instead of an unpaid `approved` row.

## Findings

1. **minor** — Instant purchase feedback can mismatch the stored row. When
   the repo downgrades an uncovered instant tap to `requested`
   (`kid_shop_repository_impl.dart:88-112`), the bloc still answers with the
   instant-purchase copy "It’s yours — enjoy!"
   (`kid_shop_bloc.dart:103-104`). The kid hears "it's yours" while the row
   actually needs parental approval. Fix: have `requestReward` return the
   resulting status (`'approved' | 'requested' | 'requested_only'`) (a tiny
   API addition stays inside RULES §1 — domain-owned contract), and map it in
   `_onRewardRequested`: `approved` → enjoy copy, `requested` → thumbs-up
   copy, balance-refused → a "Not quite enough coins yet — keep saving!"
   toast.

2. **minor** — `app/test/features/kid_shop/k08_bugs_test.dart:3-27` header
   comment still describes K08-BUG-1/2/3 as failing "on this tree". Those
   fixes have landed and the same tests pass as regression proofs. Fix:
   update the header to state they ran failing in iteration 1 and now guard
   the fixed behavior.

3. **note (recorded deviation, tracked)** — `.k8-get.off` still uses
   `NestKidButtonColor.white` + `onPressed: null`, so the disabled "Save
   up!" is the whitened 0.45-opacity variant rather than the design's flat
   `surface-2`/`ink-2` block. Filed in `docs/screens/K08/SHARED_REQUEST.md`;
   swap is one prop once the design-system owner adds the muted variant.

4. **note (cross-feature, shared-owned)** — two stale placeholder-copy
   assertions remain in `app/test/features/kid_home/kid_home_view_test.dart`
   (:2001 and the table row in the :2059 group). Outside K08's editable
   path; fix is filed in `SHARED_REQUEST.md`.

## Children's Code

- No analytics, ads, tracking pixels, or external loads in kid mode; taps
  only insert `reward_redemptions` rows via the feature repository. PASS.

## Verification evidence

- `flutter analyze` → "No issues found!" (no ignores, no weakened
  analysis_options).
- `flutter test --timeout 120s test/features/kid_shop/` → all pass
  (143 tests, incl. the BUG-1/2/3 regression proofs).
- No simulator used in this stage; no code edited per stage instructions.

VERDICT: PASS
