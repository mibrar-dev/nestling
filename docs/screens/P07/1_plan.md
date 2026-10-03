# P07 Paywall — build plan (Stage 1)

Route: `/paywall` (`PaywallRoutePaths.paywall`, feature `paywall`, parent mode, end of P01→P07 onboarding).
Sources: `design/html-source/screens/P07-paywall.html`, `design/screens/light/P07-paywall.png`,
`design/screens/dark/P07-paywall.png`, DESIGN_SPEC §5 P07, SPACING_SPEC §§1–2/8/10–11.
PNG size 1170×2532 = 390×844 logical (÷3). All numbers below are logical px = Flutter dp 1:1.

Note on PNG vs HTML: the PNGs show the top of the scroll (hero → title → benefits → plan → CTA).
The HTML `timeline` card ("What happens next") + `center-note` ("One subscription…") live BELOW the
fold inside the same `.scroll` — no conflict, they appear on scroll. The builder implements the full
HTML column; `shot.sh` at top-of-scroll must match the PNGs.

Exact copy (typographic characters preserved — builder: copy these strings verbatim):
- Title (h1, centred): `Try Nestling free for 14 days`
- Benefits (4 rows): `Unlimited children & quests` · `Pip’s full evolution & seasonal outfits` (curly ’)
  · `Pocket money ledger & payout day` · `Co-parent sharing, so James sees the same`
- Plan card: title `Annual — £29.99/year` (em dash U+2014) · sub `Just £2.50 a month, billed yearly`
  · tag `One price, the whole family`
- Timeline head: `What happens next`; items: `Today` / `Full access, straight away`;
  `Day 12` / `We’ll remind you by email` (curly ’); `Day 14` / `£29.99 billed — cancel any time` (em dash)
- Centre note: `One subscription covers the whole family.`
- CTA: `Start free trial`; caption: `£29.99/year after the 14-day trial. Cancel anytime in Settings.`
- Legal row: `Restore purchases` · `·` (U+00B7) · `Terms` · `·` · `Privacy`
- Close semantics: `Close and go back`; hero Pip semantics:
  `Pip the songbird, fully grown, sitting in a twig nest`

## (a) Widget tree top→bottom (design-system components + token spacing only)

`PaywallView` (feature-private widgets under `presentation/widgets/`; no `core/` or `app/` edits):

1. `Scaffold(backgroundColor: tokens.paper)` — NO tab bar (onboarding flow, top-level route).
   `body: Column(children: [NestStatusBar(), _PaywallNav(), Expanded(_PaywallScroll), NestBottomCta(...)])`.
   `NestStatusBar` height-reserve only (OS draws real bar — ignore status-bar diffs in checks).
   Bottom-edge owner rule: `NestBottomCta` surface runs to the physical edge (it wraps in `SafeArea(top:false)`);
   never add page-colour padding below it.
2. `_PaywallNav` — compact bar per `.nav-bar.compact`: `minHeight 52`, padding `4,12,12` (`s1/s3/s3`).
   Row: 44×44 close button (surface-2 bg, radius 12 — `.nav-back.close`, implement locally as
   `Container(44×44, decoration: surface2 + r12) > NestIcon(close, ink)`; `NestNavBar` back slot is
   transparent so do NOT use it here), `Expanded(fill)`, 44-wide `nav-gap` spacer (balances the bar).
   Tap 44×44, semantics `Close and go back`.
