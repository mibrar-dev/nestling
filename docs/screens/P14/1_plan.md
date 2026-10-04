# P14 · Rewards manager — build plan (Stage 1)

Route `/rewards` (feature `rewards`, parent mode). Sources: `design/html-source/screens/P14-rewards.html`
(authoritative for copy/geometry), `design/screens/light|dark/P14-rewards.png` (÷3 → logical px),
DESIGN_SPEC §5 P14, SPACING_SPEC §§2–3/8–11. Existing code is placeholder scaffolds only
(`RewardsView` AppBar + ListTile, `RewardsBloc` with `RewardsLoadRequested` only) — the builder
replaces the view/widgets/bloc-events/state in place. No shared code is touched.

## 0. Orchestrator overrides applied

- No Pip on this screen — PIP rule N/A.
- `NestStatusBar` reserves 47 px only; ignore status-bar glyph differences in UI checks.
- DATA OVER MOCKS: list comes from `Seed.demo()` via Drift `watchRewards` (6 rows, price order
  50/60/80/90/100/150 — see §4). The design shows 5 rows in HTML order 50/80/60/100/150; the DB
  order and the 6th row (`Choose dinner`, 90) win. All `needsOk` default `true` in seed, so all
  toggles render ON — the light/dark PNGs show “Baking together” OFF, which is overridden by the DB.
- No `ORCHESTRATOR_NOTES.md` exists — nothing extra mandatory.
- No bottom bar / tab bar / CTA on this screen: `Scaffold` background is page `paper` top to edge,
  so the BOTTOM-EDGE rule is trivially satisfied (no bar, no strip). Do not add any footer bar.
- Copy uses the HTML’s exact characters: em dash `—` (U+2014) in intro, `é` in `café`.
- No `google_fonts` anywhere. No `letterSpacing` overrides (no tracking in this screen’s CSS).
- No chips on this screen — CHIP ROWS rule N/A. No `text-wrap: balance` in this screen’s CSS —
  no `NestBalancedText`.
- Every interactive node exposes `SemanticsAction.tap` (back, toggle, edit, New reward, sheet
  controls); toggles keep `toggled:` + `enabled:`; never wrap a control in
  `Semantics(excludeSemantics: true)` without passing `onTap:`.

## 1. Widget tree top→bottom (all tokens, no hard-coded colours/sizes)

```
Scaffold(backgroundColor: tokens.paper)
├─ NestStatusBar()                                    // reserves 47, OS draws glyphs
├─ NestNavBar(compact: true, title: 'Reward shop',    // .nav-bar.compact: min-h 52,
│             onBack: () => context.pop(),            // padding 4/12/12, 44 back btn,
│             backSemanticLabel: 'Back')              // centred 18/24 w800 title, 44 trail spacer
├─ Expanded: ListView(                                // .scroll: padding 0/20/66 (P14 §6 override
│   padding: EdgeInsets.fromLTRB(20, 0, 20, 66),     // bottom 66, NOT the base 32),
│   separators: SizedBox(16) between children)        // siblings gap 16 (.scroll > * + *)
│   ├─ Text(intro, NestType.bodySmall ink2)           // .intro 15/22 w400 ink-2, wrap, maxLines 4
│   ├─ RewardCard × N (DB order, §4)                  // .rw: surface, r-m 16, sh-1, padding 12
│   │   Row(crossAxisAlignment: center, spacing 12):  // .rw gap 12
│   │   ├─ 40×40 tile, radius 12, tint bg/fg (§4),    // .icon-tile 40×40 (radius 12 per
│   │   │  centred NestIcon(asset, 24, tintFg)        // NestListRow owner-QA precedent)
│   │   ├─ Expanded Column(align start, minWidth 0):
│   │   │   ├─ Text(name, 15/21 w700 ink, 1 line …)  // .n: bodySmallStrong→copyWith
│   │   │   │                                        // (height 21/15, w700), Flexible+ellipsis
│   │   │   ├─ padding-top 2: NestCoinPill(xSmall,    // .p: pill 13px, pad 5/9, icon 15
│   │   │   │  amount: '$price')                      // (NestCoinPillSize.xSmall)
│   │   │   └─ padding-top 8: Row(gap 10, min-h 44):  // .okrow: margin-top 8, min-height 44
│   │   │       ├─ Flexible Text('Needs my OK',       // 13/18 w600 ink-2 (NestType.fieldLabel)
│   │   │       │  maxLines 1, ellipsis)
│   │   │       └─ NestToggle(value: needsOk,        // 51×31 track, 44 tap box built in,
│   │   │            semanticLabel: 'Needs approval   // toggled: + enabled: + onTap passthrough
│   │   │            for {suffix}', onChanged: …)
│   │   └─ Semantics(button, label 'Edit {name}',    // .editbtn: EXACT 44×44 bg rect,
│   │       onTap: openSheet(reward)): Material+InkWell// radius 12, border 1×line, surface bg,
│   │       → Container(44×44, radius 12) +          // NestIcon(edit, 24, ink2). Custom rect
│   │         NestIcon(NestIcons.edit, 24, ink2)      // (NestIconButton is circular — do NOT use).
│   └─ NestButton.secondary(                       // .newbtn: secondary, min-h 52,
│        label '+ New reward', onPressed: openSheet)  // full width. Label is ASCII '+' + space.
└─ (no bottom bar; paper runs to the physical edge)
```

