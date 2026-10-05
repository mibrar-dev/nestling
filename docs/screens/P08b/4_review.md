# Stage 4 — QA CODE REVIEW (iteration 3) · P08b · Today empty

Scope: `git diff main...HEAD` for P08b (branch `screen/P08b`, HEAD `3ea8e0c`
"checkpoint after build (iteration 3)"). Iteration 3 fixes the two Stage 3
proofs from iteration 2 (P08b-T07/B06 greeting cap, P08b-T08/B07 message cap)
by removing the two invented `maxLines` caps in the shared `TodayLoadedBody`
empty branch. No code edited in this stage — review only.

## Files reviewed (app diff)

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  (empty branch: `_EmptyGreeting` with no line cap, `_EmptyCard` with
  DB-driven names and no message cap, 44 px sky-underlined link row,
  flush `_TipCard`; populated P08 branch untouched)
- `app/lib/features/today/presentation/bloc/today_bloc.dart`
  (`nothingToDo = items.isEmpty || summaries.isEmpty` gates `A fresh nest`,
  same predicate as the body)
- `app/lib/features/today/data/today_repository_impl.dart`
  (age/nickname re-sort removed; `watchChildren` creation order kept)
- `app/lib/features/today/presentation/views/today_empty_view.dart`
  (comment-only)
- Tests: `today_empty_view_test.dart` (new, ~60 tests), `p08b_bugs_test.dart`
  (B01–B07 proofs now all live), extended `today_bloc_test.dart`,
  `today_repository_test.dart`, `today_view_test.dart`
- Design record: `design/html-source/screens/P08b-today-empty.html:2-15`,
  `design/html-source/components.css:43`,
  `docs/design/SPACING_SPEC.md` §§5/8/11

## Dimension results

1. **RULES.md isolation** — PASS. Every non-docs path in the diff is under
   `app/lib/features/today/**` or `app/test/features/today/**`
   (`git diff main...HEAD --name-only` minus `docs/screens/P08b/` returns
   only the 4 lib + 5 test files above; the inverse grep returns nothing).
   No `app/lib/core/**`, `app/lib/app/**`, other feature, or `tools/**`
   touched. Router/seed/shell correctly left to the orchestrator
   (ORCHESTRATOR_NOTES items 5–6: no `router.dart`/`seed.dart` edits).
2. **ARCHITECTURE.md** — PASS. Feature-first kept: no domain/entity change,
   no repo-interface change, no new events, still one `TodayBloc` per
   feature with `TodayLoadRequested` only, no DI/route edits, no use-case
   classes, no utils file. `emptyMessageSuffix` is feature-local
   presentation logic in the widget file, unit-tested directly.
3. **Design system / tokens** — PASS. All colours/spacing via `context.nest`
   tokens + `NestSpacing`/`NestDevice`/`NestType`; literals only for
   design-mandated art/measure (140 egg, 260 message width, 44 link floor).
   No hard-coded hex, no `letterSpacing` added in new code (the two
   `letterSpacing` hits at `today_loaded_body.dart:369,381` are pre-existing
   P08 populated-greeting code, untouched by this diff, matching the −1%
   tracking in SPACING_SPEC §0), no `google_fonts` anywhere in lib or tests,
   no v1 `pip_stage_*.svg` (`PipAvatar` v2, mochi stage 1 at 140, `skin`
   defaults to `PipSkin.sunny` verified at `pip_avatar.dart:235`). No
   `Wrap`/`Row` chip row (no chips on screen). `NestBalancedText` correctly
   NOT used: P08b's CSS sets no `text-wrap: balance`, so plain `Text` is the
   faithful mapping. `NestChipWrap` N/A (no chip row).
4. **DESIGN_SPEC §5 P08b + HTML source** — PASS. Every element present:
   text-only greeting (no `+`, no avatar), date line `Sat 3 Oct · A fresh
   nest` (day part from the pinned clock, suffix from the screen),
   `.empty-card` (egg/h2/two-sentence message/8 px spacer/52 px primary/44 px
   link row), `.card.inset` tip, tab bar via shell with Today active.
   Copy verified char-by-char against the HTML source: em dash / curly
   quotes / en dash in the tip (`— “Make your bed” … “Reading – 20
   minutes”`), middle dot in the date line, `Maya and Leo` two-name message.
   Orchestrator overrides honoured: names from DB in creation order,
   Oxford-comma-free (`Maya, Leo and Zara`), 0-child sentence dropped;
   `items.isEmpty || summaries.isEmpty` predicate identical in bloc and
   view (broader than "summaries.isEmpty" shorthand but correct: an
   unassigned "Anyone" quest leaves `items` empty and the nest really is
   empty — pinned by test); P08 populated path untouched (demo seed always
   has items; sort removal keeps Maya→Leo demo/new-family order).
