# P06 Pocket money setup — build plan (Stage 1)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding flow (P05 → P06 → P07).
Sources: `design/html-source/screens/P06-pocket-money.html`, `design/screens/light|dark/P06-pocket-money.png` (÷3 = logical px),
DESIGN_SPEC §5 P06, SPACING_SPEC §§2/3/8/10. No ORCHESTRATOR_NOTES.md exists. No Pip appears on this screen.

## 0. Exact copy (character-for-character from the HTML source)

- H1: `How does pocket money work in your house?`
- Option 1: `Weekly amount` / `A set amount every week`
- Option 2: `Earn per quest` / `Coins turn into pence at payout`
- Option 3: `Both` / `Weekly base + bonus for extra quests` (SELECTED by default)
- `Payout day` · chips `Mon Tue Wed Thu Fri Sat Sun` (`Sat` selected)
- `Weekly base` · `Maya` `£3.00` · `Leo` `£1.50`
- Stepper aria-labels: `Less weekly pocket money for Maya` / `More weekly pocket money for Maya` (same pattern for Leo)
- Radiogroup aria-label: `Pocket money style` · day group aria-label: `Payout day`
- `Coin value` · `10 coins = 10p`
- Caption: `Nestling never holds or moves money. You pay your way; we keep score.`
- CTA: `Continue` · nav back aria-label: `Back`
- Note: this copy is plain ASCII + `£` only (no curly quotes/dashes to preserve).

Seed truth (overrides nothing here — design matches seed): mode `both`, payoutDay `6` (Sat),
Maya £3.00 (lilac avatar `M`), Leo £1.50 (peach avatar `L`), coin value 1 pence/coin.

## 1. Widget tree top→bottom (design-system components + token spacing only)

`Scaffold(backgroundColor: tokens.paper)` — NO tab bar (onboarding step). Body is a `Column`:

1. `NestStatusBar` — reserves 47 (`NestDevice.statusH`); OS draws the real bar.
2. `NestNavBar(compact: true, onBack: …)` — no title (empty compact title slot + 44 trailing spacer
   keep the bar at its 52-minimum geometry; padding 4/12/12, back button 44×44).
3. `Expanded → SingleChildScrollView(padding: EdgeInsets(left/right: 20 = padSide, bottom: 32 = s8))`:
   - `Text(h1)`: `NestType.h1(color: ink)` — the copy above. (P06 HTML puts the H1 inside `.scroll`,
     unlike P03/P05 which use the nav-bar title slot — follow the HTML.)
   - `SizedBox(16)` then option radiogroup column (`gap 8 = s2`, NO shared widget — three
     feature-private `_PocketOptionCard` buttons built ONLY from tokens):
     each card = full-width button, `minHeight 60`, `padding vertical 8 / horizontal 13`,
     `gap 12` row, `radius 16 (r-m)`, `border 2 × line`, `bg surface`, `shadow cardShadow`;
     selected: `border leaf`, `bg leafTint`. Radio: 22 circle, unselected `border 2 × ink3, bg surface`;
     selected `border 2 × leaf, bg leafTint` with centred inner dot 10 circle `bg leaf`
     (CSS `inset 0 0 0 4px leaf-tint` ≈ 14 px leaf centre; 10 px dot is the closest token-free read).
     Text column `gap 2`: title `bodyStrong (16 w700, ink)`; sub `bodySmall (15/22, ink2)`.
     Semantics: outer `Semantics(container: true, label: 'Pocket money style')`, each card
     `Semantics(button: true, selected: …, label: '<Title>, <Sub>')`, radio `ExcludeSemantics`.
   - `SizedBox(16)` then settings card: `NestCard(variant: standard, padding: EdgeInsets.zero)`
     with manual inner padding to reproduce the full-bleed dividers (card CSS `padding: 16 16 12`,
     divider `margin: 8 -16`):
     - `Padding(16/16/0)` → `Text('Payout day', style: fieldLabel 13 w600 ink2)`,
       `SizedBox(6)` → day row: `Row(gap 6)` of 7 × `Expanded → NestChip(label, selected, onSelected)`.
       Cell ≈45.7 wide at 390; labels single-line ellipsis (NestChip already `Flexible` + ellipsis).
       Selected = Sat (payoutDay 6). Semantics label per chip: `Day Mon` … (NestChip uses `label`
       as its semantics label — pass `'Mon'` etc. as label and wrap the Row in
       `Semantics(container: true, label: 'Payout day')`).
     - Full-bleed `Container(height: 1, color: line, margin: vertical 8)` (no horizontal inset).
     - `Padding(horizontal: 16)` → `Text('Weekly base', fieldLabel)`, `SizedBox(2)`,
       then one 44-min row per child (`Row(gap 12, minHeight 44)`, children in insertion order
       Maya then Leo — NEVER alphabetical): `NestAvatar(s32, initial, lilac|peach)` +
       `Expanded(Text(nickname, bodyStrong 16 w600 ink))` + `NestStepper(valueText: '£3.00',
       decreaseSemanticLabel: 'Less weekly pocket money for Maya', increaseSemanticLabel: …)`.
       Rows are adjacent (0 gap — the HTML has no margin between them).
     - Full-bleed divider again (vertical 8).
     - `Padding(0/16/12)` → coin row (`Row(gap 12, minHeight 44)`): 40×40 `radius 16`
       `bg coinTint` tile with `NestIcon(NestIcons.poundCoin, color: coinInk, size 24)` +
       `Expanded(Text('Coin value', bodyStrong))` + `Text('10 coins = 10p', bodySmall ink2,
       softWrap: false)`. Value text rule: `'10 coins = ${10 * coinValuePencePerCoin}p'`.