Reward editor = in-feature bottom sheet (no new route — none exists in the route table):
`showModalBottomSheet` + `NestBottomSheet` (`title:` `New reward` / `Edit reward`, grabber 40×5, radius 32 top, padding 8/20/50):
title `New reward` / `Edit reward` (18/24 w800), `NestField` name (52 h, r-m 16), coin
`NestStepper` (`valueText: '$price coins'`, `onDecrease`/`onIncrease` stepping 5, min 5, helper `= {price}p at payout`),
`NestToggle` row `Needs my OK`, `NestButton.primary` Save, `NestButton.ghost` Cancel,
`NestButton.dangerGhost` Delete (edit only). All in
`app/lib/features/rewards/presentation/widgets/` — no shared changes, no new routes.

Icon asset + tile tint map (seed `icon` string → P14 glyph per
`nestling_assets.dart` P14 annotations; `moon` → `clock` because the catalog names `clock`
“Reward: stay up 15 min later (P14)” and `moon` the K08 glyph):

| id | seed icon | asset | tint |
|---|---|---|---|
| r-screen | tv | `NestIcons.screenTime` | sky (`skyTint`/`sky`) |
| r-film | film | `NestIcons.film` | lilac (`lilacTint`/`lilac`) |
| r-bedtime | moon | `NestIcons.clock` | peach (`peachTint`/`aPeach`) |
| r-baking | cake | `NestIcons.chefHat` | coin (`coinTint`/`coinInk`) |
| r-cafe | coffee | `NestIcons.cafe` | leaf (`leafTint`/`leafInk`) |
| r-dinner | plate | `NestIcons.pizza` | leaf (non-adjacent to r-cafe in price order) |

Unknown future strings fall back to `NestIcons.gift` + neutral (`surface2`/`ink`).

Exact copy (from HTML, character-for-character):
- Nav title `Reward shop`; intro `Things coins can buy — you decide. Children spend coins, never pounds.`
  (em dash U+2014, full stop).
- Names/prices: `30 min extra screen time` 50 · `Pick Friday film` 80 · `Stay up 15 min later` 60 ·
  `Baking together` 100 · `Trip to the park café` 150 (é U+00E9) · `Choose dinner` 90 (DB-only row).
- Row label `Needs my OK`; toggle labels `Needs approval for screen time|Friday film|staying up
  later|baking|park cafe` (+ `Needs approval for dinner` for the 6th row — same pattern).
- Edit labels: `Edit 30 min extra screen time` · `Edit Pick Friday film` · `Edit Stay up later`
  (shortened — copy exactly) · `Edit Baking together` · `Edit Trip to the park cafe` (no accent —
  copy exactly) · `Edit Choose dinner`.
- Button `+ New reward` (ASCII plus). Empty state (§3) copy only appears when DB is empty.

Dark mode: everything via `context.nest` tokens (surface/paper/line/tints flip per SPACING_SPEC §0);
no per-theme branches. Verify light + dark screenshots.

## 2. BLoC events/states + repository calls (Drift via existing repo — no repo changes needed)

Keep `RewardsBloc`, `RewardsStatus{initial,loading,loaded,failure}`, `RewardsState(items,errorMessage)`.
`RewardsLoadRequested` stays as-is (`emit.forEach(_repository.watchItems(), …)` — never re-add to
refresh; the stream pushes updates after every write). Add to `rewards_event.dart`:

- `RewardsNeedsOkChanged(id: String, needsOk: bool)` → `await _repository.setNeedsOk(id:, needsOk:)`;
  errors → `failure` with message (stream resubscribes on next `RewardsLoadRequested`).
- `RewardsCreateRequested(title:, coinPrice:, needsOk:, icon:)` → builds `Reward(id: '', …)`
  (impl generates `reward-{ms}` id) via `_repository.createReward`.
- `RewardsUpdateRequested(reward: Reward)` → `_repository.updateReward`.
- `RewardsDeleteRequested(id: String)` → `_repository.deleteReward`.

`watchItems()` order is `coinPrice ASC` (`app_database.dart:513`) — render list order verbatim.
`watchRequests()`/`approveRedemption`/`denyRedemption` are the K08/parent-approval path, out of scope
for P14 (no redemption UI in this screen’s design). Entity `Reward.detail` (`'{price} coins'`) is
unused by P14 (price shows in the coin pill); leave the field alone.

## 3. Every interaction + navigation (route constants)

- Nav back (`Back`, 44×44) → `context.pop()` (go_router). No hard route: P14 is top-level
  (`RewardsRoutePaths.rewards = '/rewards'`), pushed from Family/Money tabs.
- `NestToggle` per row → adds `RewardsNeedsOkChanged` → `setNeedsOk` → stream re-emits → toggle
  animates. Semantics: tap on the toggle node flips the real DB row.
