# Stage 4 — QA CODE REVIEW (iteration 2) · P08b · Today empty

Scope: `git diff main...HEAD` for P08b (branch `screen/P08b`, commit `7d106cb`
on top of main). Iteration 2 fixes the six Stage 3 proofs (P08b-T01…T06,
same root causes as Stage 6 P08b-B01…B05) inside the shared `TodayLoadedBody`
empty branch. No code edited in this stage — review only.

## Files reviewed (app diff)

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  (shared empty branch: `_EmptyGreeting` без top padding, `_EmptyCard` with
  DB-driven names + sky-underlined 44 px link row, `_TipCard` without gap)
- `app/lib/features/today/presentation/bloc/today_bloc.dart`
  (`nothingToDo = items.isEmpty || summaries.isEmpty` gates `A fresh nest`)
- `app/lib/features/today/data/today_repository_impl.dart`
  (age/nickname re-sort removed; `watchChildren` creation order kept)
- `app/lib/features/today/presentation/views/today_empty_view.dart`
  (comment-only)
- Tests: new `today_empty_view_test.dart` (51 tests), new `p08b_bugs_test.dart`
  (proofs + probed-clean pins), extended `today_bloc_test.dart`,
  `today_repository_test.dart`, `today_view_test.dart`

## Dimension results

1. **RULES.md isolation** — PASS. `git diff --name-only` outside
   `docs/screens/P08b/` is exactly the five `today`-feature paths above.
   No `app/lib/core/**`, `app/lib/app/**`, other feature, or `tools/**`
   touched. Router/seed/shell correctly left to the orchestrator
   (ORCHESTRATOR_NOTES item 7–8).
2. **ARCHITECTURE.md** — PASS. Feature-first kept: no domain/entity change,
   no repo-interface change, no new events, still one `TodayBloc` per
   feature, no DI/route edits, no use-case classes, no utils file
   (`emptyMessageSuffix` is feature-local presentation logic in the widget
   file, covered by widget tests).
3. **Design system / tokens** — PASS. All colours/spacing via
   `context.nest` tokens + `NestSpacing`/`NestDevice`; literals only for
   design-mandated art/measure (140 egg, 260 message width, 44 link floor).
   No hard-coded hex, no `letterSpacing` added in new code, no
   `google_fonts`, no v1 `pip_stage_*.svg` (`PipAvatar` v2, mochi·sunny
   stage 1 — `skin` defaults to `PipSkin.sunny`, verified at
   `pip_avatar.dart:235`). No `Wrap`/`Row` chip row (no chips on screen).
   `NestBalancedText` correctly NOT used: P08b's CSS sets no
   `text-wrap: balance` (`.greet h1` is a plain element rule), so plain
   `Text` with `maxLines: 2` is the faithful mapping.
4. **DESIGN_SPEC §5 P08b + HTML source** — PASS. Every element present:
   text-only greeting (no `+`, no avatar), date line, `.empty-card`
   (egg/h2/message/8 px spacer/primary/link row), `.card.inset` tip, tab bar
   via shell. Copy verified char-by-char against
   `design/html-source/screens/P08b-today-empty.html:13-15`, including the
   em dash / curly quotes / en dash in the tip and the middle dot in the
   date line. Orchestrator overrides honoured: names from DB in creation
   order, Oxford-comma-free, 0-child sentence dropped; `items.isEmpty ||
   summaries.isEmpty` predicate identical in bloc and view; P08 populated
   path byte-identical (demo seed always has items; sort removal does not
   move Maya→Leo demo/new-family order).
5. **Accessibility** — PASS. Greeting is a `header` node with no tap;
   art is a labelled `image` node with no tap; both CTAs expose
   `SemanticsAction.tap` and `performAction` navigates (tests pin this);
   link wrapper passes `onTap:` on the `Semantics(excludeSemantics: true)`
   node; greeting wraps to 2 lines instead of clipping at 320 px / 1.3×.
6. **Performance** — PASS. No new streams/subscriptions; bloc still uses a
   single `emit.forEach`; `_PushOnce` re-arm is a plain field write in a
   post-frame callback (safe post-dispose, no `setState`); `const`
   constructors used for static subtrees; no rebuild-storm shape.
7. **Error handling** — PASS. Loading spinner and `TodayFailureBody` paths
   unchanged; raw `errorMessage` stays in state, fixed kind copy on screen,
   `Try again` re-adds `TodayLoadRequested`.
8. **Children's Code** — PASS. Parent-mode screen; no analytics, ads,
   child contact data, or location; nicknames shown only to the parent.

## Findings

1. (minor) No test pins the empty-state Pip's style/skin/stage —
   `app/test/features/today/today_empty_view_test.dart` (geometry group
   checks the 140 px box and offsets, semantics group checks the image
   label, but nothing asserts `PipStyle.mochi` / `PipSkin.sunny` /
   `stage == 1`). Code is correct by inspection
   (`today_loaded_body.dart:833-835`, default `skin: sunny` verified), so
   this is test-gap only. Fix: add one `expect` over
   `find.byType(PipAvatar)` widget properties per 1_plan §f.5.
2. (minor) The two mock-repository tests in
   `app/test/features/today/today_empty_view_test.dart` (loading group and
   failure group) `pumpWidget` a real `TodayBloc` and never close it.
   Harmless here (mock `Stream.empty()` completes, no Drift scope/timer),
   but hygiene. Fix: `addTearDown(bloc.close)` (or `await bloc.close()`)
   in both tests.

No blocker or major findings. The six iteration-1 bugs are fixed at the
narrowest layer, P08's demo-seed path is untouched, and every orchestrator
item (ORCHESTRATOR_NOTES.md) is honoured.

VERDICT: PASS