4. `NestBottomCta(dense: true, caption: null, child: Column)` — dense = 14 vertical / 20 horizontal
   (P06 override wins over the base 16). HTML order is caption-ABOVE-button but `NestBottomCta`
   renders `caption` below `child`, so compose inside `child` (not a re-implementation, just slot use):
   `Text(caption, caption ink2, center, maxLines 3)` + `SizedBox(8)` + `NestButton.primary('Continue',
   minHeight: 52)`. Surface runs to the physical edge (owner BOTTOM EDGE rule — `NestBottomCta`
   already does `SafeArea(top: false)`; do NOT add page-colour padding below it).
5. No `NestHomeIndicator` widget call needed if the app shell provides it — match whatever P05 does
   (same onboarding chrome); never paint paper/cream under the CTA.

Keys (for tests): `p06_option_weekly`, `p06_option_per_quest`, `p06_option_both`,
`p06_day_1`…`p06_day_7`, `p06_base_dec_<childId>` / `p06_base_inc_<childId>` (put ValueKeys on the
stepper buttons via a wrapper — `NestStepper` has no key passthrough for its internal buttons,
so wrap each `NestStepper` in a `KeyedSubtree`? No: give the ROW `Key('p06_base_row_maya')` and find
stepper buttons by semantics label), `p06_continue`. Back button: find by semantics `Back`.

Dark mode: tokens only — no hardcoded colours. Selected option card `leafTint/border leaf` and
selected day `NestChip(selected)` both have dark variants in the design system; verify against
the dark PNG (selected card = deep green tint, selected Sat = green-tint pill).

## 2. BLoC + repository (local Drift via the existing feature repo)

Current `PocketMoneyBloc` only watches the ledger `watchItems()` — insufficient. Extend
**inside `app/lib/features/pocket_money/` only** (§1 of RULES):

New entity `domain/entities/pocket_money_setup.dart`:
`PocketMoneySetup({mode: String, payoutDay: int 1..7, coinValuePencePerCoin: int, children: List<PocketMoneySetupChild>})`
+ `PocketMoneySetupChild({id, nickname, avatarColour, weeklyBasePence})`. Mode strings are the DB
values `weekly | per_quest | both` (labels map: Weekly amount→`weekly`, Earn per quest→`per_quest`,
Both→`both`).

