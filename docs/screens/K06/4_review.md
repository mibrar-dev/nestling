# K06 · QA code review (stage 4, iteration 1)

Scope: `git diff main...HEAD` on branch `screen/K06`. RULES §1 kept (only
`features/pip/**`, `test/features/pip/**`, `docs/screens/K06/**` plus one
documented test-only exception in `test/features/kid_home/kid_home_view_test.dart`,
already covered by `SHARED_REQUEST.md` §4 with orchestrator precedent P09 §3).
Checks run: `flutter analyze` → No issues found; `flutter test test/features/pip/` → 52 passed.

## Architecture

1. (pass) Feature-first shape preserved: entities + abstract repo in
   `domain/`, Drift impl in `data/`, one `PipBloc` per feature in
   `presentation/bloc/`, DI/routes untouched (`pip_di.dart`, `pip_routes.dart`
   unchanged on this branch).
2. (minor) `app/lib/features/pip/domain/entities/pip_nest.dart:26` —
   `pipStageName()` is display copy living in the domain layer;
   ARCHITECTURE.md §Per-feature contract says domain = entities + abstract
   repo ONLY. Move the helper to `presentation/` (e.g. next to
   `pip_look.dart`) in a later pass.
3. (minor) `app/lib/features/pip/data/pip_repository_impl.dart:185` —
   `_switchMap` is a near-verbatim duplicate of kid_home's
   `switchMapStream` (`kid_home_repository.dart:59`). RULES blocks the
   cross-feature import, so the fork is acceptable today, but it should be
   hoisted to `core/data/stream_combine.dart` (which already owns the
   combineLatest helpers) via a shared change, not grown further.

## Data correctness / RULES period & clock rules

4. (pass) No `DateTime.now()`, no clock-derived ids, no
   `subscription_status` writes. Bathe now costs 3 (design), feed 5, play
   free; all writes no-op when coins are insufficient; happiness clamps 0..5.
   Wardrobe order/names/prices come from the DB (175/250 growth, wellies 40,
   crown 120 render from seeded rows, never from the HTML numbers).
5. (pass) `watchNest()` re-emits on profile/wardrobe/active-child changes;
   care/buy/equip success paths carry no events, they rely on the stream —
   matches RULES §4. The `_nestSub` guard in `PipBloc._onLoadRequested`
   correctly applies the K03-BUG-15 pattern and releases on error/close, so
   the failure card's "Try again" still works.

## Design system & tokens

6. (pass) No hard-coded colours/sizes/fonts in new pip code: colours via
   `context.nest` tokens, spacings via `NestSpacing`, radii via `NestRadii`,
   text via `NestType`. `PipCareButton`/`PipWardrobeTile`/`PipNestSlot`/
   `PipGrowthCard` re-implement a kid button / dashed border / pet slot
   because the shared components cannot express them — each is filed in
   `SHARED_REQUEST.md` with a concrete need, not silently forked.
7. (pass) Pip renders via `PipAvatar` with the active child's
   style/skin/accessory/stage (orchestrator PIP rule); the neutral
   mochi/sunny fallback is used only on the load-failure card (no child
   known). No `flutter_svg` v1 `pip_stage_*` assets in product UI (only
   `nest.svg`/`coin.svg` art, which the design itself stacks).
8. (pass) `NestBalancedText` used on the `.kid-title` heading; no new
   letter-spacing added; fonts bundled (no `google_fonts` import anywhere
   in feature or tests — grep clean).

## Copy (character-exact vs `design/html-source/screens/K06-pip.html`)

9. (minor) `pip_nest_view.dart` section heading is `Pip’s wardrobe` with a
   curly U+2019, but the HTML source (line 71) has a straight `Pip's`
   (0x27). The plan ruled curly; the orchestrator COPY rule is
   character-exact vs HTML. Ratify one of the two — currently the PNG is
   unverifiable either way at this stage.
10. (minor) `kPipNotWearable` (`pip_nest_view.dart`) — "That one is not
    something Pip can wear." is the only on-screen string not in the design;
    the plan mandated a toast for owned-but-not-wearable taps without copy.
    Flag to orchestrator to ratify or replace.
11. (minor) `PipGrowthCard` progress semantics: "Pip is N percent of the
    way to a Songbird" vs the design's aria-label "Pip is 70% of the way to
    Songbird" (no article). Screen-reader-only deviation; align the string.

## Accessibility

12. (pass) Every interactive element exposes `SemanticsAction.tap`:
    back, lock (56×56 `NestLockButton`), Feed/Play/Bath (button+label+
    `enabled`, tap passed through the `excludeSemantics` wrapper), wardrobe
    tiles (`'<Name>, Owned'` / `'<Name>, <price> coins'`). Disabled care
    buttons report `enabled: false` with no tap action, per RULES §8.
    Tests assert tap-performs-real-DB-mutation.

## Performance / error handling / Children's Code

13. (pass) No rebuild storms: tap press states are local
    `StatefulWidget`s; the nest stream is a single subscription; the bloc
    cancels it on close. Widgets are `StatelessWidget`/const where
    possible; `PipCareButton` press is an `AnimatedContainer` driven by
    `NestMotion.resolve` (respects DISABLE_ANIMATIONS).
14. (pass) Load failure renders the friendly card + retry; wardrobe buy
    failure and unaffordable buy surface a kind toast without writing;
    care writes no-op on insufficient coins. No analytics, ads, network, or
    child-data leaks in kid mode.
15. (pass) Bottom-edge rule respected: no bottom bar on K06, the shared
    KidScope meadow runs to the physical edge, `NestHomeIndicator` last;
    both loading/failure chrome and the loaded screen use `_PipChrome`-style
    transparent scaffolds so no meadow/tinted strip shows under the OS
    indicator (light and dark via tokens).

## Tests

16. (pass) `test/features/pip/` covers the repository (Drift memory DB +
    Seed.demo: feed/bath costs, clamp, no-op paths, order/names/DB prices),
    the bloc (load/care/buy/equip/error-nonce), the view (title, avatar,
    progress, care labels, wardrobe from DB, caption em dash, semantics
    taps mutating the DB, back/lock navigation, dark, 320px @1.3x no
    overflow) and the widgets. All end with `disposeApp(tester)`.

VERDICT: PASS
