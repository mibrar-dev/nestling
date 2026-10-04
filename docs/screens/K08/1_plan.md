# K08 · Reward shop — build plan (stage 1)

Screen: K08 · feature `kid_shop` · route `/reward-shop` (`KidShopRoutePaths.shop`) · kid mode.
Sources (read, in full): `design/html-source/screens/K08-shop.html`,
`design/screens/light/K08-shop.png` + `design/screens/dark/K08-shop.png` (1170×2532 = 390×844 logical),
DESIGN_SPEC §5 K08, SPACING_SPEC §§2/4/7/10/11, `app/lib/features/kid_shop/**`,
`app/lib/core/data/{seed,app_database}.dart`, P14 `rewardIconSpecs` precedent,
K01/K02/K03 chrome + `KidHomeBloc` subscription-guard precedent.
No `docs/screens/K08/ORCHESTRATOR_NOTES.md` exists. No Pip slot in this design (text-only
“Pip” mention in footer) → PIP orchestrator rule needs no `PipAvatar`.

Copy below is transcribed character-by-character from the HTML (é U+00E9 in
“café”, periods, ’ none present). DB-vs-design deltas are flagged `DATA:`.

## (a) Widget tree, top → bottom (all sizes logical px; geometry from the HTML/CSS, visually cross-checked vs PNG/3)

Chrome (copy the K01/K02/K03 pattern exactly — `KidScope` + transparent `Scaffold`):

```
KidScope (shared sky gradient + 390×136 meadow hills, bottom 0; dark-only stars; NEVER local hills)
└ Scaffold(backgroundColor: transparent)
  └ Column
    ├ NestStatusBar()                                    // reserves 47; OS draws glyphs (ignore in UI checks)
    ├ Padding(20, 0, 20, 6)  [.k8-top: padding `0 20px 6px`]
    │ └ Row: NestIconButton(back, 'Back', size 56, iconSize 26,
    │          transparent bg+border)                     // .nav-back.lg 56×56 r18, chevron 26 stroke 2.5; shape invisible (transparent) — K02 precedent
    │        + Spacer + NestLockButton(large, semanticLabel 'Grown-ups')  // .lock-btn.lg 56×56 r18, surface/line, HTML aria-label "Grown-ups"
    ├ Expanded
    │ └ ListView(padding: 20,0,20,58)                    // .scroll sides 20; .k8-scroll bottom 34+24=58 clears home indicator
    │   ├ _ShopHead: Row(gap 10)
    │   │   ├ Expanded → NestBalancedText('Reward shop', style kidTitle 28/34 w900 ink, textAlign start)
    │   │   │                                                 // .kid-title has text-wrap:balance → NestBalancedText mandatory
    │   │   └ NestCoinPill.large(amount '$coins')              // .coin-pill.big: 20px, pad 10/16, coin 20, gap 6; label '$coins coins' built in
    │   │     Row height 40 → head band y ≈ 109…149 (status 0…47, top-row 47…109)
    │   ├ SizedBox(16)                                        // .scroll > * + * = 16
    │   ├ Text('Spend your coins on things you actually want.', kidCaption 15/20 w700 ink-2)  // .kcap; 1 line @390
    │   ├ SizedBox(16)
    │   ├ Column(gap 16): chunk items into pairs →
    │   │   IntrinsicHeight + Row per pair: Expanded(_ShopCard) + gap 16 + Expanded(_ShopCard)
    │   │     // 2 cols, gap 16, colW = (W−40−16)/2 = 167 @390 (compute from width, min 0; SPACING_SPEC §10.2).
    │   │     // IntrinsicHeight = CSS grid row stretch. Odd trailing card: Expanded + Spacer-equivalent (second Expanded with SizedBox.shrink).
    │   ├ SizedBox(16)
    │   └ Text(footer, kidCaption ink-2, center)               // .kcap.k8-foot: 'You have $coins coins. Pip is helping you save!' (DB coins)
    └ NestHomeIndicator()                                     // renders nothing in-app (mock-glyphs off); keeps gallery parity like K01/K03
```

`_ShopCard(item, coins)` — `Container(surface, border 3×ink, r 24, sh-kid, padding 10)`
+ bottom margin 6 so the 6 px kid shadow is never clipped (SPACING_SPEC §10.7);
`Column(mainAxisSize.min, center, gap 6)`:

1. `_ShopArt`: 56×56 circle (`tapKid`), bg `coinTint`, `NestIcon(mapped, size 32, coinInk)`, `ExcludeSemantics` (name+price carry the meaning). // `.k8-art`
2. Name: `ConstrainedBox(minHeight 40, Center(Text(maxLines 2, ellipsis, center)))`,
   style `h3(ink).copyWith(fontSize 15, height 19/15)` (Nunito w800 carried over). // `.k8-n 15/19 w800, min-height 40` = 2 lines (38 ≤ 40)
