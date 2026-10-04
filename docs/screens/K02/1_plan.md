# K02 Kid PIN (`/kid-pin`) — build plan

Source of truth: `design/html-source/screens/K02-pin.html` (+ its `<style>` block),
`design/screens/light/K02-pin.png` and `design/screens/dark/K02-pin.png`
(1170×2532 @3x; all numbers below are logical px = PNG ÷ 3).
Geometry cross-checked by pixel scan: every HTML-derived Y below lands within
±1 px of the light PNG (dark PNG shares the same geometry; only tones differ).

Copy is plain ASCII throughout this screen (no curly quotes/dashes to preserve):
`NESTLING` · `Hi Maya! Enter your secret code` · `Forgot it? Just ask a grown-up.`
(dynamic nickname; keep the `!` and the `.` exactly).

## (a) Widget tree, top → bottom

Scaffold: `KidScope` (shared kid sky gradient + meadow hills, bottom 0, 390×136 —
orchestrator KID BACKGROUND rule; no local hills) → `Scaffold(backgroundColor:
Colors.transparent)` → `Column`:

| # | Element | Component / tokens | Geometry (logical px, y) |
|---|---|---|---|
| 0 | Status bar | `NestStatusBar()` — reserves 47 only; OS draws glyphs (orchestrator STATUS BAR rule) | 0–47 |
| 1 | Top bar | `Padding(0, 20, 0, 6)` → `Row(spaceBetween)`: back + lock | 47–109 |
| 1a | Back | `NestIconButton(icon: NestIcons.back, semanticLabel: 'Back', size: 56, iconSize: 26, backgroundColor: transparent, borderColor: transparent)` — matches `.nav-back.lg` (56, transparent, 26px chevron, ink fg default) | x 20–76, y 47–103 |
| 1b | Lock | `NestLockButton(large, semanticLabel: 'Grown-ups')` — 56×56, r18, surface bg, line border (matches `.lock-btn.lg`) | x 314–370, y 47–103 |
| 2 | Scroll | `Expanded` → `ListView(padding: 0, 20, 0, 32)` (scroll bottom = spec 32). Single centered column child | viewport 109–810 (see §bottom spacer) |
| 3 | Avatar | `Container(128 circle, lilacTint)` centering `NestAvatar(initial, s96, lilac)` — replicates the HTML exactly (`.k2-ava` 128 tinted circle + inner `.avatar.s96`; same bg so one visual disc, `M` at 38px Nunito 900, aLilac) | 109–237, x 131–259 |
| — | gap | 20 (`s5`, `.k2-body` gap) | 237–257 |
| 4 | Mark pill | `Container(lilacTint, pill, padding 2/12)` + `Text('NESTLING', kidMark + ls 1.28)` — SHARED_REQUEST #1; ls at call site (orchestrator known case K02 `.mark` 1.28 = .08em × 16) | 257–283 |
| 5 | Greeting | `Text('Hi {nick}! Enter your secret code', kidSay, center, maxLines 2)` — SHARED_REQUEST #1; one line for Maya, wraps for long names/scales | 285–311 (say has `margin-top: 2`) |
| — | gap | 20 (`.k2-body` gap) | 311–331 |
| 6 | Dots | `NestPinDots(total: 4, filled: entered.length)` — exact match (18 dots, gap 12, pad 8v, 3px ink border, filled = ink). Semantics label comes free (`N of 4 entered`, cf. design aria `Two of four digits entered`) | block 331–365; dots 340–358, x 141–249 |
| — | gap | 20 + keypad top pad 8 | 365–393 |
| 7 | Keypad | `NestKeypad(onKey, onDelete, kid: true)` — keys 72 circle, Nunito 900 26, 3px ink border, kidShadow; delete = backspace icon, label `Delete`; blank cell bottom-left. KNOWN DRIFT: component uses 24px columns / 16px rows, design measures 10/10 (pitch 82 both axes, pixel-verified) → SHARED_REQUEST #2; use component as-is + TODO | rows 393–465 / 475–547 / 557–629 / 639–711; grid x 77–313 (236 wide, centered) |
| — | gap | 20 (`.k2-body` gap, last child) | 711–731 |
| 8 | Caption | `Text('Forgot it? Just ask a grown-up.', kidCaption/ink2, center)` — `.kcap` 15/20 w700 = existing `NestType.kidCaption` | 731–751 |
| 9 | Bottom | scroll pad 32 → content ends 783; transparent bottom spacer `SizedBox(height: MediaQuery.viewPadding.bottom)` (= 34 design home reserve) so rows land on design while the shared meadow shows through to the physical edge (BOTTOM EDGE owner rule — no bar on this screen, so no surface box; spacer paints nothing) | viewport ends 810; meadow behind to 844 |

