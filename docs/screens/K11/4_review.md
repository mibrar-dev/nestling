# K11 · Badges — stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` for feature `badges` (route `/badges`, kid mode) against
docs/ARCHITECTURE.md, docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K11,
docs/design/SPACING_SPEC.md (§§7–8/10–11), docs/screens/K11/1_plan.md, and the
orchestrator rules (including `docs/screens/K11/ORCHESTRATOR_NOTES.md`, mandatory).
No code edited in this stage.

Files reviewed: `app/lib/features/badges/data/badges_repository_impl.dart`,
`domain/badges_repository.dart`, `domain/entities/badges_data.dart`,
`presentation/bloc/badges_{bloc,event,state}.dart`,
`presentation/views/badges_view.dart`,
`presentation/widgets/{badge_grid_cell,happy_week_card}.dart`,
`app/test/features/badges/*.dart`, `docs/screens/K11/{1_plan,3_test,5_ui,6_bugs}.md`,
`SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`,
`design/html-source/screens/K11-badges.html`.

## Compliance (all pass)

- **RULES §1 paths:** diff touches only `app/lib/features/badges/**`,
  `app/test/features/badges/**`, `docs/screens/K11/**`. No `core/`, `app/`,
  other-feature, or `tools/` edits. `SHARED_REQUEST.md` (nine design badges,
  Blocks: no) is satisfied — seed landed on main as `shared/k11_badges_seed`
  and the `TODO(K11)` is gone (grep finds no `TODO` under the feature).
- **Architecture:** one bloc per feature (`BadgesLoadRequested` + initial/loading/
  loaded/failure); internal `BadgesDataReceived`/`BadgesStreamFailed` are
  bloc-private (views never send them) and exist only because Drift watch streams
  never close — the K08 guard precedent, preserving RULES §4 ("never re-add load
  events"). Domain = entities (`badge.dart`, `badges_data.dart` Equatable) +
  abstract repo only; no use-cases, no extra folders. DI/routes untouched and
  correct (`badges_di.dart` lazy-singleton repo + factory bloc;
  `badges_routes.dart` route-level `BlocProvider` + `BadgesLoadRequested`).
- **Iteration-1 findings closed:** constructor `new` removed
  (`badges_repository_impl.dart:12`, `badges_bloc.dart:10` modern syntax);
  `happyDays` clamped (`happy_week_card.dart:37-38,67` — dots and why-line both
  use the clamped value); loading/loaded clear stale errors via dedicated
  `copyWithLoading`/`copyWithLoaded` (`badges_state.dart:51-74`), so the generic
  `copyWith` retaining `errorMessage` is now failure-path only.
- **ORCHESTRATOR_NOTES (mandatory, all done):** no `seed.dart` edit by this
  branch; all nine design ids map to their own medal in `_artFor`
  (`badge_grid_cell.dart:35-45`) with ribbon fallback only for unknown ids
  (pinned by `badges_art_test.dart`); `TODO(K11)` removed; K11-BUG-2 fixed (no
  `'maya'` literal remains — `_resolveChildId` uses persisted id else first
  child in creation order else empty shelf); K11-BUG-1 fixed (clamp 0..7).
- **Design system / tokens:** everything via `context.nest` / `nestKid` /
  `NestSpacing` / `NestDevice` / `NestRadii` / `NestType`. File-local consts
  (back chevron 26, medal 60, dot 38, 15/19 + 14/18 type, 10/4 + 14/12 padding,
  4/12 gaps) each cite the HTML line and match SPACING_SPEC screen-local
  geometry — not hard-coded palette/scale. No `Color(0x`, no hex, no
  `letterSpacing` (NestType default 0 holds; K11 has no tracking case). Grid
  uses `Expanded` slots (never fixed 108.67); dots use
  `LayoutBuilder min(38,(w-24)/7)`. `KidScope` shared sky+meadow, transparent
  Scaffold, explicit 34 px home reserve painting nothing — BOTTOM EDGE holds.
  `NestBalancedText` on `.kid-title` only. No chips/Pip/avatars/£ (PIP N/A;
  jar-only £ holds); `Row` uses here are layout rows, not chip rows.
- **Copy (char-exact vs HTML):** `My badges`; repo-owned `Got it!` /
  `Keep going!` (view never remaps); `×` U+00D7 from DB title; week line em
  dash U+2014 + curly ’ U+2019 verified in source; `M T W T F S S`; `Back` /
  `Grown-ups` labels; DB-driven subtitle/why with flagged zero-state kid voice
  per plan §c–d. UK spelling clean. HTML `<button class="k11-b">` tiles are
  intentionally static — no detail route exists in the nav map, so no
  onTap/toast/sheet was invented (plan §c).
- **Accessibility:** back/lock expose tap via design-system buttons; stage-3
  tests prove `hasAction(tap)` + `performAction(tap)` drives real navigation
  with the double-tap single-push guard. Static tiles carry one merged label
  with `excludeSemantics: true` and no tap action — correct because they are
  not controls (RULES §8 `onTap` applies to wrapped controls). Spinner labelled
  `Loading badges`. 56 px targets, 1.0–1.3 clamp, 2-line ellipsis.
- **Performance/errors/Children's Code:** `BlocBuilder` scoped to body; const
  chrome; no timers/controllers; `_sub` cancelled on `close()` and released on
  error so `Try again` works; loading/failure/empty keep chrome mounted with
  generic kid-safe copy (raw errors never shown). No analytics/ads/location/
  photos; positive framing, no loss-aversion. No `DateTime.now` / `clock` /
  `newId` / `google_fonts` in lib (test files mention the rule in comments
  only). No `flutter clean`, no simulator, no global kills.

## Findings

1. (minor) `app/lib/features/badges/data/badges_repository_impl.dart:129` —
   `_switchMap` drops the previous inner subscription with
   `unawaited(innerSub?.cancel())`, so old and new inners overlap briefly and
   a racing old emission could forward once. Carried from iteration-1 finding 3;
   stage-6 probe (10 switch+write bursts) proved no stale child emission lands,
   and Drift cancels promptly, so hardening only. Fix (if ever touched): await
   the cancel before subscribing, or gate emissions with a generation counter.

No blocker or major findings.

## Verification evidence

- `flutter analyze app/lib/features/badges app/test/features/badges` → No issues found.
- Grep: no `Color(0x`, no `GoogleFonts`, no `DateTime.now`, no `'maya'` literal,
  no `TODO`, no `letterSpacing`, no `PipAvatar` (N/A — no Pip on K11).
- Stage-3 suite (120 tests, `--timeout 120s`, `disposeApp` where the app is
  pumped) and stage-5 UI check (all rects ±2 px, DB-driven shelf excluded) and
  stage-6 probes already on file; this stage re-read the code rather than
  re-running the full suite.

VERDICT: PASS
