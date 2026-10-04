# P15 · Child profile — build plan (Stage 1)

Route `/child-profile` (FamilyRoutePaths.childProfile) · parent mode · feature `family`.
Sources: `design/html-source/screens/P15-child-profile.html`,
`design/screens/light|dark/P15-child-profile.png` (1170×2532 → ÷3 = 390×844 logical),
DESIGN_SPEC §5 P15, SPACING_SPEC §§0–4/8/10–11.
No `docs/screens/P15/ORCHESTRATOR_NOTES.md` exists (checked) — only the global
orchestrator rules apply. No SHARED_REQUEST (see §g).

Selected child: the `CHILD` launch flag flows into `app_state.activeChildId`
(demo seed: `'maya'`). The repo resolves `activeChildId` match, else the first
child in creation order (Maya, then Leo — CHILD ORDER ruling), else null.
Demo numbers below are for Maya.

## (a) Widget tree, top → bottom

Scaffold `backgroundColor: tokens.paper`. No `NestNavBar` (tab root — the
design has none). No bottom CTA (design has none; content scrolls behind the
tab bar owned by `ParentShell`). `NestStatusBar` first (reserves 47; the OS
draws glyphs — ignore status-bar diffs in UI checks). `NestTabBar` comes from
`ParentShell` (shared — do NOT touch; BOTTOM EDGE rule is the shell's
responsibility; if a paper strip shows under the tab bar, file a
SHARED_REQUEST at the UI stage instead of fixing it here).

Body: `ListView`, padding `EdgeInsets.fromLTRB(20, 0, 20, 32)` (padSide,
bottom s8), separators `SizedBox(16)` (SPACING_SPEC §1 `.scroll` rule).
Measured bands below are PNG/3 approximations — the builder MUST confirm
every y with `tools/screens/compare.py` (±2 px rule at the UI stage).

1. Hero `NestCard` (standard; screen wins padding `20v/16h` per P15 `.hero`;
   ≈ y 59–303). Center column:
   - `NestAvatar(initial: first letter of nickname, size: s64, color: mapped
     from avatarColour: lilac→lilac, peach→peach, sky→sky, leaf→leaf,
     coin→coin, else neutral)` — 64×64.
   - `SizedBox(10)` then name `Text('Maya')`: screen-local `.hero h1` =
     Nunito 900, **24/30** (NOT the standard h1 28/34 — screen wins).
   - Sub `Text('Age 7–9 · Pip is a Fledgling')`: Inter 400 14/20, ink2.
     Build as `'Age ${ageBand.replaceAll('-', '–')} · Pip is a $stageName'`
     (en dash U+2013 from DB hyphen; middot U+00B7). `stageName`: 1→Egg,
     2→Hatchling, 3→Fledgling, 4→Songbird (mirror K03 precedent).
2. `SizedBox(16)`. Stats 3-up grid, gap 10 (each cell ≈110 wide — compute
   from width, never fixed 170 here; SPACING_SPEC §10.2): each cell is a
   `Container` surface + radius r-m 16 + `cardShadow` (== `.stat`, NOT
   `NestCard` whose radius is r-l 24), padding `12v/6h`, centered:
   value Nunito 900 22/26 (`stat .v`), label Inter 600 12/16 ink2
   (`stat .l`, maxLines 2, ellipsis — "Quests this week" wraps). Cells:
   `questsThisWeek` / "Quests this week" · `coins` / "Coins" ·
   `happyDays` / "Happy days". (≈ y 319–419.)
