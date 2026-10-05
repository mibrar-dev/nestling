# K11 · Badges — stage 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` for feature `badges` (route `/badges`, kid mode) against
docs/ARCHITECTURE.md, docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K11,
docs/design/SPACING_SPEC.md, docs/screens/K11/1_plan.md, and the orchestrator rules.
No `ORCHESTRATOR_NOTES.md` exists (verified — no mandatory notes). No code edited in this stage.

Files reviewed: `app/lib/features/badges/data/badges_repository_impl.dart`,
`domain/badges_repository.dart`, `domain/entities/badges_data.dart`,
`presentation/bloc/badges_{bloc,event,state}.dart`, `presentation/views/badges_view.dart`,
`presentation/widgets/{badge_grid_cell,happy_week_card}.dart`,
`app/test/features/badges/{badges_bloc_test,badges_repository_test,badges_view_test,
badges_widget_geometry_test}.dart`, `docs/screens/K11/{1_plan,2_build,2a_build_logic,2b_build_ui}.md`,
`SHARED_REQUEST.md`, `design/html-source/screens/K11-badges.html`.

## Compliance (all pass)

- **RULES §1 paths:** diff touches only `app/lib/features/badges/**`,
  `app/test/features/badges/**`, `docs/screens/K11/**`. No `core/`, `app/`, other-feature,
  or `tools/` edits. `SHARED_REQUEST.md` filed (seed nine badges, Blocks: no) with matching
  `TODO(K11)` in `badges_view.dart:326`. The legacy 8-row seed renders in DB order behind it —
  correct process use, not a finding.
- **Architecture:** one bloc (`BadgesLoadRequested` + Status initial/loading/loaded/failure);
  internal `BadgesDataReceived`/`BadgesStreamFailed` are bloc-private (views never send them) and
  exist only because Drift watch streams never close — the documented K08 guard precedent, intent
  of RULES §4 ("never re-add load events") preserved. Domain = entities + abstract repo only;
  no use-cases, no extra folders. DI/routes untouched and correct (route-level `BlocProvider` +
  `BadgesLoadRequested`). `BadgesData` is an Equatable entity, not a use-case.
- **Design system / tokens:** everything resolves via `context.nest` / `NestSpacing` /
  `NestDevice` / `NestRadii` / `NestType` / `NestKidButton` etc. File-local consts
  (medal 60, dot 38, back chevron 26, 15/19 + 14/18 type, 10/4 + 14/12 padding) each cite the
  HTML line and match SPACING_SPEC screen-local geometry — not hard-coded palette/scale.
  No hex, no `Color(0x`, no `letterSpacing` (NestType defaults 0 hold). `KidScope` shared
  sky+meadow, transparent Scaffold, explicit 34 px home reserve with nothing painted —
  BOTTOM EDGE holds. `NestBalancedText` on the `.kid-title` only. No chips/Pip/avatars/£ on
  this screen (all N/A per spec: no Pip, jar-only £ rule holds).
- **Copy (char-exact vs HTML):** `My badges`; `Got it!` / `Keep going!` (owned in repo, view never
  remaps); `Bed maker ×7` (U+00D7); week line em dash U+2014 + curly ’ U+2019;
  `M T W T F S S`; `Back` / `Grown-ups` aria labels; DB-driven subtitle/why with flagged
  zero-state kid voice per plan §c–d. UK spelling clean.
- **Art:** `_artFor` keys all nine design ids to `NestlingIllustrations.badge*` (earned ids map to
  the colourful assets, todo ids to the grey not-yet assets — the files themselves carry the
  state, so "border+sub only" is correct); unknown legacy ids fall back to neutral ribbon, never
  a wrong badge. Static cells are correct: no detail route exists in the nav map, so no tap/toast/
  sheet was invented; merged `Semantics(label: "<name>, <detail>")` with art excluded.
- **Accessibility:** back/lock expose `SemanticsAction.tap` via design-system buttons and tests prove
  `performAction(tap)` drives real navigation both ways + single-push double-tap guard. Static tiles
  carry no tap action (not controls — RULES §8 `onTap` requirement applies to wrapped *controls*).
  Spinner labelled `Loading badges`. 56 px targets, 1.0–1.3 clamp, 320 px `LayoutBuilder` dot
  shrink (`min(38, (w−24)/7)`), 2-line ellipsis everywhere.
- **Performance/errors/Children's Code:** `BlocBuilder` scoped to body; const chrome; no
  timers/controllers; `_sub` cancelled on `close()` and released on error so `Try again` works;
  loading/failure/empty keep chrome mounted with generic kid-safe copy (raw errors never shown).
  No analytics/ads/location/photos. No `DateTime.now` / `google_fonts` / clock / `newId` in lib
  (one test comment mentions the rule only). No simulator, no `flutter clean`, no global kills.

## Findings

1. (minor) `app/lib/features/badges/data/badges_repository_impl.dart:11` — constructor still uses
   legacy `new({required this._db})` while bloc/events/state moved to modern syntax. Fix: drop
   `new` (`BadgesRepositoryImpl({required AppDatabase db ...})` keeps the field name or rename
   consistently). Style only; analyze clean.
2. (minor) `app/lib/features/badges/presentation/widgets/happy_week_card.dart:86,97` —
   `happyDays` is used unclamped for both dots (`i < happyDays`) and `HappyWeekCopy.why`. Seed
   guarantees 0…7 today, but a value >7 would fill all 7 dots while the line claims e.g. "8 happy
   days". Fix: `final n = happyDays.clamp(0, 7);` at the top of `build`/`why` and use `n`.
3. (minor) `app/lib/features/badges/data/badges_repository_impl.dart:99` — `_switchMap` drops the
   previous inner subscription with `unawaited(innerSub?.cancel())`, so old and new inners overlap
   briefly and a racing old emission could forward once. Tests prove the covered interleavings emit
   no stale child, and Drift cancels promptly, so this is hardening only. Fix (if ever touched):
   await the cancel before subscribing, or gate emissions with a generation counter.
4. (minor) `app/lib/features/badges/presentation/bloc/badges_state.dart:31-43` — `copyWith`
   retains a stale `errorMessage` when moving to `loading` (`errorMessage ?? this.errorMessage`).
   Harmless (view shows generic copy; `copyWithLoaded` clears), but loading should start clean.
   Fix: pass `errorMessage: null` explicitly on the loading path or make `copyWith` clear on
   `status: loading`. Do not change failure-path behaviour.

No blocker or major findings. Backlog items correctly left open: seed nine-badge correction
(shared, Blocks: no) and stage-5 UI check.

## Verification evidence

- `dart format` on `lib/features/badges` + `test/features/badges`: 0 changed.
- `flutter analyze`: No issues found.
- `flutter test --timeout 120s test/features/badges`: all passed on retry (first attempt hit a
  transient `NativeAssetsManifest.json` copy race in the build dir; retried without `flutter clean`
  per the ban and went green — infra flake, not a code finding).

VERDICT: PASS
