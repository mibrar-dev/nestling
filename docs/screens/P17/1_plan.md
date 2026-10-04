# P17 Parental gate — build plan (Stage 1, iteration 1)

Route: `/parental-gate` (`ParentalGateRoutePaths.gate`) · mode kid · feature `parental_gate`.
Sources: `design/html-source/screens/P17-parental-gate.html`,
`design/screens/light/P17-parental-gate.png` + `design/screens/dark/P17-parental-gate.png`
(1170×2532 @3x → ÷3 = 390×844 logical), DESIGN_SPEC §5 P17, SPACING_SPEC §§5/7/11.
No `docs/screens/P17/ORCHESTRATOR_NOTES.md` exists → no extra mandates.
No `1_plan.md` existed before this file. No simulator was used (plan stage must not).

## 0. What this screen is

Full kid-mode route (NOT a `showNestModal` dialog): dimmed kid backdrop (Maya header +
Pip, `aria-hidden`) + full-bleed scrim + centred `.modal` card holding the
multiplication gate. On success the app switches to parent mode and leaves the
gate; on cancel it returns to the kid screen that opened it.

Exact copy (from the HTML source, character-for-character — hyphen is U+002D,
period U+002E, colon U+003A):
- Title (h2): `Grown-ups only`
- Instruction (body-s): `Type the answer in numbers:`
- Question (h3, dynamic): `seven times six` (entity `challenge.question`)
- Digits group label: `Answer, {filled} of {total} entered`
- Keypad group label: `Number pad` · delete key label: `Delete`
- Cancel (ghost): `Back to Pip`
- Caption: `This keeps settings and purchases safe.`
- Dialog label: `Parental gate`

## (a) Widget tree, top → bottom (all spacing in logical px, CSS is truth)

Canvas 390×844. `NestStatusBar` reserves 47 (OS draws glyphs — ignore in UI checks).

```
Scaffold (backgroundColor: transparent — KidScope paints it)
└─ KidScope (sky gradient + meadow hill pinned to bottom edge; default height)
   └─ Stack
      ├─ 1. Backdrop Column (aria-hidden, ExcludeSemantics; padding 0 28px —
      │     P17 <style> `.kid-bg` wins over the 20px gutter; this is dimmed
      │     scenery, the modal defines the screen edges at x 24/366)
      │     ├─ SizedBox(height: 8)                        // `.kb-top` pad-top 8
      │     ├─ Row (gap 12, center):                      // `.kb-top`
      │     │     NestAvatar(initial: childInitial, s44, color from
      │     │       avatarColour: lilac→lilac …) 44×44
      │     │     Expanded Text `Hi {nickname}!`
      │     │       (NestType.h1 28/34 w900 ink — `.kb-hi`)
      │     │     NestCoinPill(amount: '{coins}', standard)  // DB value (demo Maya 120)
      │     └─ Center: PipAvatar(style/skin/accessory from DB, stage, size: 200)
      │          margin-top 26 (`.kb-pet`), 200×200 slot.
      │          Default/active child Maya = mochi·sunny·none·stage 3;
      │          Leo = bolt·sky·stage 2. NEVER v1 `pip_stage_*.svg`.
      ├─ 2. Positioned.fill Container(color: tokens.scrim)  // `.scrim inset 0`
      │     light ink@45 / dark black@62. Full-bleed to every edge.
      ├─ 3. Centered modal layer:
      │     Padding(horizontal: 24) → width 342
      │     → SingleChildScrollView (only scrolls at textScale 1.3 / short
      │        heights; physics NeverScrollablePhysics when it fits)
      │     → NestModal(title: null, child: Column(mainAxisSize.min)) // surface,
      │        radius 32 (allXl), raisedShadow, padding 24-top/20-side/20-bottom.
      │        Do NOT use NestModal(title:) — its title is h3 + 16 gap;
      │        design title is h2 with a 12 gap, built manually below.
      │       ├─ _LockTile 52×52, radius 16 (NestRadii.m), bg lilacTint,
      │       │    NestIcon(lock, 26, lilac), centered. (No DS component matches
      │       │    `.lock-tile`; local widget from tokens only.)
      │       ├─ SizedBox 12 → Text `Grown-ups only`, NestType.h2 ink, centered
      │       ├─ SizedBox 8  → Text instr, NestType.bodySmall ink2, centered
      │       ├─ SizedBox 4  → Text question, NestType.h3 ink, centered, maxLines 2
      │       ├─ SizedBox 16 → _DigitsRow: centered Row gap 12, Semantics
      │       │    label `Answer, {n} of {total} entered`. N boxes where
      │       │    N = answer.toString().length (design shows 2; 7×6=42):
      │       │    each 56×64, radius 16 (allM), Nunito 28 w900 (NestType.h1).
      │       │    filled: bg surface + 2px ink border; empty: bg surface2 +
      │       │    2px line border; the FIRST empty box shows a 3×24 leaf caret
      │       │    (rounded 2). Boxes are display-only (ExcludeSemantics —
      │       │    the group label announces state).
      │       ├─ SizedBox 16 → keypad slot: SizedBox(width: 296, child: FittedBox(
      │       │    fit: BoxFit.scaleDown, child: NestKeypad(kid: true,
      │       │    onKey: digit, onDelete: delete, deleteSemanticLabel:
      │       │    'Delete'))). kid:true = PNG rings (3px ink border, Nunito 900
      │       │    numerals, kid shadow). Keys 72×72, col gap 24, row gap 16.
      │       │    FittedBox only shrinks at 320px widths (264→232 inner:
      │       │    scale ≈0.88, keys ≈63 ≥ 44 — still legal); at 390 it is 1:1.
      │       ├─ SizedBox 12 → NestButton.ghost `Back to Pip`, fullWidth,
      │       │    minHeight 56, fontSize 15 (`.gate .cancel` wins over base 52/16)
      │       └─ SizedBox 10 → caption, NestType.caption ink2, centered
      └─ 4. (no bottom bar, no tab bar) — BOTTOM-EDGE owner rule: N/A, but the
            scrim + KidScope MUST run full-bleed to the physical edge; never a
            coloured strip around the home indicator. NestHomeIndicator renders
            nothing in-app (gallery mock only) — do not add spacers for it.
```