Design Y anchors for the UI check (title/say 285, dots 340, keypad rows 393/475/557/639, caption 731). Gutters: 20 everywhere (topbar pad, scroll pad, avatar/keypad/dots centered on x 195). No `Wrap`/`Row` chip rows on this screen (CHIP ROWS rule N/A). No `text-wrap: balance` in K02 CSS → no `NestBalancedText`. No Pip on this screen (avatar only; PIP rule N/A).

Dark mode: same tree; tokens flip via `context.nest` (avatar disc dark-tint/`M` lavender, keys dark-navy with light border per `NestKeypad`, dots filled light). Never hard-code a colour/size — tokens + `NestSpacing` + `NestDevice` only.

## (b) BLoC + repository

No new repo methods: `KidHomeRepository.verifyPin(childId, pin)` exists (Drift,
salted hash; `pinHash == null` → `true`). No DI / schema / seed change.
`KidHomeState.child.pinSet` already exposes whether the child has a PIN
(Maya `true`, PIN `1234` in demo seed; Leo `false` → auto-pass, see (c)).
Route already provides `KidHomeBloc + KidHomeLoadRequested` — no route change.

Additive bloc change (`presentation/bloc/`, allowed by RULES §1; K01/K03/K04/K05
share the bloc — additive fields only, no renames):

- Event `KidHomePinSubmitted({childId, pin})`.
- State adds `pinChecking=false`, `pinWrongNonce=0`, `pinPassed=false`;
  thread through `copyWith`; preserve in `withCompletion*`; `copyWithLoaded`
  preserves `pinChecking`/`pinWrongNonce`, resets `pinPassed=false`
  (consumption pattern, mirrors `justCompletedQuestId`).
- Handler: ignore re-entry while `pinChecking` (matches `_homeSub` guard
  style); emit checking; `ok = await repo.verifyPin(...)` (catch → wrong
  path, commented); emit `checking=false` + `pinPassed=true` **or**
  `pinWrongNonce+1`, built from `state` at completion time so an interleaved
  stream emission cannot swallow the outcome.