3. `SizedBox(16)`. Pip `NestCard` (standard, padding 16; ≈ y 435–571).
   `Row(gap 12, crossAxisAlignment: center)`:
   - `PipAvatar(style/skin/accessory parsed from the child's row, stage:
     pipStage.clamp(1,4), size: 84)` in the 84×84 slot (PIP ruling: Maya =
     mochi·sunny·none·stage 3; never the v1 `pip_stage_*.svg`). Wrap in
     `Semantics(image: true, label: "{name}'s Pip, a {stage}")` +
     `ExcludeSemantics` on the avatar (today P08 precedent).
   - `Expanded` column: title `Text('Pip · Fledgling')` Nunito 800 17/24
     (screen-local `.piprow` head — no letter-spacing); caption `Text('Evolves
     at $evolveAt total coins')` 13/18 ink2 (`evolveAt` =
     `PipProfile.evolveAtCoins` = 250, imported read-only from the pip
     feature's domain entity — no edits there); `SizedBox(8)`;
     `NestProgress(fraction: (pipTotalCoins / evolveAt).clamp(0,1),
     semanticLabel: 'Pip evolution progress')` (base 8px bar — NOT kid);
     `SizedBox(4)`; caption `Text('175 of 250 · 70%')` =
     `'$total of $evolveAt · ${pct}%'` (pct = (100·fraction).round()).
4. `SizedBox(16)`. `NestList` with 3 `NestListRow` (min-height 56, padding
   `12/10/16/10`, 40px tile radius 12, gap 12, overlay dividers left 72 —
   all inside `NestListRow`/`NestList`; ≈ y 587–787):
   - `title: 'Kid PIN'`, `tint: sky`, `leadingAsset: NestIcons.lock`,
     subtitle pinSet ? `'On · $nickname knows their code'`
     : `'Off · No code set yet'`, trailing `Text('Change ›',
     style: ink3 w600)` (trailing chevron is U+203A `›`, exactly as the
     HTML `Change ›`). COPY NOTE: the design reads "Maya knows **her**
     code" but the schema has no gender — `their` is the intentional
     data-driven adaptation (DB-driven copy; flagged for review, no schema
     change requested).
   - `title: 'Quests'`, `tint: leaf`, `leadingAsset: NestIcons.check`,
     subtitle `'$n active · $d daily, $w weekly'` (+ `' · $o one-off'`
     only when once > 0). Demo Maya: **6 active · 4 daily, 2 weekly**
     (design mock says "3 daily, 3 weekly" — DATA OVER MOCKS: the DB wins).
     Trailing `›`.
   - `title: 'Pocket money'`, `tint: coin`,
     `leadingAsset: NestIcons.poundCoin`, subtitle `'£3.00 a week · Owed
     £4.20'` = `'£${base} a week · Owed £${owed}'` with
     `(pence/100).toFixed(2)` formatting — reuse the exact helper P12's
     ledger view uses (`moneyPounds`; locate at build time, import
     read-only). Trailing `›`. (`£` U+00A3, middots U+00B7.)
5. `SizedBox(16)`. Danger `NestCard` (standard padding 16) containing a
   full-width `NestButton(label: 'Remove $nickname from family',
   variant: dangerGhost, minHeight: 48)` (P15 `.danger`: 48 high, 15px
   w700 danger, no border — matches `dangerGhost`; label interpolates the
   nickname: "Remove Maya from family").
6. Tab bar: `ParentShell` + `NestTabBar`, Family active — not this view's
   code. Gutters stay 20 everywhere (ALIGNMENT rule); cards and tab bar
   share the same side edges.

Dark mode: tokens only (surface/paper/ink flip per SPACING_SPEC §0); hero
fill is `surface`, never `ink`. No hard-coded colours/sizes anywhere.

## (b) BLoC + repository

One bloc per feature (ARCHITECTURE): extend `FamilyBloc`, no new bloc.

New entity `family/domain/entities/child_profile.dart` (`ChildProfile`,
Equatable, const): `child: FamilyChild`, `questsThisWeek: int`,
`dailyActive / weeklyActive / onceActive: int`, `owedPence: int`.

`FamilyRepository` gains `Stream<ChildProfile?> watchProfile()`:
- Watches the `app_state` row (for `activeChildId` — see `AppSession` for
  the exact query), `_db.watchChildren(Seed.familyId)` (creation order),
  `_db.watchActiveQuests`, `_db.watchAllCompletions` (same three the impl
  already combines), plus the selected child's ledger via
  `_db.watchLedger(childId)` with `asyncExpand` on the resolved selection.
  Combine with the existing `stream_combine.dart` helpers only (core is
  shared — nest `combineLatest2/3`, do NOT add helpers).
- Selection: `activeChildId` match ?? first child (creation order) ?? null
  (null = no children).
- `daily/weekly/onceActive`: the selected child's active quests grouped by
  `repeatRule` (`daily` / `weekly` / `once`; unknown rules count as `once`).
- `questsThisWeek`: completions for the child with status `done_pending`
  or `approved` where `countsForCurrentPeriod(repeatRule, createdAt, now)`
  is true (PERIODS ruling; `london_time.dart`; `now` = `DateTime.now()` at
  emission). Demo Maya ≈ 4 — the design's "18" is a mock (DB wins).
- `owedPence`: replicate the pure algorithm from
  `pocket_money_repository_impl.dart:259-284` (`summarise`) as a private
  static in the family impl (latest `payout` instant; only `weekly_base` +
  `quest_bonus` rows at/after it; `.totalPence`). Cite the source in a
  comment. No cross-feature imports, no shared edits.
- `FamilyChild` itself is UNCHANGED (P05 const test fixtures keep
  compiling).

`FamilyState` gains `ChildProfile? profile` (null until first emission;
stays put across draft edits). `_onLoadRequested` keeps ONE `emit.forEach`
(RULES §4): nest the current `combineLatest2(items, children)` with
`watchProfile()` and set all three fields in `onData`; keep the
`_closeOnError` + failure mapping.

New event `FamilyRemoveChildRequested(childId)`: `await
removeChild(childId)` in try/catch; the `watchProfile`/`watchChildren`
streams re-emit (selection falls through to the next child or null). On
`Exception`: `emit(state.copyWith(errorMessage: ...))`, status stays
`loaded`; the view surfaces it via `NestToast`. No new status values.

DI: unchanged (`FamilyBloc(repository:)` factory; the profile logic lives
inside `FamilyRepositoryImpl`, which already holds the db).

## (c) Interactions + navigation

- Kid PIN row (`NestListRow.onTap` → Semantics button+tap, P05 precedent):
  `context.push(KidHomeRoutePaths.pin)` (`/kid-pin`). ASSUMPTION flagged
  for review: no dedicated change-PIN route exists; `/kid-pin` is the
  closest PIN surface.
- Quests row: `context.go(QuestsRoutePaths.library)` (`/quests`).
- Pocket money row: `context.go(PocketMoneyRoutePaths.ledger)` (`/money`).
  (`go` for tab-branch switches per the P05 `go`-not-`push` precedent;
  `push` for the PIN overlay screen.)
- Pip card, hero, stats: not interactive (Pip carries image semantics only).
- Remove: opens `NestModal` confirm — title `'Remove $nickname?'`, body
  `'They will lose their quests, coins and Pip. This cannot be undone.'`
  (UK spelling), actions `NestButton Ghost 'Cancel'` (pop) +
  `NestButton dangerGhost 'Remove'` → adds
  `FamilyRemoveChildRequested` → pops the modal. After removal the stream
  re-emits: next child (creation order) or the empty state (§d).
- No back button (tab-branch root).

## (d) Empty / loading / error

- `initial`/`loading`: centered `CircularProgressIndicator` (P05 pattern).
- `failure`: centered message + `NestButton.secondary 'Try again'` which
  re-adds `FamilyLoadRequested` (stream was closed by `_closeOnError` —
  P05 retry precedent).
- `loaded` with `profile == null` (no children — `Seed.empty()`, or the
  last child was just removed): `NestEmptyState` — Pip stage 1 art
  (`PipAvatar(style: mochi, stage: 1, skin: sunny, size: 140)` per the
  no-child Pip rule), title `'No children yet'`, body `'Add your first
  child and their Pip will start to hatch.'`, CTA `NestButton.primary
  'Add a child'` → `context.go(FamilyRoutePaths.addChildren)`
  (`/add-children`).

## (e) Accessibility

- Every interactive node exposes `SemanticsAction.tap`: rows via
  `NestListRow.onTap` (already wraps `Semantics(button: true, onTap:)`),
  danger via `NestButton`, modal actions via `NestButton`. If any wrapper
  uses `Semantics(excludeSemantics: true)` it MUST forward `onTap:`.
- Tap targets: rows 56, danger 48, modal buttons ≥48 — all ≥44. No chip
  rows on this screen (no `NestChipWrap` needed).
- Text scale: app clamps to 1.0–1.3; verify at 1.3 — stat labels wrap ≤2
  lines + ellipsis; subtitles `maxLines: 1, ellipsis`; pip title flexible.
- Width 320: stats cells use fractional widths (`LayoutBuilder`/`Expanded`,
  gap 10 — never fixed 170/110); pip text column `Expanded` + ellipsis;
  list titles already `Flexible`+ellipsis inside `NestListRow`.
- Contrast: ink2-on-surface ≥4.5 (13px+ body), trailing ink3 ≥3:1 at its
  size/weight per spec §0.9; danger-on-surface ≥4.5 both themes.

## (f) Test plan (`app/test/features/family/`, no `google_fonts` imports)

- `child_profile_test.dart` (bloc): profile selects `activeChildId`
  ('maya'); falls back to first-created when unset/unknown; null when no
  children; breakdown 6/4/2/0 for demo Maya; `questsThisWeek` under pinned
  Sat 3 Oct 2026 (`test/flutter_test_config.dart` pins
  `Seed.anchorOverride`); `owedPence == 420`; remove event calls
  `removeChild('maya')` and the stream re-emits Leo-first state.
- `child_profile_view_test.dart` (widget, seeded demo db): exact copy —
  `Maya`, `Age 7–9 · Pip is a Fledgling` (assert the U+2013/U+00B7 chars),
  `Pip · Fledgling`, `Evolves at 250 total coins`, `175 of 250 · 70%`,
  `Kid PIN`, `Change ›`, `Quests`, `Pocket money`, `£3.00 a week · Owed
  £4.20`, `Remove Maya from family`; `PipAvatar` present with
  mochi/sunny/stage 3 and size 84; progress fraction 0.7; row taps route
  to `/kid-pin`, `/quests`, `/money` (mock router observer); remove flow:
  tap → modal → confirm → repo called with 'maya'; every control
  `hasAction(SemanticsAction.tap)` and `performAction(tap)` drives the
  real effect; 320-wide pump has zero overflow; `textScaler 1.3` has zero
  overflow. Every pump ends with `disposeApp(tester)` (RULES §7: drains
  the Drift stream-close timer).
- Keep `add_children_test.dart`, `p05_*` green (`FamilyChild` untouched).

## (g) Shared requests

None. All work is inside `app/lib/features/family/**` and
`app/test/features/family/**`. Read-only imports only:
`PipProfile.evolveAtCoins` (pip domain), `countsForCurrentPeriod` /
`londonWeekStartUtc` (`core/data/london_time.dart`), route path constants,
design-system barrel. Tab-bar/bottom-edge behaviour belongs to the shared
`ParentShell` — untouched; any strip under the tab bar becomes a
SHARED_REQUEST at the UI stage.

VERDICT: PASS