Measured modal frame (PNG÷3, UI check must confirm ±2px): x 24…366 (w 342),
y ≈ 66…778 (≈712 tall). Inside-modal y bands (approx, CSS wins on conflict):
lock 52 (pad-top 24) → title → instr → question → digits 64 → keypad 352
(4×72 + 3×16 + 2×8 padding) → cancel 56 → caption → pad-bottom 20.

Dark mode: identical geometry; surface/surface-2/line/scrim resolve from tokens.
Kid keys in dark: ink ring (≈white) + no shadow (NestKeypad handles).

## (b) BLoC events / states / repository calls

Keep the per-feature contract (`ParentalGateLoadRequested`, Status
initial/loading/loaded/failure). No new repository methods — Drift via the
existing `ParentalGateRepository` only.

State (`parental_gate_state.dart`, extend — no parental_gate tests exist yet):
- `status`, `items` (0–1 `ParentalGateChallenge`, unchanged semantics:
  `[]` = gate disabled), `errorMessage` (existing)
- ADD `entered` (String, default `''`), `attempts` (int, default 0),
  `unlocked` (bool, default false).
- Helpers: `challenge` → `items.isEmpty ? null : items.first`;
  `expectedLength` → `challenge.answer.toString().length`;
  `isComplete` → `entered.length == expectedLength`.

Events (`parental_gate_event.dart`, ADD):
- `ParentalGateLoadRequested` (existing → `watchItems()` via `emit.forEach`)
- `ParentalGateDigitEntered(String digit)` — guard: only when loaded +
  `challenge != null` + `entered.length < expectedLength` + digit 0–9 single
  char. Appends; if `isComplete`: `verify(int.parse(entered))` → true:
  `unlocked = true`; false: `attempts + 1`, `entered = ''`.
- `ParentalGateDeletePressed` — drops last char if non-empty.
- `ParentalGateUnlockAcknowledged` — resets `unlocked = false` after the view
  navigates (one-shot, survives rebuilds).

