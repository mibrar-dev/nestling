# K08 · Reward shop — QA code review (stage 4, iteration 1)

Review of `git diff main...HEAD` (kid_shop feature, its tests, docs/screens/K08)
against docs/ARCHITECTURE.md, docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K08,
docs/design/SPACING_SPEC.md, the shared design system, and the orchestrator rulings.
~1,550 lines of K08 code/tests, no shared files touched.

## Scope compliance (RULES §1)

- Only `app/lib/features/kid_shop/**`, `app/test/features/kid_shop/**`,
  `docs/screens/K08/**` changed. No edits to `app/lib/core/**`, `app/lib/app/**`,
  another feature's directory, or `tools/screens/**`. VERIFY VIA:
  `git diff main...HEAD --stat` — 100% feature-local.
- The one cross-directory need (`watchShop` kept on `KidShopRepositoryImpl` for the
  shared `test/core/data/repositories_test.dart`) is documented in the repo impl
  doc-comment and keeps the public interface exactly per 1_plan §(b). Correct call.
- `SHARED_REQUEST.md` exists with the two known items filed (kid-button off variant;
  stale K03 placeholder-copy assertions).
- No `analysis_options` weakening, no `google_fonts`/`GoogleFonts`, no `flutter clean`,
  no `DateTime.now()` in app code (clock via `appNowUtc()`), test timeouts documented
  (`--timeout 120s`), seeds pinned to Sat 3 Oct 2026.

## Architecture (docs/ARCHITECTURE.md)

- Feature-first: domain holds entities + the abstract repository only;
  `KidShopData` is a pure Equatable value object; no use-case classes added.
- One bloc (`KidShopBloc`), one repository, DI/routes unchanged (bloc/repo
  registrations still match). Views wrap a single route (`RewardShopView`).
- The rewritten load handler fixes a real latent deadlock the old code had
  (`await emit.forEach` on a never-completing watch stream) using the K03-BUG-15
  subscription-guard pattern; reload-while-live is ignored, error releases the
  subscription so the failure card's "Try again" can re-subscribe, and `close()`
  cancels it. Correct.

## Design system usage

- All colours/typography/radii/shadows via tokens (`context.nest`, `NestType`,
  `NestSpacing`, `NestRadii`, `tokens.kidShadow`); no hex/`Color(` literals;
  shared `KidScope` + `NestMeadowPainter` for sky/hills exactly as the CSS places
  them (bottom 0, 390×136); no local hills.
- CSS-derived magic sizes (56 chevron row, 26 back icon, 56/32 art, 20 coin, …)
  carry a comment citing the HTML line — acceptable within this codebase's spec
  style. Buttons/pills/empty states are the shared `Nest*` components.

## Findings

1. **minor — assistive voice reads a bare price number.** `_ShopPrice` renders
   `SvgPicture(coin)` + `Text('$price')` with the icon `ExcludeSemantics`d and no
   label on the text (`app/lib/features/kid_shop/presentation/widgets/shop_reward_card.dart:189-217`).
   VoiceOver therefore announces only "50"/"150" with no unit. Contrasts with
   `NestCoinPill` which labels `'$amount coins'`
   (`app/lib/core/design_system/components/nest_coin_pill.dart:64`) and with
   P14's explicit `priceLabel = 'Price in coins'`
   (`app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart:107`).
   Fix: give the row `Semantics(label: '$price coins')` (merging the two children
   and already excluding the icon), and keep `Text` out of the a11y tree via
   `excludeSemantics`/explicit merge. Same for the "N more to go" note if present.

2. **minor — `.k8-get.off` deviates from the design.** The unaffordable "Save up!"
   button uses `NestKidButtonColor.white` + `onPressed: null`, so the whole control
   is wrapped at `Opacity(0.45)` (`app/lib/core/design_system/components/nest_kid_button.dart`,
   `enabled ? 1 : 0.45`), whereas the design wants a flat, full-strength
   `surface-2`/`ink-2` block (`K08-shop.html:29-30`). Already tracked as
   non-blocking in `docs/screens/K08/SHARED_REQUEST.md` §1 with a one-line swap
   plan. Recording here so the deviation survives to the UI check; not a reason
   to block iteration 1.

3. **note (not a K08 finding) — two stale assertions in another feature.**
   `app/test/features/kid_home/kid_home_view_test.dart:2001` and `:2059/2077`
   still assert the old placeholder copy `'K08 Reward shop'` and fail on this
   branch. It is outside K08's editable surface and filed in
   `SHARED_REQUEST.md` §2 with a 2-line fix (route assertion, already used at
   :1982-1983). No K08 code change can or should satisfy it.

## Design spec §5 K08 compliance

- Title "Reward shop", coin-pill balance, intro line, two-column grid (167 @390,
  16 gutter), per-card icon/name/price/button, "Get it" vs "Save up!", single
  "N more to go" note on the unaffordable card, and the footer line are all
  present and character-identical to `design/html-source/screens/K08-shop.html`
  (verified: "Spend your coins on things you actually want.", "You have … coins.
  Pip is helping you save!", "more to go", curly apostrophes/em dash in the
  toast copy "It’s yours — enjoy!", "Mum will give it a thumbs-up soon.").
- Data over mocks honoured: six rewards in creation order from the DB
  (`r-screen, r-film, r-bedtime, r-baking, r-cafe, r-dinner`), DB title
  "Trip to the park café" wins over the HTML's "Park café trip", live coin
  balance, `affordable` computed from the child row — no hard-coded design
  numbers in app code.
- Non-shaming disabled style ("Save up!", full-opacity-intent note, no lock
  badge) matches the spec's intent. PIP rule N/A (no Pip slot; footer is text).
- Bottom edge: no bar of its own, list scrolls over the shared meadow to the
  physical edge, no strip — owner rule satisfied. 20 px gutters consistent
  (top row, list, footer); geometry test asserts 201/433/665 rows, 167 columns,
  56 pt buttons, centred art.

## Accessibility (§8)

- Every enabled control exposes `SemanticsAction.tap` and tapping performs the
  real behaviour (view tests assert `hasAction(...)` for Back / Grown-ups /
  "Get <title>" and disabled `enabled: false`, no-tap for "Save up for …").
- Excluded art/icons are non-interactive; no `excludeSemantics` wrapper without
  `onTap`. Kid target sizes ≥56 via `--tap-kid` equivalents. Findings 1 is the
  only gap.

## Performance / lifecycle

- One stream subscription per bloc (guarded reload), cancelled on error and on
  `close()`; `_switchMap` cancels inner on every outer emission and both on
  cancel. No `Timer`/animation controllers; `DISABLE_ANIMATIONS` respected via
  the shared motion fallbacks (unused here anyway). Chrome (`KidScope`, status
  bar, top row) is a separate widget from the `BlocBuilder` body — no rebuild
  storm; toast via `BlocListener` keyed on `noticeSeq`, survives stream
  emissions, no repeated toasts of identical text because the sequence bumps.

## Error handling

- Repository lookup failures → failure body with "Try again" re-subscribe;
  `requestReward` misses → honest toast, spinners cleared, no silent success.
  View handles loading / loaded / empty / failure in every chrome state.

## Children's Code

- Kid mode screen: no analytics, ads, remote loads, or external storage; a tap
  only inserts a `reward_redemptions` row via the feature repository.

## Verdict

No blocker or major findings. Two minor items (1: price a11y label; 2: filed
off-variant deviation) and one cross-feature note (3) recorded. K08 code is
feature-local, spec-faithful, and fully covered by the 53 kid_shop tests plus
the shared-suite confirmations logged in `2_build.md`.

VERDICT: PASS
