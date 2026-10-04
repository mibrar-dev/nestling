# P17 Parental gate — QA code review (stage 4, iteration 3)

Scope: `git diff main...HEAD` (53 files) — `app/lib/features/parental_gate/**`,
`app/test/features/parental_gate/**`, `docs/screens/P17/**`, plus the two
out-of-scope files listed in finding 1. Reviewed against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P17, the design system in
`app/lib/core/design_system/`, the accessibility / performance / error-handling /
Children's Code criteria, and the orchestrator rules in the stage brief
(`ORCHESTRATOR_NOTES.md` items 1–7 + the 07:13 keypad note are mandatory).

## Verified independently this iteration

| Check | Result |
|---|---|
| `flutter analyze` (whole app) | **No issues found!** (7.7 s) |
| `flutter test test/features/parental_gate` | **+106 ~1: All tests passed!** (1 skip = P17-BUG-1, shared `router.dart`, honestly skip-marked) |
| `dart format --output=none --set-exit-if-changed lib/features/parental_gate test/features/parental_gate test/core/family_time_test.dart` | clean for every file in the diff |
| `flutter test test/core/family_time_test.dart` | +22 pass (the file P17 edited outside §1 — see finding 1) |
| Diff path audit | only `features/parental_gate/**`, `test/features/parental_gate/**`, `docs/screens/P17/**` + the two finding-1 files. `app/lib/core/**`, `app/lib/app/**`, `pubspec.yaml`, `analysis_options.yaml`, `tools/**` are untouched. |
| `5_ui.md` (iteration 3, concurrent stage) | mean diff 1.37 % light / 1.45 % dark (was 6.66 / 5.41); card top 66/66, bottom 777.7/777.7, x24 w342/342, title 164/164, keypad rows 344/426/508/590 all Δ0, cancel +1.7 — every ORCHESTRATOR_NOTES item measured PASS |

Owner-rule sweep (all clean, no finding): PIP from the DB via `PipAvatar`
(`style/skin/accessory/stage` per child, Mochi·sunny·stage 3 for Maya; the
no-child fallback is `PipAvatar(style: mochi, stage: 3)`, whose default skin is
`sunny` — the onboarding analogue), never a `pip_stage_*.svg`; CHILD ORDER
(`db.watchChildren` is ordered `createdAt, rowid` and the fallback is
`kids.first`, never alphabetical); no `google_fonts`/`GoogleFonts`; no
`letterSpacing` added anywhere (the P17 CSS sets none, so `NestType` defaults
stand — and the view test pins 0); no `NestBalancedText` (P17 uses `.h2/.h3/
.body-s/.caption`, all excluded by the rule, and the backdrop greeting is
`.kb-hi`, not `.h1`); no `subscription_status` write; no `DateTime.now()` in
`lib`; BOTTOM EDGE n/a (no bar) and the scrim + shared `KidScope` meadow run
full-bleed (pinned); copy is ASCII-exact against the HTML source
(`Grown-ups only`, `Type the answer in numbers:`, `Back to Pip`, `This keeps
settings and purchases safe.`, `Parental gate`, `Number pad`, `Delete`), UK
spelling, no curly punctuation on this screen; DI/routes untouched and already
correct (`registerParentalGate` lazy-singleton repository + factory bloc,
`parentalGateRoute` provides the bloc and fires `LoadRequested`); domain holds
entities + the abstract repo only, data holds the repo impl + one model.

## Iteration-3 changes — review

The iteration-3 builders changed only the view (`parental_gate_view.dart`) and
the geometry/states/view/bugs tests; `2a_build_logic.md` confirms the bloc,
state, events and the London-day `challengeFor` are byte-identical to
iteration 2, so I re-reviewed the whole diff rather than only the delta.

- **Card anchor vs CSS centre** — the modal is now `Padding.fromLTRB(s6, 66,
  s6, 0)` + `ConstrainedBox(minHeight: maxHeight − 66)` + `Align(topCenter)`
  (`:127-141`). At textScale 1.0 this reproduces the design exactly (card
  66…778, verified twice: geometry pins and the 5_ui device run), and the
  `SingleChildScrollView` still absorbs the 1.3-scale card. CSS truth is
  `.modal { top: 50%; transform: translateY(-50%) }` — a deviation in form,
  identical in result at the design scale. Finding 3.
- **Keypad call-site compatibility** (`:229-284`) — `LayoutBuilder` picks
  `NestKeypadFit.stretch` when the card content ≥ `NestKeypad.contentWidth`
  (302 ≥ 280 at 390 px) and renders the keypad directly, else
  `FittedBox(scaleDown) > SizedBox(width: contentWidth) > shrinkWrap`. That is
  exactly the two patterns the iteration-2 test review prescribed; it fixes the
  `RenderFlex … unbounded` merge blocker and keeps the painted key at 59.7 px
  at 320 (≥ 56 kid minimum). No local re-spacing — the shared pitch (82/88) is
  used as merged. Correct per ORCHESTRATOR_NOTES 07:13.
