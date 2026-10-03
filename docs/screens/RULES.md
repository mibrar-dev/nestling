# Screen build — isolation rules (foundation)

30 screen agents branch from `foundation/local-data` and build one screen
each. These rules keep parallel work conflict-free. The orchestrator applies
shared changes on `main`; screen agents never touch shared code.

## 1. What a screen agent may edit

For screen `<ID>` in feature `<feature>` (mapping in §3), ONLY:

- `app/lib/features/<feature>/presentation/**` (views, widgets, bloc)
- `app/lib/features/<feature>/domain/**` + `app/lib/features/<feature>/data/**`
  (entities, repository interface + impl, models) — when the screen needs
  fields or methods the foundation did not foresee
- `app/test/features/<feature>/**` (feature tests)
- `docs/screens/<ID>/**` (notes, screenshots, comparisons)

Everything else is shared. In particular, NEVER edit:

- `app/lib/core/**` (design system, database schema, seed, session)
- `app/lib/app/**` (router, DI, launch flags, app shell)
- another feature's directory
- `tools/screens/**`

## 2. Requesting shared changes

Shared work (design-system tweak, new route, DI change, **database schema
change**, seed correction) goes in `docs/screens/<ID>/SHARED_REQUEST.md`:

```md
# Shared request — <ID> <title>
Need: <one paragraph: what and why>
Files: <shared paths this touches, if known>
Blocks: <yes/no — can the screen land without it?>
```

The orchestrator batches these onto `main` and merges back. While blocked,
build against the foundation as-is behind a `TODO(<ID>)` comment.

## 3. Screen → feature map (same feature ⇒ NEVER run in parallel)

| Feature | Screens | Route constants (`INITIAL_ROUTE`) |
|---|---|---|
| onboarding | P01 welcome, P02 value tour | `/welcome`, `/value-tour` |
| auth | P03 create account | `/create-account` |
| privacy_consent | P04 privacy | `/privacy` |
| family | P05 add children, P15 child profile | `/add-children`, `/child-profile` |
| pocket_money | P06 setup, P12 ledger, P13 payout | `/pocket-money-setup`, `/money`, `/payout` |
| paywall | P07 paywall | `/paywall` |
| today | P08 today, P08b today empty | `/today`, `/today-empty` |
| quests | P09 quest editor, P10 library | `/quest-editor`, `/quests` |
| approvals | P11 approvals | `/approvals` |
| rewards | P14 rewards manager | `/rewards` |
| settings | P16 settings | `/settings` |
| parental_gate | P17 gate | `/parental-gate` |
| kid_home | K01 picker, K02 PIN, K03 home, K03b done, K04 detail, K05 complete | `/who-is-playing`, `/kid-pin`, `/kid-home`, `/kid-home-done`, `/quest-detail`, `/quest-complete` |
| pip | K06 nest, K07 evolution | `/pip`, `/pip-evolution` |
| kid_shop | K08 shop | `/reward-shop` |
| kid_jar | K09 jar, K10 payout day | `/my-jar`, `/payout-day` |
| badges | K11 badges | `/badges` |

Parallel-safe groups share no feature. The tightest constraint is `kid_home`
(6 screens) — run those sequentially or split presentation-only work with
extra care (bloc/entity edits will conflict).

## 4. Data layer contract (read this before touching a repo)

- `AppDatabase` (`app/lib/core/data/`) owns every table. Money is integer
  pence; timestamps UTC (display via `london_time.dart`, Europe/London).
- Repositories expose `watch…()` streams; blocs subscribe with
  `emit.forEach` — never re-add load events to refresh.
- `Seed.demo()` numbers are the spec: Maya 120 coins, owed £4.20
  (£3.00 base + £1.20 quests), Lego goal £15.50/£24.99, Leo 45 coins,
  3 pending approvals, 12 active quests. If a design number disagrees with
  the DB, file a SHARED_REQUEST — do not fork the seed.
- `Seed.empty()` = onboarded parent, no children (P08b). `Seed.fresh()` =
  nothing (onboarding flow).
- Kid screens show coins, never £ — except K09 (jar), the only £ screen.
- Pip look (`pip_style/skin/accessory/stage`) comes from the child's row
  via `PipRepository.watchProfile`; feed it into
  `PipAvatar(style/stage/mood/skin/accessory/inNest)`.

## 5. Launch flags (every screen loop uses these)

```
--dart-define=SEED=demo|empty|fresh        # reseed DB on launch
--dart-define=INITIAL_ROUTE=/today        # route constants from §3
--dart-define=APP_MODE=parent|kid
--dart-define=THEME=light|dark|system
--dart-define=CHILD=maya|leo
--dart-define=DISABLE_ANIMATIONS=1        # still frames for screenshots
```

`tools/screens/shot.sh <app_dir> <route> <out> <udid> [theme] [seed]
[mode] [child]` wraps the full invocation (non-interactive) and waits for a
stable frame. `tools/screens/compare.py <design> <app> <out>` builds the
side-by-side + heat-map and prints the per-band drift table.

## 6. Motion rule

`kDisableAnimations` (`core/data/env_flags.dart`, from
`DISABLE_ANIMATIONS`) OR `MediaQuery.disableAnimations` ⇒ render the still
frame: Rive widgets fall back to their SVG, Lottie uses `RawLottie`/still
progress. No `Timer`/`AnimationController`-driven motion may run when either
is set. Screenshots always launch with `DISABLE_ANIMATIONS=1`.

## 7. Done criteria per screen

1. `dart format .` clean, `flutter analyze` → No issues found (no ignores),
   `flutter test` → all pass (add/extend feature tests for new repo logic).
   Widget tests that pump the app MUST end with `disposeApp(tester)` from
   `app/test/test_scope.dart` — Drift schedules a deferred stream-close
   timer on bloc disposal and teardown fails with "A Timer is still
   pending" without the drain.
2. `shot.sh` for the route in light + dark, `compare.py` against the design
   PNG; band table reviewed, spacing drift fixed or filed as SHARED_REQUEST.
3. No files outside §1 touched; `SHARED_REQUEST.md` filed or absent.

## 8. Accessibility actions (shared semantics_tap)

Every interactive element must expose SemanticsAction.tap; tests assert
hasAction(SemanticsAction.tap) and performAction drives the real behaviour.
If a control is wrapped in `Semantics(excludeSemantics: true)`, the wrapper
must still pass `onTap:` (and `onLongPress`/`onIncrease`/`onDecrease` where
used) so VoiceOver/TalkBack can activate the labelled node; a disabled
control passes no tap and reports `enabled: false`.