- View keeps entry digits in local `_entered` state (max 4); 4th digit
  dispatches submit and sets local `_awaiting=true` (keys disabled —
  drive from local flag, not bloc, so a mid-check stream emission cannot
  desync the keypad). `BlocListener`: `pinPassed` false→true → `go(home)`;
  `pinWrongNonce` bump → clear `_entered`, `_awaiting=false`,
  `showNestToast('That wasn’t it — try again.')` — wait, COPY RULE: design
  has no error copy; keep ASCII to match file convention:
  `showNestToast("That wasn't it — try again.")` — no, em dash is also
  non-ASCII. Use `"That didn't work. Try again."` (ASCII, kind, no red —
  kid rule; toast also announces to VoiceOver/TalkBack like K03's).
- App code never calls `DateTime.now()` (no dates on this screen anyway);
  tests pinned to Sat 3 Oct 2026 per `flutter_test_config.dart` (N/A here).

## (c) Interactions → navigation

- Digit `NestKeypad.onKey` → append if `< 4` and `!_awaiting`; at length 4 →
  submit. No OK button in design → auto-submit is mandatory.
- `onDelete` → drop last (no-op when empty).
- While `_awaiting`: keys ignored (disabled semantics state via `ExcludeSemantics`?
  no — keep enabled=false pattern: `NestKeypad` has no enabled flag; guard in
  callbacks + `AbsorbPointer`? Simplest: guard in callbacks, dots show 4 filled;
  semantics `Checking your code` live update on the dots node).
- Back (`'Back'`) → `context.canPop() ? pop() : go(picker)` (deep-link safe).
- Lock (`'Grown-ups'`) → `push(ParentalGateRoutePaths.gate)` with the K03
  `_GateLockButton` anti-double-tap guard (copy that 20-line pattern).
- Success → `context.go(KidHomeRoutePaths.home)` (replace: back must not
  return to the PIN).
- No-PIN child (`pinSet == false`, e.g. Leo) → post-frame `go(home)` once
  (transient loading UI meanwhile). K01 sends every child through K02;
  K02 is `(optional)` per the nav map — this is the option.
- Caption is static text, no action.
- Unlimited retries (kind motivation, no lockout/shame).

## (d) Empty / loading / error states

- `initial/loading` → K03 `_KidLoading` pattern: `KidScope`, status bar,
  top-right lock, centered spinner with semantics `Loading your secret code`.
- `failure` → K03 `_KidFailure` copy verbatim (`Oh no! Pip got lost.` /
  `Let's try again.` / `Try again` → re-adds `KidHomeLoadRequested`; guard
  already in bloc). Same card keeps kid screens consistent.
- `loaded` + `child == null` → K03 `_NoActiveChild` pattern (`Who's playing?`
  + `Choose` → `go(KidHomeRoutePaths.picker)`).
- Empty N/A: screen never lists `items` (ignore them entirely).
- Wrong PIN → toast + cleared dots (not the failure card; stream is healthy).
- Scale 1.3 / width 320: `ListView` (never fixed heights); say `maxLines 2`;
  keypad grid 236 wide fits 320 (42px margins); caption wraps; assert
  no-overflow in tests.

## (e) Accessibility

- Every key: `Semantics(button, label 'Digit N'/'Delete', onTap)` via
  `NestKeypad` — assert `hasAction(tap)` + `performAction` mutates dots/DB.
  Never wrap keypad in `excludeSemantics` without `onTap` (orchestrator rule).
- Dots: label-only (`N of 4 entered`), assert NO tap action.
- Back `'Back'`, lock `'Grown-ups'` — tap → real navigation (assert).
- Wrong attempt announced via toast live region; dots clear announced by label change.
- Tap targets: keys 72, back/lock 56 ≥ 56 kid minimum. Text scaler clamp
  1.0–1.3 (app-level, SPACING_SPEC §10.1).

## (f) Test plan (`app/test/features/kid_home/kid_pin_view_test.dart`)

Follow `kid_home_view_test.dart` harness (`setUpTestScope` + `Seed.demo`,
fake repo for hang/fail, `pumpAppRoute`-style local pump at `/kid-pin`,
every pump ends `disposeApp`):

1. Matrix light/dark × 320/390/430 × 1.0/1.3: renders, no overflow, copy
   (`Hi Maya! Enter your secret code`, `NESTLING`, `Forgot it? Just ask a
   grown-up.`), no `£`, no `google_fonts`, no `pip_stage_*` assets.
2. Geometry (390/1.0): avatar disc 128 (x 131–259, y 109–237); mark pill
   bg = lilacTint + pill radius + ls 1.28; dots 18px, total x 141–249;
   keypad first-row top 393 ±2, keys 72×72; caption baseline row ~731.
   Shapes-not-text: pill bg rect, dot fill colours (2 filled after 2 taps).
3. Semantics: every digit/delete/back/lock `hasAction(tap)`; digit
   `performAction` fills a dot; delete clears; dots node has no tap action.
4. Correct PIN (`1,2,3,4` taps, Maya demo PIN) → `pushedPath == /kid-home`.
5. Wrong PIN (`9,9,9,9`) → toast `That didn't work. Try again.`, dots reset
   to 0, still on `/kid-pin`; retry with correct PIN still works.
6. Leo (no PIN): set active child leo → auto-advances to `/kid-home`.
7. No active child (Seed.empty) → `Who's playing?` + `Choose` → K01.
8. Fake hang → loading (`Loading your secret code`); fake fail → failure card
   → `Try again` recovers to PIN entry. Lock → P17 gate in every state.
9. Extra 5th digit ignored; delete on empty no-op; double-tap last digit
   submits once (one `verifyPin` outcome → single navigation).

## (g) SHARED_REQUESTs (file separately; both non-blocking — build behind TODO)

1. **Typography**: add `NestType.kidSay` (Nunito 800, 20/26) for `.say` and
   `NestType.kidMark` (Nunito 900, 16/22) for `.mark` (ls 1.28 stays at the
   K02 call site). No existing scale entry covers either (nearest: h3 18/24
   w800 — wrong size, would fail the ±2px UI rule). Blocks: no.
2. **NestKeypad density**: component gaps (24 cols / 16 rows) vs measured
   design (10/10 both axes; row pitch 82, col pitch 82, grid x 77–313).
   Cumulative drift ≈ +18px by row 4 → UI-check FAIL until fixed. Same CSS
   governs P17, so the fix helps both. Blocks: partial (K02 uses the
   component as-is with `TODO(K02)` citing this plan; UI check records the
   keypad drift as a shared deviation, not a screen bug).

No other shared touch: routes, DI, schema, seed, KidScope, NestPinDots,
NestLockButton, NestAvatar, NestStatusBar all already cover K02.

VERDICT: PASS