- **`NestKeypadFit.shrinkWrap` with an explicit width** — sound: the component's
  `contentWidth` (280) is a token-level constant, so nothing screen-local
  duplicates the CSS arithmetic.
- **Backdrop row alignment** — `crossAxisAlignment` removed, so the `Row`
  default `center` implements `.kb-top { align-items: center }`. The geometry
  pin was then split into row-top (55) and greeting-text-top (60), which is a
  correction of a wrong expectation, not a relaxation: 60 = 55 + (44−34)/2.
- **`_announcedChallengeId`** — re-bases the announcement high-water mark when
  the live challenge changes, so the first wrong answer on a new question is
  announced. Correct, view-local, no contract change.
- **`_GateLoading`** reserves 326 (8 + 4×72 + 3×10 = the merged keypad) and no
  longer double-reserves the caption gap the enclosing column adds; the
  loading-vs-loaded card height pin is green at Δ0.
- **Rebuild behaviour** — `_ParentalGateViewState.build` runs once (the route's
  `BlocProvider` never rebuilds); state changes land in the inner
  `BlocBuilder` behind a `buildWhen` on status/items/entered/errorMessage, so a
  digit tap rebuilds the digits + keypad only. No rebuild storm; `_LockTile`
  and `_GateLoading` are `const`. Streams: the backdrop's `StreamBuilder` is
  re-subscribed only when `AppSession` notifies (`appState` row write or
  `refresh()`), not per frame. Finding 5 is the one genuine leak.

## Findings

1. **minor** — RULES §1 violation, open for the third iteration.
   `app/test/core/family_time_test.dart` (+54/−8) and
   `docs/screens/_shared/family_time_test_fix_REPORT.md` are in the diff;
   neither is inside `app/lib/features/parental_gate/**`,
   `app/test/features/parental_gate/**` or `docs/screens/P17/**`, and neither
   is cited in `SHARED_REQUEST.md`.
   The *fix* is correct and needed — with main's PERIODS ruling
   `KidHomeRepositoryImpl.completeQuest` inserts a second row for a quest whose
   seeded completion belongs to an earlier period, so main's
   `expect(rows.single.createdAtTz, london)` throws; P17's
   before/after-snapshot helper is date-independent (verified: the file passes
   on this branch). The routing is what is wrong.
   Fix: move the report into `docs/screens/P17/` (or drop it) and either have
   the orchestrator absorb `family_time_test.dart` onto `main` — it is a
   shared-test repair, not a P17 change — or revert it here and rebase after
   the merge. Add a line to `SHARED_REQUEST.md` recording the shared
   regression so it is not lost when the branch merges.

2. **minor** — architecture: the view queries another feature's data.
   `parental_gate_view.dart:347-353`: `_GateBackdrop` resolves
   `GetIt.instance<AppSession>()` and `GetIt.instance<AppDatabase>()` in
   `build()` and runs its own `db.watchChildren(Seed.familyId)`
   `StreamBuilder`. ARCHITECTURE's per-feature contract puts data access in
   `data/<feature>_repository_impl.dart` and streams through the BLoC; no other
   feature view touches `AppDatabase` (only `paywall_view.dart` reads
   `AppSession`, an app-wide service, which is fine). Carried from iteration 1.
   Fix: add `Stream<ParentalGateBackdropChild?> watchActiveChild()` to
   `ParentalGateRepository` (impl over `AppDatabase.watchChild` /
   `watchChildren(Seed.familyId)`, keeping the active-child-then-first-in-DB-
   order resolution in `data/`), `combineLatest2` it with `watchItems()` in
   `ParentalGateBloc`, put the child in `ParentalGateState`, and let the view
   bind to state. This is a contract change, so — as `2a_build_logic.md` notes
   — it needs a joint logic+UI iteration, or a recorded orchestrator deferral.
   Either way it should stop being re-litigated every review: either fix it or
   have the orchestrator accept the plan's deliberate "no new repo" choice.

3. **minor** — `parental_gate_view.dart:132` and `:139`: the magic number `66`
   is the *derived* design top `(844 − 712) / 2`, while the CSS is
   `.modal { top: 50%; transform: translateY(-50%) }` — i.e. centred. At
   textScale 1.3 the card grows to ~788 px and now hangs from 66 downwards
   (a 10 px internal scroll, as `3_test.md` obs 1 records) instead of staying
   vertically centred, so the anchor encodes the design's card height.
   Fix: drop the literal and centre — keep the
   `SingleChildScrollView > ConstrainedBox(minHeight: constraints.maxHeight)`
   and use `Align(alignment: Alignment.center)` (or a `Center`) with symmetric
   `EdgeInsets.symmetric(horizontal: NestSpacing.s6)`; at textScale 1.0 the
   712 px card then lands on exactly 66 and the existing pins (card top 66,
   bottom 778) stay green, while the 1.3 case stops depending on a literal.