5. **Accessibility** — PASS. Greeting is a `header` node with no tap; art is a
   labelled `image` node (`Pip the bird as a speckled egg`) with no tap; both
   CTAs expose `SemanticsAction.tap` and `performAction` navigates (tests pin
   this); link wrapper passes `onTap:` on the `Semantics(excludeSemantics:
   true)` node per the ACCESSIBILITY ACTIONS rule; no unlabelled
   `excludeSemantics` button remains. Iteration-3 removals are the a11y fix:
   greeting and message now wrap instead of ellipsising names (B06/B07
   proofs live and green). Tap targets: primary 52, link row exactly 44.
6. **Performance** — PASS. No new streams/subscriptions; bloc still a single
   `emit.forEach`; `_PushOnce` re-arm is a plain field write in a
   post-frame callback (safe post-dispose, no `setState`); `const`
   constructors for static subtrees; no rebuild-storm shape. `clock.now()` /
   `appNowUtc()` only, no `DateTime.now()`; `newId` N/A (no new rows).
7. **Error handling** — PASS. Loading spinner and `TodayFailureBody` paths
   unchanged; raw `errorMessage` stays in state, fixed kind copy on screen,
   `Try again` re-adds `TodayLoadRequested`; stream errors close via
   `_closeOnError` so retries do not leak subscriptions.
8. **Children's Code** — PASS. Parent-mode screen; no analytics, ads, child
   contact data, or location; nicknames shown only to the parent; kind
   framing throughout ("Your nest is quiet", "will see it straight away").

## Findings

1. (minor) Stale header comment — `app/test/features/today/today_empty_view_test.dart:15-17`
   still says the geometry group "currently fails — see `3_test.md`
   (P08b-T01/T02/T03)". Those proofs turned green in iteration 2 and T07/T08
   turned green in iteration 3. Docs only, no behaviour impact. Fix: update
   the comment to say all geometry pins are green.
2. (minor) Stale comment — `app/test/features/today/p08b_bugs_test.dart:90`
   still says "B06–B07 skipped until fixed". Both proofs now run live
   (no `skip:` remains in the `today` feature). Docs only. Fix: reword to
   "B01–B07 fixed and live".
3. (minor) Test gap carried forward — no test pins the empty-state Pip's
   `style`/`skin`/`stage` (`today_empty_view_test.dart` checks the 140 px box
   and offsets, the semantics group checks the image label, but nothing
   asserts `PipStyle.mochi` / `PipSkin.sunny` / `stage == 1`). Code is correct
   by inspection (`today_loaded_body.dart:833-835`, default `skin: sunny`
   verified at `pip_avatar.dart:235`), so test-gap only. Fix: add one
   `expect` over `find.byType(PipAvatar)` widget properties per 1_plan §f.5.
   (Re-filed from the iteration-2 review; still open.)
4. (minor) The two mock-repository widget tests in
   `app/test/features/today/today_empty_view_test.dart:447` (loading) and
   `:479` (failure) `pumpWidget` a real `TodayBloc` and never close it.
   Harmless here (finite mock streams, no Drift scope/timer), but hygiene.
   Fix: `addTearDown(bloc.close)` in both tests (the pattern already used at
   `:1454`). (Re-filed from the iteration-2 review; still open.)
5. (minor) Defensive cap on static copy —
   `app/lib/features/today/presentation/widgets/today_loaded_body.dart:914`
   (`maxLines: 4` on the tip caption). The design sets no cap, but the copy
   is static and fits in ≤4 lines at every supported size (320 px @1.3x needs
   exactly four — pinned green by the size-matrix test), so the cap can never
   trigger. No behaviour impact. Fix (optional): drop the cap for strict CSS
   fidelity, or leave as-is.

No blocker or major findings. The iteration-2 defects (T07/B06, T08/B07) are
fixed at the narrowest layer (two `maxLines` removals with CSS-cited
comments), P08's demo-seed path is untouched, the `today` feature has zero
skipped tests, and every ORCHESTRATOR_NOTES.md item is honoured.

VERDICT: PASS
