# Stage 2b — build UI chunk (iteration 1)

P08b Today empty · parent · light/dark. Feature `today`.

## What changed

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  - Shared empty state now pixel-matches P08b and is the ONE empty state
    for the whole app (orchestrator note): `/today` and `/today-empty`
    both render it when `state.items.isEmpty || state.summaries.isEmpty`
    (no active quests feed, or no children). The populated P08 path is
    untouched — demo seed always has quests, so P08 renders byte-identically.
  - `_EmptyGreeting` (new private widget): `NestType.h1` 28/34 title
    (`$greeting, $parentName`) + date line 15/22 w500 ink-2. NO plus
    button, NO avatar — the populated `_Greeting` keeps both.
  - `_EmptyCard` rewritten: `NestCard(standard, padding 28/20)`, column
    gap 8; `PipAvatar(mochi, stage 1, size 140)` wrapped in
    `Semantics(image: true, label: 'Pip the bird as a speckled egg',
    child: ExcludeSemantics(...))`; h2 22/28 title; ink-2 message in a
    260 max-width `ConstrainedBox`; 8 px spacer; `NestButton('Add a
    quest')` (primary, 52); link row `Semantics(button, excludeSemantics,
    onTap)` + `InkWell`, vertical padding 12, underlined sky 15/22 w600,
    min height 46 (≥ 44). `NestEmptyState` no longer used here (its h3,
    160 art box and insets did not match).
  - Message copy built from DB children (creation order): 0 → first
    sentence only; 1 → "… Maya will see it straight away."; 2 → "… Maya
    and Leo will see it straight away."; 3+ → UK comma-free
    "… Maya, Leo and Ava will see it straight away.". Names come from
    `state.summaries` (sorted eldest-first; identical to creation order
    for the demo/new-family seeds).
  - `_TipCard` added: `NestCard(variant: inset)`, padding 16, radius 24,
    no shadow; `bodySmallStrong` "Tip for new nests" + caption tip body
    with byte-exact curly quotes and em/en dashes.
- `today_empty_view.dart`: doc-comment updated; still renders the shared
  `TodayLoadedBody` (now with the P08b empty branch) per the note — no
  separate empty view.
- `app/test/features/today/today_view_test.dart`:
  - Fixed the enshrined bug: `/today-empty` message assertion now expects
    the Seed.empty copy (first sentence; names sentence omitted with 0
    children), plus tip title/body byte-exact copy.
  - Added: dark-theme same-copy test; 320 px + 1.3× scroll test through
    the tip (no exception, link ≥ 22 text height inside a ≥ 44 hit area).

## Contract notes (2a)

- 2a landed the `dateLine` change in `today_bloc.dart`:
  `${formatLondonDay(now)} · ${summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}`.
  UI consumes `state.dateLine` verbatim — no contract change needed.

## Verification

- `flutter analyze lib/features/today` → No issues found.
- `flutter test --timeout 120s test/features/today/today_view_test.dart`
  → 53 passed.
- `dart format` on touched files → clean.

## LEFT FOR NEXT ITERATION

- SHARED_REQUEST (filed): move `/today-empty` into the Today
  StatefulShellBranch in `app/lib/app/router.dart` — required for the
  tab bar and owner bottom-edge rule; not editable by this stage.
- Seed `new_family` (Sarah + Maya + Leo, no quests) merge will exercise
  the 2-name message variant; Seed.empty exercises the 0-name variant
  today. Consider an explicit widget test against `new_family` once it
  lands on main.
- Bottom-edge + tab-bar presence on `/today-empty` can only be
  asserted after the shared router merge.

VERDICT: PASS