4. **minor** — failure state duplicates the caption and adds a dead 10 px.
   `_GateFailure` (`:611-616`) renders its own `SizedBox(height: s2 + gap2)` +
   `This keeps settings and purchases safe.`, and the enclosing column
   (`:304-320`) then adds another `SizedBox(height: s2 + gap2)` plus a
   `SizedBox.shrink()` standing in for the caption it skips. Result: a 10 px
   orphan gap below the caption in the failure state only, and two owners for
   one piece of copy — flipping the `status == failure` condition would render
   the caption twice.
   Fix: let the enclosing column own both (drop `:611-616` from `_GateFailure`
   and always render the caption there), or drop the outer
   `SizedBox`/`shrink` pair and keep them inside `_GateFailure`; not both.

5. **minor** — retry leaks one live `emit.forEach` subscription per attempt.
   `parental_gate_bloc.dart:17-51`: `_onLoadRequested` never returns (the
   `watchItems()` subscription is open for the life of the bloc), and bloc 9's
   default transformer is concurrent (`map` + flatMap,
   `bloc-9.2.1/lib/src/bloc.dart:61-65`), so each `Try again`
   (`ParentalGateLoadRequested`) starts a *second* handler and a second Drift
   subscription while the first stays open. Repeated taps grow the listener set
   without bound, and the stale subscription can still emit `onError`, flipping
   the UI back to the failure card after a retry that already succeeded
   (a race the current tests cannot hit because they never tap retry twice).
   Fix without a dependency (`bloc_concurrency` is not in `pubspec.yaml`, and
   `pubspec.*` is shared, so a SHARED_REQUEST would be needed): add a private
   `int _loadGeneration`, bump it in `_onLoadRequested`, and return early from
   `onData`/`onError` when the captured generation is no longer current; or
   keep the `Emitter` from the previous call and `cancel()` it. Add a test that
   adds `LoadRequested` twice and asserts exactly one emission per stream event.

6. **minor** — `parental_gate_view.dart:600`: `Try again` is
   `minHeight: 44`, below the kid minimum. DESIGN_SPEC §5 kid rules ask for
   tap targets ≥56, and the only other control in that state (`Back to Pip`,
   `:607`) is 56. The value comes from `1_plan.md` §(d) and is pinned by
   `parental_gate_states_test.dart`, so this is a plan/spec conflict, not a
   coding slip.
   Fix: amend the plan line to `minHeight: NestDevice.tapKid` (56) and update
   the pin; if the orchestrator prefers 44, record the acceptance next to the
   plan so it is not re-found each iteration.

7. **note, not actionable by P17** — dead code, deliberately kept and now
   justified: `presentation/widgets/parental_gate_placeholder_card.dart` is
   unreferenced, but 14 byte-identical copies exist across features (the
   repo-wide v1 scaffold — deleting only P17's would make this feature the odd
   one out). `data/models/parental_gate_challenge_model.dart` is also
   unreferenced from `lib` (only its own round-trip test imports it); that one
   has no repo-wide justification, so either wire it into the repository's
   serialisation or delete it with its test.

8. **note, not actionable by P17** — `SHARED_REQUEST.md` #1 (8 reds in
   `app/test/features/kid_home/**` asserting the removed v1 scaffold title) and
   #2 (P17-BUG-1: kid mode + expired trial →
   `/paywall ↔ /parental-gate` redirect loop in shared `app/lib/app/router.dart`)
   are both still open. #3 (keypad pitch) is resolved by `9cac0c6` and can be
   closed — the pitch measures 82/88 with no P17-local change and no stale
   `TODO(P17)` left at the call site. The single `skip:` in the suite is
   P17-BUG-1 and stays honestly marked; nothing in this feature is red.

9. **note** — a gate left open across London midnight keeps its question:
   `watchItems()` only re-emits when the `settings` row changes, so nothing
   re-keys the challenge at 00:00 (same reasoning as `3_test.md` obs 5 and
   P17-BUG-2's tail). Low impact for a seconds-long interaction; no test pins
   it. Also unchanged: no in-app exit during `initial`/`loading` (only the
   system back gesture), which the plan's loading design sanctions.

Children's Code re-check: no analytics, ads, trackers or network calls; the
gate is a local arithmetic challenge with no child data leaving the device; kid
mode shows coins only (never £); no red/danger styling on a wrong answer — the
retry is announced politely (`That wasn’t right — try again`, curly U+2019)
with no nagging; the backdrop is `ExcludeSemantics`d, so the dimmed scenery is
out of the a11y tree. Every control (10 digits + delete + `Back to Pip` +
`Try again`) exposes `SemanticsAction.tap` and the tests both assert
`hasAction` and `performAction` the real state/navigation change; the
`excludeSemantics: true` wrappers are display-only groups, so no `onTap:`
passthrough is owed.

**No blocker and no major findings.** The six items above are minor (two of
them are carried decisions rather than regressions), and none of them makes the
screen wrong: the feature suite is 106 pass / 1 skip / 0 red, `flutter analyze`
is clean, and the device measurement this iteration puts every design band
within ±2 px.

VERDICT: PASS