3. Price `Row(mainAxisSize.min, gap 4)`: coin svg 20 (`ExcludeSemantics`) + `Text('$price', coinPill(coinInk).copyWith(fontWeight w900))`. // `.k8-p 16/1 w900 coin-ink`; `softWrap false`
4. Iff `price > coins`: `Text('${price−coins} more to go', kidCaption(ink2).copyWith(fontSize 14, height 18/14), center)`. // `.k8-note`
5. `NestKidButton(label affordable ? 'Get it' : 'Save up!', color affordable ? leaf : white, minHeight 56, borderRadius 16, fontSize 17, fullWidth, semanticLabel affordable ? 'Get ${item.title}' : 'Save up for ${item.title}', onPressed affordable ? request : null, loading: requesting)` // `.k8-get min-h 56 r-m 16 17px`; off-style deviation → §(g)

Computed card height (no note): 10+56+6+40+6+20+6+56+10 = 204 + 6 border = 210.
Row 1 y ≈ 201…411; row 2 ≈ 427…637; row 3 (café has note: +18+6 → 234) ≈ 653…887 → scrolls (matches PNG: row 3 cut by viewport). Footer below row 3.

Icon map (screen-private `const` in widgets, NOT P14's map — documented delta):
`tv→screenTime, film→filmStrip, moon→moon, cake→chefHat, coffee→cafe, plate→pizza`, fallback `gift`.
Rationale: K08 HTML draws the film-strip (side sprockets) and crescent-moon glyphs;
`nestling_assets.dart` annotates `filmStrip`/`moon` as the K08 glyphs, while P14's
`rewardIconSpecs` maps `film→film` / `moon→clock` for the parent cards. Keep both maps;
do not “unify” (would break one screen's fidelity).

DATA deltas (database wins; never hard-code): (1) order = creation order
`r-screen 50, r-film 80, r-bedtime 60, r-baking 100, r-cafe 150, r-dinner 90`
(design order ≠ price order); (2) r-cafe title is `Trip to the park café` in DB vs
`Park café trip` in HTML/PNG — render `r.title`; (3) coins/pill/footer from child row
(Maya 120, matches design); (4) `affordable = coins >= coinPrice` (only r-cafe false
at 120 → `30 more to go`, exactly the HTML).

Bottom-edge owner rule: no bottom bar on K08 (list runs to edge over meadow) — nothing to paint; FAIL if any surface strip appears under the scroll.
Alignment: 20 px gutters on top row, scroll, footer; grid (W−40−16)/2 columns.

## (b) BLoC + repository (local Drift, existing repo — no schema/seed changes)

State (extend `KidShopState`): `{ status, childId ('' until first emission), coins (0), items ([]) ,
requestingIds (Set<String>, {}), notice (String?), noticeSeq (int 0), errorMessage }`.

Events:
- `KidShopLoadRequested` — guarded manual subscription (K03-BUG-15 precedent from
  `kid_home_bloc.dart:27-83`: `watchActiveShop()` never completes, so `await emit.forEach`
  would hang the handler and deadlock later tap events — the CURRENT bloc has this latent
  bug and must be rewritten, not extended). `if (_sub == null) { emit(loading); _sub =
  repo.watchActiveShop().listen((d) => add(KidShopDataReceived(d)), onError: release + add(KidShopStreamFailed(e))); }`
- `KidShopDataReceived(KidShopData)` → `loaded(childId, coins, items)` (preserves `notice*`).
- `KidShopStreamFailed(Object)` → `failure`.
- `KidShopRewardRequested(rewardId)` — ignore when `!loaded`, id unknown, unaffordable,
  or already in `requestingIds` (double-tap guard). Else `requestingIds + id`, then
  `await repo.requestReward(childId, rewardId)`; on success `requestingIds − id` +
  `notice = needsOk ? 'Mum will give it a thumbs-up soon.' (reused K05 wording) : 'It’s yours — enjoy!' (builder copy, em dash U+2014, curly ’ U+2019)` with `noticeSeq+1`;
  on error `requestingIds − id` + `notice = 'Hmm, that did not work. Try again.'` (K03-reviewed wording), `noticeSeq+1`.
- `KidShopNoticeShown` — clears `notice` (view's `BlocListener` shows `showNestToast` when `noticeSeq` changes, then adds this).

Repository (feature-owned `domain`+`data`, RULES §1 — no shared edits):
- New entity `KidShopData { childId, coins, items }`.
- New `Stream<KidShopData> watchActiveShop()`: `watchAppState()` → `activeChildId ?? 'maya'`
  (demo seed sets `activeChildId='maya'`) → `combineLatest2(watchRewardsInCreationOrder(family),
  watchChild(id))` → items in CREATION order with `affordable`. Replaces the current
  `watchItems/watchShop` (price-order `watchRewards` — wrong order for K08; `watchRewardsInCreationOrder`
  doc names K08 explicitly). Builder: verify no other callers, then delete the superseded methods.
- `requestReward` unchanged (needsOk → `requested`, coins untouched; else `approved` + deduct; unknown id no-op).

## (c) Interactions → navigation (route constants only)

- Back (`NestIconButton`) → `if (context.canPop()) context.pop() else context.go(KidHomeRoutePaths.home)` (`/kid-home`; K02 precedent `kid_pin_view.dart:191-197`). Semantics tap ✓.
- Lock (`NestLockButton 'Grown-ups'`) → `_busy` tap guard + `await context.push(ParentalGateRoutePaths.gate)` (`/parental-gate`; K03 `_GateLockButton` pattern — one gate per gesture burst). Semantics tap ✓.
- `Get it` (affordable) → `KidShopRewardRequested(id)`; button shows `loading` spinner while its id ∈ `requestingIds`; toast on completion (§b). Coins/pill/footer update via stream (instant rewards). Semantics tap drives real DB write ✓.
- `Save up!` (unaffordable) → disabled (`onPressed null`, `enabled:false`, no tap action).
- No other navigation (no detail screen, no CTA, no dock on K08).

## (d) Empty / loading / error

- Loading (initial + guarded reload): chrome + `Center(CircularProgressIndicator(leaf))`, `Semantics(label 'Loading rewards')` (K01 pattern).
- Loaded empty (`items.isEmpty` — wiped rewards / fresh family): chrome + `NestEmptyState(art: NestIcon(gift, 96, ink3) [P14 precedent], title 'No rewards yet' [P14 RewardCopy.emptyTitle], message 'Ask a grown-up to add something coins can buy.' [BUILDER COPY — no design source; kid voice], no action — kid cannot add)`.
- Failure: chrome + gift art + `'Something went wrong'` [P14 `RewardCopy.loadError`] + `NestKidButton.white('Try again')` → re-adds `KidShopLoadRequested` (sub was released on error, guard lets it through). No Pip art anywhere (avoids contradicting the PIP rule; P14-copy failure avoids inventing voice).

## (e) Accessibility

- Every control named + tappable: Back / Grown-ups / `Get $title` / `Save up for $title` (disabled, `enabled:false`); `getSemanticsData().hasAction(tap)` true for all enabled, `performAction(tap)` performs the real nav/DB write (test asserts).
- No `Semantics(excludeSemantics:true)` wrapper without `onTap:` — only inside `Nest*` components (handled) and decorative art (excluded, non-interactive).
- Targets: 56 back / 56 lock / 56 full-width buttons (kid minimum 56 ✓).
- Text scale 1.3 + width 320: `ListView` scrolls; name 2-line ellipsis; balanced title; computed columns (132 @320, art 56 + price fit); pill/labels `softWrap false` + ellipsis parents; `textScaler` clamp 1.0–1.3 is app-wide.
- Contrast: token pairs only (coinInk/coinTint, ink2 captions — design-system audited).

## (f) Test plan (`app/test/features/kid_shop/`, `--timeout 120s`, clock pinned Sat 3 Oct 2026, no `DateTime.now`, no `google_fonts`, `disposeApp` after every pump)

- `kid_shop_bloc_test.dart`: loaded emits Maya coins 120 + 6 items in creation order with `r-cafe.affordable=false`; `RewardRequested` (needsOk) → repo called, `requestingIds` transient, noticeSeq 1 + thumbs-up copy; instant (`r-baking`) → enjoys copy; unaffordable/unknown/duplicate ignored; stream error → failure → retry reloads.
- `kid_shop_repository_test.dart` (in-memory Drift + `Seed.demo`): creation order + affordable flags; `requestReward` needsOk → `reward_redemptions` row `requested`, coins unchanged; `!needsOk` → `approved` + coins −100; unknown reward no-op.
- `reward_shop_view_test.dart` (`pumpAppRoute('/reward-shop')`, light + dark): `Reward shop` + pill `120`; all six DB titles incl. `Trip to the park café`; café card `Save up!` + `30 more to go`; footer `You have 120 coins. Pip is helping you save!`; semantics-tap `Get …` writes a redemption; back → `/kid-home`; lock → `/parental-gate`; every control `hasAction(tap)`; 1.3 text + 320 width pumps without overflow; geometry test: top-row y 47…109, head ≈109…149, grid starts ≈201, colW 167, card min-h 210, note row taller — all ±2 vs CSS (DB text excluded).

## (g) SHARED_REQUEST

One, NON-BLOCKING (`docs/screens/K08/SHARED_REQUEST.md` to file in build stage):
`NestKidButton` off-variant for `.k8-get.off` (bg `surface-2`, fg `ink-2`, full opacity,
3 px ink border + sh-kid kept). Fallback the builder uses meanwhile: `NestKidButton.white`
with `onPressed: null` (surface/ink @45 % disabled). Blocks: no.
Nothing else shared: order fix, `KidShopData`, icon map, copy are all feature-local.

VERDICT: PASS
