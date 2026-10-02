# P03 Create account — QA code review (Stage 4, iteration 4)

Scope reviewed: `git diff main` for P03 — `app/lib/features/auth/**` (view, bloc,
domain, data, glyph widgets) + `app/test/features/auth/**` + `docs/screens/P03/**`.
No code was edited by this stage. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03 (line 150) and §0.9,
`docs/design/SPACING_SPEC.md` §3, `design/html-source/screens/P03-create-account.html`,
`design/html-source/components.css:129-135`, `ORCHESTRATOR_NOTES.md` (**all items
mandatory**), the standing **COPY** rule, `1_plan.md`, `FIXES_1…3.md`, `2_build.md`,
`3_test.md`, `SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **142 passed, 1 skipped, 2 failed**; the two red
  are `p03_bugs_test.dart` `P03-BUG-16` and `P03-BUG-21`.
- Copy bytes: `od -c` on the subtitle shows `Y o u 342 200 231 r e` = U+2019 — the
  straight apostrophe is gone and the copy audit is green.
- Flutter SDK: `rendering/proxy_box.dart:4399-4420` — `RenderExcludeSemantics
  .visitChildrenForSemantics` returns without visiting anything while excluding, so
  the `Text`'s node and label are dropped and only the wrapper's flags survive.
- Pixel measurement, `docs/screens/P03/ui/light.png` vs
  `design/screens/light/P03-create-account.png`: CTA hairline **678 vs 677**; submit
  button **694–745** (design 694–745); caption line 1 one sky run x 262–300 (design
  258–297) = "Terms", line 2 x 149–241 (design 150–240) = "Privacy Notice"; CTA
  `surface` uniform to y=844. Layout is unchanged from iteration 3 and within 1–4dp.
- `git status` touches only `app/lib/features/auth/**`, `app/test/features/auth/**`,
  `docs/screens/P03/**` — RULES §1 respected.

## Iteration-3 findings — all seven addressed

| # | Iteration-3 finding | Status |
|---|---|---|
| 1 | BLOCKER — red suite; BUG-11/BUG-16 mutually exclusive | **in scope half done**: BUG-15 fixed so only the shared-blocked pair remains — see finding 1 |
| 2 | MAJOR — straight apostrophe | **closed** (U+2019 byte-verified, copy audit 10/10 green) |
| 3 | MINOR — subtitle breaks a word early (shared §6) | **no local change, correctly** — not chased with a token-violating hack |
| 4 | MINOR — 44dp targets only ~32dp reachable | **closed** (`_HitTestExpand` + a real `tapAt`/hit-path probe; see findings 3–4 for hardening) |
| 5 | MINOR — post-frame measurement could go stale | **closed** (synchronous `TextPainter` mirror + bounded verification chain; five proofs compare built rects against the real paragraph) |
| 6 | MINOR — no live region on the owned error rows | **attempted, regressed** — the flag is set but the node is empty (finding 2) |
| 7 | MINOR — `height: 20 / 13` token debt | **closed** (`NestSpacing.s5 / 13`, `SHARED_REQUEST.md` §7 filed) |

I also re-audited the new proof machinery rather than taking it on trust: the
mirror-vs-paragraph equality proofs compare built rects to the real `RenderParagraph`'s
own glyph boxes at 320/390/430 × 1.0/1.3, and the `P03-BUG-18` proof probes the real
hit path with taps rather than reading sizes. Both are the right shape — the proofs
that were blind in iteration 3 now test the thing that was actually wrong.

## Checked and clean (no finding)

- **Architecture** — `domain/` holds only the entity folder plus the abstract repository;
  one bloc per screen from `registerAuth`, provided at the route level; route-path
  constants only for cross-feature navigation; no use-case classes; all
  `package:nestling/...` imports.
- **RULES §4** — password never persisted; owner row idempotent; legacy
  `createAccount(name:)` alias still documented for the one shared caller.
- **Geometry (device vs design)** — CTA hairline 678 vs 677, submit button 694–745 in
  both, caption break and link positions within 4dp, note/helper/headline/brand buttons
  unchanged from iteration 3 (0–2dp). The bottom-edge OWNER rule holds in both themes
  (uniform `surface` to y=844, no page tint, no ring around the home area) and the 20px
  gutters are untouched.
- **Design system** — only DS components; `NestBottomCta.caption` still avoided; the
  caption's line-height override is now expressed with `NestSpacing.s5` and is pinned by
  `P03-BUG-12`; the two brand glyphs remain the HTML's own artwork. The `_HitTestExpand`
  shim is *not* a re-implemented component: I checked the layout-only alternative and it
  is impossible at this geometry — a 44dp box centred on a 20dp line inside a two-line
  40dp caption needs a **64dp** parent to be fully reachable, which would move the
  hairline 24dp off the design. Bypassing the parent bounds check is the only way to
  honour both the 44dp rule and the design's panel height, and it changes no layout.
- **Rebuild scoping / lifecycle** — brand buttons on `BlocSelector(isSubmitting)`, fields
  on `buildWhen` error selectors, CTA on `canSubmit`; `_LegalLine` is still `const` and
  only re-lays out on real change; controllers disposed; the bloc's `watchItems()`
  subscription is route-scoped; no timers or animations.
- **Copy** — all nine user-facing strings byte-identical to the HTML (U+2019, U+2014, the
  single U+00A0 in "Privacy Notice"), each pinned by its own assertion so one deviation
  cannot mask another.
- **Error handling** — both submits `on Object catch` + `addError`, so no path can strand
  the spinner, and the failure is announced.
- **Children's Code / privacy** — parent-mode only; no analytics, ads, network calls,
  child data or photo/location surfaces; the copy states the privacy position.
- **Accepted trade-offs (documented in code, not defects)** — `_shownTerms`/`_shownPrivacy`
  are plain State fields assigned during build (safe: no `setState`), and the lateral
  overlap of the two targets mirrors the HTML's inline hit boxes.

## Findings

### 1. BLOCKER — red suite: one in-scope regression (finding 2) and one proof that needs a decision, not a re-run

`app/test/features/auth/p03_bugs_test.dart` — `P03-BUG-21` (in scope) and `P03-BUG-16`
(shared-blocked). RULES §7 requires `flutter test` → all pass.

`P03-BUG-16` is the pair I flagged in iteration 3: `NestTextField` drives the danger
border and Material's indented error row off the same `errorText != null`, so P03 cannot
have both the gutter-aligned error and the red invalid border. The screen is right that
re-passing `errorText` re-opens a major, and `SHARED_REQUEST.md` §5 says **"Blocks: yes"**.
What the loop needs now is a *stable* disposition instead of the delete/restore
oscillation of this iteration:

- keep the proof in the file but **skip it with an explicit reason** —
  `skip: 'SHARED_REQUEST.md §5 — NestTextField has no independent hasError flag'` — so
  the guard stays documented and visible, the suite is green, and the shared fix lands
  with the proof ready to un-skip; or
- land the shared `hasError`/`errorBorder` flag on `main` (§5) and keep the proof red
  until P03 consumes it.

Deleting the proof (as this iteration did) hides a real defect; leaving it red (as now)
keeps the branch unlandable. A skip-with-reason is the only option that satisfies both.

`P03-BUG-21` is a one-line fix — finding 2.

### 2. MAJOR — the validation error left the semantics tree: an empty live region

`create_account_view.dart:190-201` (email) and `:246-258` (password):

```dart
Semantics(
  liveRegion: true,
  child: ExcludeSemantics(
    child: Text(state.emailError!, …),
  ),
),
```

`ExcludeSemantics` removes the `Text`'s own node — `RenderExcludeSemantics
.visitChildrenForSemantics` returns without visiting the subtree while excluding
(`rendering/proxy_box.dart:4399-4420`) — and the wrapper supplies a **flag, not a
label**. The result is a node with `isLiveRegion: true` and an empty label: VoiceOver
announces an empty live region and the message is not in the tree to navigate to either.
That is worse than the iteration-3 behaviour (a plain labelled `Text`) and worse than
Material's own row, which is a live region *with* content.

The wrapper only works when `ExcludeSemantics` is paired with an explicit label — my
iteration-3 wording ("keep the inner `Text` out of semantics so the label is read once")
omitted that pairing, and the build followed it literally.

Fix (either form):
```dart
Semantics(
  liveRegion: true,
  label: state.emailError!,
  child: ExcludeSemantics(child: Text(state.emailError!, …)),
),
```
or simply drop the `ExcludeSemantics` — with no explicit `label:` there is nothing to
double up, and the `Text`'s own node is exactly what you want inside a live region.

Proof gap to close as part of the fix: the existing `P03-BUG-20` proof does
`tester.getSemantics(find.text(error))`, which resolves to the *nearest enclosing* node
(the empty live region) and asserts only `isLiveRegion` — so it passed while the label
was gone. Add the label assertion (and that the node is findable via
`find.bySemanticsLabel('Enter a valid email address')`) so this cannot regress again.

### 3. MINOR — `_HitTestExpand.extra` is dead code, and its value is coincidental

`create_account_view.dart:294` (call site `extra: (NestDevice.tapParent - NestSpacing.s5) / 2`)
and the `_RenderHitTestExpand` field/setter. `hitTest` never reads `extra` — the extra
reach comes from each target's own 44dp box — yet `updateRenderObject` assigns it and
calls `markNeedsPaint()`, which a hit-test-only property does not need (it can cause a
pointless repaint on every bar rebuild). The name also promises an expansion the
mechanism never performs.

Fix: delete `extra`, the setter and the `markNeedsPaint()` (and the `extra:` argument at
the call site), or — if the bound is meant to be enforced — actually use it to clamp the
fallback pass and document the relationship. The current expression ties the overhang to
`NestSpacing.s5` (20), which happens to equal the caption line height but is unrelated to
it; if the caption line height ever changes (e.g. when `NestType.legalCaption` lands from
`SHARED_REQUEST.md` §7) the number silently stops describing reality.

### 4. MINOR — the extra hit-test pass fires even when the normal path already claimed the tap

`create_account_view.dart` `_RenderHitTestExpand.hitTest` (`:hitTest`, the
`stack.visitChildren` block). The fallback pass runs for any position outside the caption
stack, **including positions the normal path already delivered** — and the Terms target
overlaps the submit button's last ~4dp (measured on the capture: button 694–745.7,
caption line 1 centre ≈763.7 → target top ≈741.7). A tap in that strip is therefore
delivered to both: the submit button activates *and* the link's `onTap` fires. It is
inert today only because the links are no-ops (`TODO(P03)`); the moment the Terms/Notice
routes exist, that strip becomes a double activation.

Fix: run the fallback only when nothing was hit — `if (!hit && !stackRect.contains(position)) { … }`
— which is the entire purpose of the pass (recovering taps the bounds-check dropped) and
removes the overlap without touching geometry. Add a `tapAt` proof for a point inside
the submit button asserting the link's `onTap` does **not** also run.

### 5. MINOR — `_verifyTotal` is a lifetime cap, so the safety net dies permanently

`create_account_view.dart` `_scheduleVerify` / `_verifyTotal` / `_verifyTotalCap = 12`.
`_verifyTotal` only ever increases and is never reset, so after 12 verifications
`_scheduleVerify` returns early **forever** for that `State`: every later
`didChangeDependencies` (theme switch, text-scale change, rotation) re-arms `_verifyLeft`
but can no longer schedule anything, and the font-swap drift detection is permanently off.
The hard stop is needed (it is what guarantees `pumpAndSettle` terminates) but it should
bound a *chain*, not the widget's lifetime.

Fix: reset `_verifyTotal = 0` in `didChangeDependencies` alongside `_verifyLeft`, keeping
the per-chain budget; the chain still stops after `_verifyBudget` quiet passes.

### 6. MINOR — `SHARED_REQUEST.md` §5 no longer describes the agreed disposition

`docs/screens/P03/SHARED_REQUEST.md` §5 still reads "the screen cannot converge on both
proofs until this lands (P03 keeps the visible gutter fix and leaves `P03-BUG-16`
skipped…)", while the proof is currently **red** again (restored this iteration) and the
build deleted it in between. Update §5 to state the current decision — skip-with-reason
pending the shared `hasError` flag — so the orchestrator and the next build stop
oscillating on it.

## Notes for the next stage

- Fix 2 (three lines) and apply 1's skip-with-reason, then 3, 4, 5 — all in
  `create_account_view.dart` plus one test annotation. Nothing else in the screen needs
  touching: the layout is within 1–4dp of the design, the caption break matches, the
  bottom edge and gutters hold in both themes, the copy audit is green, and the proof
  machinery is sound.
- Iteration-3 finding 3 (subtitle break) stays with `SHARED_REQUEST.md` §6 — it is a
  font-pipeline difference, and any local "fix" would be a token violation.
- `ORCHESTRATOR_NOTES.md` iteration-3 item 3 (filled-state simulator capture) is still
  outstanding for the UI stage; the filled state itself is pinned by the
  "design filled state" widget group.

VERDICT: FAIL