`PocketMoneyRepository` additions:
- `Stream<PocketMoneySetup> watchSetup()` — combines the `families` row (`fam1`: mode/payout/coin),
  the `settings` row (mirror) and the children list. Children MUST be insertion order
  (Maya, then Leo — CHILD ORDER ruling). Do NOT reuse `AppDatabase.watchChildren` (it orders by
  nickname, which yields Leo first) — query `children` ordered by SQLite `rowid` in the impl.
- `Future<void> setMode(String mode)` (assert one of the 3), `Future<void> setPayoutDay(int day)`
  (assert 1..7), `Future<void> setWeeklyBasePence(String childId, int pence)` (clamp 0..2000).
  Each writes `families` AND `settings` (both tables carry these columns; seed keeps them equal —
  update both in one transaction + `updatedAt` now UTC) so P16/settings never diverges.
- Coin value has NO setter (design shows it display-only).

`PocketMoneyState` additions: `PocketMoneySetup? setup` (null until first emit). Keep `items` —
the same bloc serves `/money` + `/payout`.

`PocketMoneyEvent` additions (write-through; NO save event — every tap persists immediately and
the stream re-emits; Continue is navigation-only):
- `PocketMoneyModeChanged(mode)` → `setMode`
- `PocketMoneyPayoutDayChanged(day)` → `setPayoutDay`
- `PocketMoneyWeeklyBaseStepped(childId, deltaPence)` → read current from `state.setup`,
  `setWeeklyBasePence(childId, clamp(current + delta, 0, 2000))`. Step = **50 p** (±£0.50; design is
  silent — 50p reproduces the £3.00/£1.50 seeds and matches UK coin granularity).

`_onLoadRequested` must subscribe to BOTH streams with ONE `emit.forEach` (two sequential forEach
never reach the second): combine via `combineLatest2` from `app/lib/core/data/stream_combine.dart`
(`watchItems` × `watchSetup`) and emit `state.copyWith(status: loaded, items:…, setup:…)`.
`onError` → `failure` as today. Follow the `emit.forEach` rule (never re-add load events).

## 3. Interactions + navigation (route constants)

- Back chevron → `context.go(FamilyRoutePaths.addChildren)` (`/add-children`; use `go`, not `pop`,
  because `shot.sh` deep-links straight at this route). Import `family_routes.dart` for the constant
  (route constants are shared read-only usage, not an edit).
- Option card tap → `PocketMoneyModeChanged` (stays on screen; card flips to selected).
- Day chip tap → `PocketMoneyPayoutDayChanged(dayIndex + 1)` (Mon=1…Sun=7). Single-select: tapping
  the selected day is a no-op (still writes are idempotent — guard `if (day == current) return`).
- Stepper −/+ → `PocketMoneyWeeklyBaseStepped(childId, ∓50)`.
- `Continue` → `context.go(PaywallRoutePaths.paywall)` (`/paywall`). No validation gate (every state
  is valid: mode always one of 3, day always 1..7, base ≥ 0). No saving spinner needed (writes are
  instant local Drift); keep the button enabled in all loaded states.
- Coin-value row: not interactive.

## 4. Empty / loading / error states

- `initial/loading` (setup == null): keep the static chrome (status bar, nav, H1, CTA shell disabled?)
  and show a `Center(CircularProgressIndicator)` in the scroll area — simplest consistent with the
  current placeholder; layout must not overflow at 320 dp either way. Do NOT render option cards
  with fake defaults (a flash of `both` before the stream emits would be a lie during onboarding).
- `failure`: `Center` message (`state.errorMessage ?? 'Something went wrong'`) + secondary
  `Retry` button re-adding `PocketMoneyLoadRequested`.
- Empty children (`Seed.empty`/`Seed.fresh`: family row exists via `beforeOpen`, children list empty):
  render mode + payout-day + coin rows normally; replace the weekly-base rows with caption-text
  `Add children to set weekly amounts.` (ink2, 13/18). Continue still works (goes to paywall).