Repository (`parental_gate_repository_impl.dart`, NO changes):
- `watchItems()` — settings row `kidGateEnabled == false` → `[]`, else
  `[challengeFor(utcNow)]`. `challengeFor(DateTime utc)` deterministic per day
  (a = 2 + day%8, b = 2 + (day~/8)%8, day = d + m*31). E.g. Sat 3 Oct 2026 →
  a=3, b=9 → `three times nine` = 27. Widget tests MUST derive the expected
  question from the repo, never hard-code `seven times six` (unit tests use a
  fixed date for that string).
- `watchGateEnabled`/`setGateEnabled` belong to P16; P17 only reads via
  `watchItems`. Never write `subscription_status` (trial flows via AppSession).

Active-child backdrop data (no new repo, no cross-feature import):
- View watches `AppDatabase.watchChild(AppSession.activeChildId)` (core, public
  API; may edit nothing in core). Resolution order: activeChildId set → that
  child; null/missing → first row of `watchChildren(Seed.familyId)` in DB order
  (Maya, then Leo — insertion order, never alphabetical); no children
  (Seed.empty/fresh) → fallback header `Hi there!` + neutral avatar `•` +
  coin pill `0` + `PipAvatar(style: mochi, skin: sunny, stage: 3)` (onboarding
  rule P01–P07 analogue).
- Local mappers nickname→initial/avatarColour and pip strings→
  `PipStyle`/`PipSkin`/`PipAccessory` (same switch as K03 `_pipStyle/_pipSkin`,
  tiny local copy — a shared helper would need a SHARED_REQUEST; not worth it).
- Import `PipAvatar` directly from
  `package:nestling/core/design_system/motion/pip_avatar.dart` (not in the DS
  barrel — direct import is read-only use, allowed).

## (c) Every interaction + navigation (route constants)

Success path (BlocListener on `unlocked == true` → add
`UnlockAcknowledged`, then EXACTLY this order):
1. `AppModeController.selectMode(AppMode.parent)` (get_it) +
   `AppSession.setAppMode('parent')` + `refresh()` — parent mode FIRST so the
   router's kid-gate redirect stops firing.
2. If `Navigator.canPop` (pushed from a kid screen via lock button) →
   `context.pop()`; else `context.go(TodayRoutePaths.today)` (`/today`,
   verify import `today_routes.dart`).

Per-control behaviour:
- Keypad `0–9` → `DigitEntered`; at full length auto-verifies. Correct →
  success path above. Wrong → clear entry, `attempts+1`, announce via
  `SemanticsService.announce('That wasn’t right — try again', TextDirection.ltr)`
  (curly ’ U+2019). NO red/danger styling anywhere (kid mode, kind-motivation).
- Delete key → `DeletePressed` (no-op when empty).
- `Back to Pip` → `context.pop()` when `canPop`, else
  `context.go(KidHomeRoutePaths.home)` (`/kid-home`, verify import
  `kid_home_routes.dart`). Never goes to a parent route (router would bounce
  straight back to the gate in kid mode).
- Gate disabled (`loaded && items.isEmpty`, i.e. settings switch off): run the
  success path WITHOUT announcing (pass-through). Guard with a `didPassThrough`
  flag so the listener fires once, not on every rebuild.
- Router context (already in `router.dart`, no change): kid mode + any
  parent-only/onboarding location → `/parental-gate`; gate itself is
  kid-reachable. K03 lock buttons `push(ParentalGateRoutePaths.gate)`.

## (d) Empty / loading / failure states

All inside the SAME modal frame (lock tile + title stay; no layout jump):
- `initial/loading` → `CircularProgressIndicator` (leaf) in place of digits +
  keypad area (keep title/instr/question hidden until loaded — question is
  dynamic; show `SizedBox` placeholders of equal height to avoid shift).
- `failure` → error text (`NestType.bodySmall` ink2, the message) + ghost
  `Try again` (minHeight 44) re-adding `ParentalGateLoadRequested`. Keep
  `Back to Pip` below.
- empty/disabled → pass-through per (c), never a visible empty state.
- No children (fresh/empty seed) → backdrop fallback per (b), gate fully usable.

## (e) Accessibility

- Modal wrapped in `Semantics(label: 'Parental gate', explicitChildNodes:
  true)` (HTML `role=dialog aria-modal`). Backdrop `ExcludeSemantics`.