- Edit pencil (`Edit {name}`, 44×44) → opens editor sheet prefilled for that reward → Save adds
  `RewardsUpdateRequested`; Delete (confirm inline in sheet: second tap confirms) adds
  `RewardsDeleteRequested` and closes the sheet.
- `+ New reward` → opens editor sheet blank (defaults: price 50, needsOk true, icon gift) → Save
  adds `RewardsCreateRequested` and closes the sheet; Cancel/`Back` dismisses with no write.
- No other navigation: no tab bar on this pushed screen, no links, no redemption actions.

## 4. Empty / loading / error states

- Loading (`initial`/`loading`): centred `CircularProgressIndicator` (tinted `leaf`), full screen
  below the nav bar. (Foundation bloc starts here on every launch.)
- Empty (`loaded`, `items.isEmpty`, e.g. `Seed.empty()`/fresh or all deleted): `NestEmptyState`
  centred in the scroll: art `NestIcon(NestIcons.gift, 96, ink3)` in a 160 slot, title `No rewards
  yet` (h3), message `Add something coins can buy — a film night, extra screen time, a trip out.`
  (bodySmall ink2, em dash), action `NestButton.secondary('+ New reward')` opening the sheet.
- Error (`failure`): centred message text (`errorMessage ?? 'Something went wrong'`, body ink2) +
  `NestButton.secondary('Try again')` re-adding `RewardsLoadRequested`. Sheet write failure: keep
  sheet open, show inline error caption (`danger`, 13/18 w600) above Save.
- Seed (demo) state: 6 rows, all toggles ON, price order 50/60/80/90/100/150 — this is the UI-check
  baseline, including the `Choose dinner` row the PNGs lack.

## 5. Accessibility

- Semantics: nav back `Back`; each toggle labelled `Needs approval for …` with `toggled:` state;
  each edit `Edit {name}`; New reward / Save / Cancel / Delete labelled; coin pills
  `'{price} coins'` (built into `NestCoinPill`); intro/title plain text. Every control has
  `SemanticsAction.tap` and `performAction(tap)` performs the real DB write/sheet open.
- Tap targets ≥ 44×44 parent mode: back 44, toggle 44 box (track stays 51×31), edit 44×44,
  New reward 52 h, sheet Save 52 h, stepper buttons 44, sheet scrim tap-to-dismiss + Cancel.
- Text scale: app clamps `textScaler` to 1.0–1.3; names/pills/`Needs my OK` ellipsize single-line;
  toggle never shrinks. Verify at 1.3, light + dark.
- Width 320 (content 280): middle column `Expanded`+`minWidth 0`; name `maxLines 1` ellipsis;
  `Needs my OK` label `Flexible` + ellipsis so the toggle never clips; tile/edit keep fixed 40/44.
  Horizontally scroll-free at 320–390. Contrast from tokens (≥ 4.5:1 body, ≥ 3:1 large); no red in
  parent destructive except sheet Delete (`dangerGhost`, allowed parent-mode).

## 6. Test plan (feature dir only: `app/test/features/rewards/**`; end pumped tests with `disposeApp`)

1. Bloc (in-memory DB via `setUpTestScope`, `Seed.demo`): `RewardsLoadRequested` → `loaded` with 6
   items in price order [50,60,80,90,100,150]; `RewardsNeedsOkChanged` flips `needsOk` in DB and the
   stream re-emits; create/update/delete round-trip through the repo.
2. Widget `pumpAppRoute(tester, '/rewards')`: shows `Reward shop` + exact intro; 6 cards in DB
   order with exact names, pill amounts, all toggles ON; light + dark smoke (no overflow).
3. Toggle tap (and 5 px above/below the 51×31 track) flips the DB row; `getSemanticsData().hasAction
   (SemanticsAction.tap)` holds for back/toggles/edits/New reward; `performAction(tap)` on a
   toggle changes the DB.
4. Edit opens the sheet prefilled; Save writes; Delete removes; `+ New reward` creates (sheet
   defaults price 50 / needsOk true); Cancel writes nothing.
5. Empty DB → `No rewards yet` + working New-reward action; failure → `Try again` reloads.
6. Text scale 1.3 + width 320: no overflow, toggle/edit rects intact; edit bg rect is 44×44
   radius-12 (shape check, not text position).
7. `dart format .` clean, `flutter analyze` no issues, full `flutter test` green. No `google_fonts`
   imports anywhere in feature/test code. No simulator use outside stage 5.

## 7. SHARED_REQUEST needed?

None. No schema/seed/route/design-system changes: the 6-row/price-order/all-ON presentation,
`moon→clock` glyph choice, `plate→pizza` + `cake→chefHat` fallbacks, and the in-feature editor
sheet are all handled inside `app/lib/features/rewards/**`. (If the orchestrator later corrects
the seed — e.g. Baking `needsOk: false` to match the PNGs, or a `clock` icon string for r-bedtime —
the view needs no code change: toggles and the icon map already follow the DB row values.)

VERDICT: PASS