- Failure of a single write (DB error): writes are awaited in the event handler; on throw, emit
  `failure` with the error (stream re-subscription on retry re-emits current DB truth — no stuck UI).

## 5. Accessibility

- H1 is the screen's only header (`Semantics(header: true)` via heading semantics on the title text).
- Radiogroup pattern (§1): container label `Pocket money style`; each card `button + selected`.
- Day row: container label `Payout day`; NestChip already exposes `button + selected + label`.
- Steppers use the HTML aria-labels verbatim (§0); value text `£3.00` gets an excluded-semantics money
  announcement via `NestStepper` internals (value is plain Text — wrap row in semantics
  `Maya, £3.00 per week`? Keep simple: rely on name Text + stepper labels; do not merge).
- Tap targets: option cards ≥60 high; day cells 44-min via NestChip tap box; stepper buttons 44 circle;
  CTA 52; back 44. All ≥ 44 (parent mode; no kid controls).
- Text scale 1.3 + width 320: day cells are `Expanded` (NestChip text ellipsis); option titles
  `softWrap + maxLines 2`; coin row right text `softWrap: false` inside `Flexible`? — the `10 coins`
  text must ellipsis, never push the tile (put the trailing text in `Flexible`). App text-scaler clamp
  1.0–1.3 is app-level (verify, do not re-implement).
- Contrast: ink/ink2 on surface/paper and leaf-tint backgrounds meet 4.5:1 in both themes via tokens.

## 6. Test plan (`app/test/features/pocket_money/` — new dir)

- `pocket_money_setup_bloc_test.dart` (blocTest): load emits setup from seed.demo
  (`both`, 6, 1, [Maya 300 lilac, Leo 150 peach] in insertion order); mode/day/step events call
  through and re-emit; step clamps at 0 and 2000; invalid mode/day asserts.
- `pocket_money_setup_repository_test.dart` (in-memory DB + `Seed.demo`): `watchSetup` first emit
  equals the seeds; `setMode/setPayoutDay/setWeeklyBasePence` update BOTH `families` and `settings`
  rows; children order is Maya-then-Leo even though alphabetical would be Leo-first.
- `pocket_money_setup_view_test.dart`: light + dark render all §0 copy (exact strings incl. `£`,
  `+`, `;`); Continue → `/paywall`, back → `/add-children` (via `pumpAppRoute` + `currentPath`);
  tapping `Earn per quest` flips selection; tapping `Sun` selects day 7; stepper + on Maya shows
  `£3.50`; width × scale matrix (320/390/430 × 1.0/1.3) with `takeException() == null`; semantics
  (radiogroup label, selected flags, stepper labels); every tap target ≥ 44; `disposeApp(tester)`
  at the end of EVERY widget test (RULES §7 — Drift timer). `GoogleFonts.config.allowRuntimeFetching = false`
  via `setUpTestScope`.
- Fine to extend the existing `repositories_test.dart` instead if it already covers pocket-money —
  check first; do not duplicate.

## 7. SHARED_REQUEST

None. All components exist (`NestNavBar` compact, `NestChip`, `NestStepper`, `NestCard`,
`NestButton.primary`, `NestBottomCta(dense)`, `NestAvatar.s32`, `NestIcon.poundCoin`, `NestStatusBar`,
tokens, spacing, radii). Two watch-items for the builder (NOT shared requests, NOT blockers):
1. `NestChip` label is fixed at 14 px (`chipLabel`) while P06 day cells are 13 px (SPACING_SPEC
   conflict #6). Use `NestChip` as-is; if `compare.py` shows glyph drift on `Mon…Sun`, file a
   follow-up SHARED_REQUEST for an optional `labelStyle` override (do not fork the component).
2. `TODO(P06)` needs no shared fallback — every read/write in §2 is reachable from the feature's
   own `domain/` + `data/` (expressly allowed by RULES §1).

`dart format`, `flutter analyze` (zero issues, no ignores), `flutter test` (all pass) before Stage 2.

VERDICT: PASS