- Every interactive element exposes `SemanticsAction.tap`: NestKeypad keys
  already wire `onTap` on their `Semantics` nodes (11 nodes: `Digit 0–9` +
  `Delete`); both ghost buttons are `NestButton` (outer Semantics onTap).
  Tests assert `hasAction(SemanticsAction.tap)` for all 13 and that
  `performAction(tap)` mutates bloc state / navigates.
- Digit boxes display-only; state announced via group label
  `Answer, {n} of {total} entered` + wrong-answer live announcement.
- Tap targets: keys 72 (≥56 kid min), cancel 56 full-width, retry 44.
  No `Semantics(excludeSemantics: true)` wrapper without `onTap:` passthrough.
- Text scale to 1.3: modal scrolls internally (SingleChildScrollView);
  question maxLines 2 wrap; caption wraps; keypad fixed 72 (never scales text).
  Clamp app textScaler to 1.0–1.3 per SPACING_SPEC §10.
- Width 320: modal 320−48=272 wide, inner 232; keypad FittedBox scaleDown
  (≈0.88, keys ≈63); digits row (2×56+12=124) fits; title h2 wraps.
- Contrast: h2/h3 ink on surface, instr/caption ink-2 on surface (≥4.5:1 both
  themes); caret leaf on surface-2; key numerals ink on surface.
- No google_fonts anywhere; no letterSpacing additions (design CSS sets none
  on P17 — NestType defaults 0 stand).

## (f) Test plan (`app/test/features/parental_gate/` — new dir)

Unit/bloc (`parental_gate_bloc_test.dart`, uses real `ParentalGateRepositoryImpl`
on in-memory DB via `setUpTestScope` like other features):
- load emits challenge; `challengeFor(fixedDate)` → `seven times six`/42/verify.
- digit appends to `expectedLength`; extra digits ignored; delete drops last /
  no-op on empty; correct full entry → `unlocked`, wrong → cleared +
  `attempts 1`; acknowledge resets `unlocked`.
- gate disabled (`setGateEnabled(enabled: false)`) → `items` empty.
- `verify()` true/false; `question` word map incl. fallback `$n`.

Widget (`parental_gate_view_test.dart`, `pumpAppRoute(tester,
'/parental-gate')` in kid mode via `AppModeController` + `session.setAppMode('kid')`,
end every test with `disposeApp(tester)`):
- renders exact copy: `Grown-ups only`, `Type the answer in numbers:`,
  repo-derived question, `Back to Pip`, `This keeps settings and purchases safe.`
- tapping digit keys fills boxes left→right; delete removes; full correct
  answer switches AppMode to parent and pops/goes `/today`.
- cancel pops to the pushing kid route (push gate from `/kid-home`, tap cancel,
  expect `/kid-home`); semantics tap on every key/button
  (`hasAction(tap)` + `performAction` changes state).
- loading spinner, failure + `Try again` retry, disabled-gate pass-through.

Geometry (`parental_gate_geometry_test.dart`): modal x=24 w=342 radius 32;
lock tile 52 radius 16; digits 56×64 gap 12; keys 72 (measure Ink rect, not the
glyph); cancel min-h 56; scrim full-bleed 390×844; light + dark.

States/a11y (`parental_gate_states_test.dart`): textScaler 1.3 + 320×844
surface → no overflow exceptions; dark theme renders; each keypad key ≥44
effective at 320; caption contrast spot-check via token values.

## (g) SHARED_REQUEST needed

NONE. No schema/seed/route/DI/design-system change: route, `AppSession`
(`setAppMode/activeChildId`), `AppDatabase.watchChild/watchChildren`,
`KidScope`, `NestModal` (title:null + custom child), `NestKeypad(kid: true)`,
`NestButton.ghost`, `NestAvatar`, `NestCoinPill`, `PipAvatar`, tokens and
`TodayRoutePaths`/`KidHomeRoutePaths` constants all exist as-is. If the UI
check finds the keypad rings diverge from `NestKeypad(kid: true)` (ink border),
file a SHARED_REQUEST then — do not fork a local keypad.

Builder order: extend state/events → bloc handlers → `_LockTile` + `_DigitsRow`
+ view (backdrop/scrim/modal/listener/nav) → wire nothing in di/routes/router
(already registered) → tests → `dart format`, `flutter analyze`, `flutter test`.
Never `flutter clean`, never interactive `flutter run`, never boot a simulator.

VERDICT: PASS