3. `_PaywallScroll` — `ListView(padding: EdgeInsets.fromLTRB(20,0,20,32))`, separators per-item
   (base `.scroll > * + *` 16 overridden by explicit margins below). `softWrap`/ellipsis per §10.
   Children in order with exact gaps:
   a. `_PaywallHero` — `350×148`, `margin-top 4`. `Stack` (positions from HTML, scale by `w/350` at 320 px
      widths — same `LayoutBuilder` scale pattern as `welcome_view.dart` `_SceneCoin`):
      circle 170×170 at (90,−5) lilac-tint; nest SVG 150×150 at (100,41) (`NestlingIllustrations.nest`,
      excluded from semantics); `PipAvatar(style: mochi, skin: sunny, stage: 4)` 120×120 at (115,20)
      — orchestrator PIP rule: P01–P07 (no child yet) use mochi/sunny at the design's stage (here 4);
      never v1 `pip_stage_*.svg`. Coins (`NestlingIllustrations.coin`, sh-1 circle shadow, decor only):
      30×30 at (8,30) rot −14°, 26×26 at right 6 / top 70 rot +12°, 24×24 at (30,128) rot +20°.
   b. Title — `margin-top 26`, `NestType.h1(ink)`, centred, maxLines 3 (text `Try Nestling free for 14 days`).
   c. `_BenefitList` — `margin-top 18`, column gap 10. Row: tick 24×24 circle (leaf-tint bg,
      `NestIcon(check, 16, leafInk)`, `margin-top −1`) + text `Inter 15/24 w400 ink, softWrap, anywhere`
      (HTML `benefit-txt` is 15/24 — use explicit `GoogleFonts.inter(15, height 24/15)`; closest token
      `bodySmall` is 15/22 so do NOT use it here). 4 rows, exact copy above.
   d. `_PlanCard` — `margin-top 24`. `NestCard` standard geometry (radius 24 = `allL`, sh-1, padding 16)
      + local 2px leaf border (wrap in `Container(decoration: BoxDecoration(border: Border.all(leaf,2),
      borderRadius: allL))` — no core change). Row gap 12, cross-start: radio 22 circle
      (selected: leaf fill + `inset 0 0 0 4 leaf-tint` ring → `BoxDecoration(leaf, inset shadow via second
      BoxShadow leafTint spread 4 inside — approximate with outer ring: circle border 4 leaf-tint outside
      14px leaf dot)`, `margin-top 10`); text column gap 2: title Nunito 800 18/24 ink
      (`NestType.h3`), sub Inter 15/20 ink-2, tag Inter 13/18 w600 leaf-ink with `margin-top 4`.
      Single plan → already selected, tap = no-op; `Semantics(selected: true, label: 'Annual — £29.99/year…')`.
   e. `_TimelineCard` — `margin-top 48` (explicit HTML override of base 16). `NestCard` standard padding 16.
      Head `NestType.h3(ink)` `What happens next`, `margin-bottom 12`. 3 `_TlItem`: `padding-left 36`,
      `padding-bottom 16` (last 0); dot 24 circle (leaf-tint fill + 2 leaf border) at (0,2); connector
      2px line at left 11 from top 26 to bottom −2 (hide on last); title Inter 15/20 w700 ink;
      sub Inter 15/20 ink-2 wrap-anywhere.
   f. `_FamilyNote` — `margin-top 20`, centred row gap 8: group icon 20 ink-2
      (`NestIcons.person` — two-person glyph closest in set; 20px, stroke 2) + text Inter 15/22 w600 ink-2
      centred, maxLines 2 (`One subscription covers the whole family.`).
   g. Scroll bottom padding 32 (base; content above CTA never hidden).
4. `NestBottomCta` (surface + top hairline, padding `16/20`, gap 8, caption centred):
   `NestButton.primary(label: 'Start free trial', minHeight: 52)` full-width;
   caption `£29.99/year after the 14-day trial. Cancel anytime in Settings.` (`NestType.caption` ink-2, centred);
   `_LegalRow`: centred row gap 2 — three sky underline links (`Inter 13 w600`, `sky`, underline offset 2,
   each `min 44×44, padding 0 6`) `Restore purchases` / `Terms` / `Privacy` separated by `·` ink-3 13px.
   Below-fold items (timeline, family note) scroll behind; nothing overlaps CTA.

Side gutters 20 everywhere (`padSide`); cards/bars share the same 20px edges (alignment owner rule —
verify no ±px drift in `compare.py` heat-map).

## (b) BLoC events/states + repository calls (local Drift via existing repo)

Keep one bloc per feature (`PaywallBloc`). Existing `PaywallLoadRequested → emit.forEach(watchItems())`
stays. ADD two action events (new file edits allowed inside the feature only):

- `PaywallTrialStarted` → `emit(working)`; `await repository.startTrial()`; `emit(success)`;
  on error `emit(failure, errorMessage)`.
- `PaywallRestoreRequested` → `emit(working)`; `await repository.activate()`; `emit(success)`;
  on error `emit(failure)`.
- State: extend `PaywallState` with `action: PaywallAction {idle, working, success, failure}` +
  reuse `errorMessage`. `status` (initial/loading/loaded/failure) keeps driving the scroll body;
  `action` drives only the CTA button (`loading: action == working` disables at opacity .45 per §2).
- Repository (existing, no change needed): `watchItems()` (static annual plan), `watchSubscription()`,
  `startTrial()` (writes trial status + `trialStart` UTC + zone), `activate()`.
- View wiring (mandatory orchestrator item 1): on `action == success` the VIEW (not the bloc — bloc has no
  context) runs: `await context.read<AppSession>().startTrialNow();`
  `await context.read<AppSession>().completeOnboarding();` then `context.go(TodayRoutePaths.today)`.
  `AppSession` is already registered (`core/data/app_session.dart`); feature imports it read-only.
  Trial and Restore share the success path (Restore = previously-paid user → same landing; `activate()`
  already set `active`, `startTrialNow()` would regress it — so for Restore call ONLY
  `completeOnboarding()` + `setSubscription('active')` via session… correction: Restore path =
  `await session.setSubscription('active'); await session.completeOnboarding();` then go `/today`).
  Listen with `BlocListener` filtering action transitions; guard double-navigation with `if (!context.mounted)`.

## (c) Every interaction + navigation target (route constants)

| Element | Action | Target |
|---|---|---|
| Close X | `onBack` | `context.canPop() ? pop() : go(PocketMoneyRoutePaths.pocketMoneySetup)` (`/pocket-money-setup`, previous onboarding step) |
| Start free trial | `PaywallTrialStarted` → session writes → `go(TodayRoutePaths.today)` (`/today`) | `/today` (parent shell; router guard then passes — onboarded) |
| Restore purchases | `PaywallRestoreRequested` → session `setSubscription('active')` + `completeOnboarding()` → `go(TodayRoutePaths.today)` | `/today` |
| Terms / Privacy | No onboarding route exists; show `NestToast('…available in the full app')` placeholder + `TODO(P07)` comment | none (no new route — shared change would need orchestrator) |
| Plan card | already-selected single plan; tap no-op (a11y `selected: true`) | none |
| Timeline / benefits / hero | static, non-interactive (`ExcludeSemantics` on art) | none |

Imports: `TodayRoutePaths` (`features/today/today_routes.dart`), `PocketMoneyRoutePaths`
(`features/pocket_money/pocket_money_routes.dart` — verify constant name at build; fallback string
`/pocket-money-setup` behind `TODO(P07)` if the identifier differs), `AppSession`
(`core/data/app_session.dart`, read-only), `go_router` `context.go/pop/canPop`.

## (d) Empty / loading / error states

- `initial/loading` → full-screen `Center(CircularProgressIndicator(color: leaf))` (keep current placeholder
  behaviour; content is static so this resolves in one frame from `Stream.value`).
- `failure` (watch error) → centred error: `NestIcon` + `Something went wrong` + `NestButton.secondary('Retry')`
  re-adding `PaywallLoadRequested`. Action failure (`action == failure`) → `NestToast` with
  `errorMessage ?? 'Something went wrong'` + CTA re-enabled (no full-screen swap).
- Empty plan list → NOT an empty-state screen: copy is static spec text, render it regardless of
  `state.items` (items only confirm the static `_plans` entry; never block the trial CTA on them).
- No `Seed` dependency (P07 shows no DB numbers — DATA-OVER-MOCKS n/a; do not hard-code child names beyond
  the fixed design copy `James`).

## (e) Accessibility

- Semantics: nav `aria-label 'Subscription'` → `Semantics(header)`; close button label `Close and go back`;
  hero art excluded except Pip `image label` above; benefits `role=list` → `Semantics(container)` per row
  with tick excluded; plan card `selected: true`; timeline `ol` → ordered semantics
  (`Semantics(indexInParent)`); legal links are real `TextButton`s (underline, 13px ≥ 4.5:1 sky on surface
  both themes — verify dark sky `#7FA9FF` on `#1F1C2E`).
- Tap targets: close 44×44, CTA 52, legal links min 44×44 (padding `0 6` inside 44 box), plan card no-op
  needs no target; tick/dot art excluded from hit-testing.
- Text scale: app clamps `textScaler` 1.0–1.3 (§10.1); benefit/plan/sub/timeline texts `softWrap: true`
  (no ellipsis except title maxLines 3); legal row `Wrap` (not single Row) so 1.3× doesn't overflow.
- Width 320: hero scales via `LayoutBuilder` factor (`welcome_view.dart` pattern); plan row keeps
  radio fixed 22 + `Expanded` text; timeline keeps 36px gutter; gutters stay 20 (content 280).
- Motion: `PipAvatar` still-frame under `kDisableAnimations`/screenshots; no timers/controllers on screen.
- Contrast: body 15px ≥ 4.5:1 ink on paper both themes; tag leaf-ink on surface (light `#0B5C38`, dark
  `#8EE6BC`); tick leaf-ink on leaf-tint.

## (f) Test plan

Location: `app/test/features/paywall/**` (feature dir only). Widget tests MUST end with
`disposeApp(tester)` (`app/test/test_scope.dart`) to drain Drift's deferred stream-close timer.
1. `paywall_bloc_test.dart`: load emits `[loading, loaded]` with annual plan (`Annual — £29.99/year`);
   `PaywallTrialStarted` calls `startTrial()` then `action success`; error → `action failure`;
   `PaywallRestoreRequested` calls `activate()`.
2. `paywall_view_test.dart` (pump via shared test scope, `DISABLE_ANIMATIONS`, mock repo + fake
   `AppSession`): exact-copy finds (title, 4 benefits incl. curly ’, plan title/sub/tag, timeline 3 items,
   family note, CTA, caption, 3 legal links); `PipAvatar(style mochi, stage 4)` present, no
   `pip_stage_` SVG usage; close button semantics `Close and go back`; CTA tap → bloc event + navigation
   to `/today` with `startTrialNow + completeOnboarding` called (orchestrator item); Restore →
   `setSubscription('active') + completeOnboarding`.
3. Text-scale 1.3 + width 320 pump: no overflow (`tester.takeException` null).
4. Light + dark pumps: leaf-border plan card, CTA, legal sky readable in both.
5. `dart format .` clean; `flutter analyze` → No issues found; `flutter test` all pass.
6. `tools/screens/shot.sh app /paywall <out> <udid> [light|dark]` (seed fresh, parent mode) +
   `tools/screens/compare.py design/screens/{light,dark}/P07-paywall.png <shot> <diff>`; review band table:
   top-of-scroll must match PNG (timeline/family-note below fold verified by scrolled shot, not the diff);
   bottom-edge check: no paper strip under `NestBottomCta` in either theme; gutters 20px aligned.

## (g) SHARED_REQUEST

None. No `core/`, `app/`, schema, seed, route, or DI changes needed: `AppSession.startTrialNow /
completeOnboarding / setSubscription`, `TodayRoutePaths.today`, onboarding setup path, `PipAvatar`,
`NestCard/Button/BottomCta/StatusBar/Icon`, and the paywall repository methods all exist. Plan-card leaf
border + surface-2 close background are implemented locally in the feature (no design-system tweak).
External Terms/Privacy URLs stay as toast placeholders behind `TODO(P07)` — no shared route requested.

VERDICT: PASS
