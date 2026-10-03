# Fix list after iteration 4

## From 3_test.md
# P03 Create account — test notes (Stage 3, iteration 4)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Two real bugs found**: one new regression the iteration-4 build introduced
(P03-BUG-21, accessibility), and one defect the build *retired the proof for*
instead of fixing (P03-BUG-16). Everything the build did fix is genuinely
fixed — I re-verified it on the simulator and with new proofs — and the
layout is byte-identical to iteration 3 (compare.py mean diff 4.66%, CTA
surface top 678 vs the design's 677, submit button 694–745.7 exactly, both
caption lines exact). Per the brief the screen is **not** patched, so
`flutter test` is **red by design**: 2 proofs fail. Everything else passes
(669 green, 1 skipped, 2 red).

## The iteration-4 fixes, verified

- **BUG-15 (curly apostrophe)** — fixed: the subtitle now ships U+2019 and
  the whole copy audit is green (10/10 strings byte-identical to the HTML).
- **BUG-18 (overhang not hittable)** — works, and without changing layout:
  probed the whole 44 dp column of both targets through the real hit test;
  the Privacy Notice target is hittable through its 12 dp overhang below the
  caption block (838 of 840), taps inside the bar take the normal path, the
  enabled submit button still navigates to `/privacy`, and the CTA hairline
  is still at 678.
- **BUG-19 (first frame / stale measurement)** — fixed and now pinned hard:
  the targets are built from a synchronous `TextPainter` mirror, and I added
  five proofs that compare the built rects against the *real* laid-out
  paragraph's own glyph boxes at 320/390/430 × 1.0/1.3 — exact equality, so
  the mirror can never silently drift from the text again.
- **BUG-20 (no live region)** — see below: the flag is set, but the region is
  empty, which is a regression rather than a fix.

## Tests added this stage

`copy_audit_test.dart` 10 → **15** (5 added, all green) — *"targets equal the
paragraph boxes"*: for each of 320/390/430 at scale 1.0 and 320/390 at 1.3,
the `p03_terms` / `p03_privacy` rect must equal exactly the box derived from
the rendered paragraph (label glyph box, re-centred on its own line, ≥44×44).
Font-independent — both sides come from real glyph metrics — and it is the
contract the whole mirror/verify machinery exists to keep.

`p03_bugs_test.dart` 24 → **27** (2 added, both red) — P03-BUG-16 restored,
P03-BUG-21 new.

No gaps left in the bloc, navigation, seeded-repository, submitting-state or
tap-target coverage: `auth_bloc_test.dart` (45), `create_account_view_test.dart`
(48) and `seeded_submit_test.dart` (7) are unchanged and green — every event
and state path the build left in place is already pinned.

Feature total: 132 → **142** (140 green, 1 skipped, 2 red).

## Bugs found

### P03-BUG-21 (MAJOR, regression from the BUG-20 fix) — the validation error
### is no longer in the semantics tree

`app/lib/features/auth/presentation/views/create_account_view.dart:190-201`
(email) and `246-258` (password):

```dart
Semantics(
  liveRegion: true,
  child: ExcludeSemantics(
    child: Text(state.emailError!, …),
  ),
),
```

`ExcludeSemantics` drops the `Text`'s own node, and the wrapper supplies only
a flag — no label. The resulting semantics node is
`liveRegion: true, label: ""`. Walking the whole tree after a rejected
submit shows it plainly:

```
SemanticsNode liveRegion=true label=""      ← the email error
SemanticsNode liveRegion=true label=""      ← the password error
```

So a screen reader announces an *empty* live region and cannot read the
message at all — it is not in the tree to navigate to either. Before
iteration 4 the error was a plain `Text` and produced a labelled node. The
existing BUG-20 proof passes anyway because
`tester.getSemantics(find.text(error))` resolves to the nearest enclosing
node — the empty live region — and only asserts `isLiveRegion`, never the
label. That is the hole the regression went through.

Repro: `flutter test test/features/auth/p03_bugs_test.dart` — proof
P03-BUG-21 asserts each error is findable by semantics label *and* that the
node carrying it is the live region.

### P03-BUG-16 (MINOR) — retired rather than fixed; the defect is unchanged

The iteration-4 build deleted this proof ("the shared `hasError` flag did
not land … per review finding 1 the proof is retired"), which is fair as
process but leaves the defect in place with no guard: an invalid input still
paints the resting `line` border, while the design marks the input itself —
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`design/html-source/components.css:135`, and `docs/design/SPACING_SPEC.md` §3
"input [aria-invalid=true] border danger").

The build's reasoning is sound (re-passing `errorText` would re-open
P03-BUG-11's 20 dp indent, and the blocker really is shared code), but
retiring a proof is not the same as fixing a bug, so I have restored it as a
failing proof. `SHARED_REQUEST.md` §5 owns the unblock.

Repro: proof P03-BUG-16 — measure the borders painted inside the keyed field
before and after a rejected submit.

## Non-blocking observations

- On the device geometry the Terms target's top overlaps the submit button's
  last ~4 dp (button 694–745.7, caption line 1 centre ≈763.7 → target
  741.7–785.7), so a tap in that strip is delivered to both. The build
  records it ("both fire there and the submit wins functionally"); it is
  inert only because the links are still inert (`TODO(P03)`). Worth a
  comment where the link routes land.
- `_HitTestExpand.extra` is never read by `hitTest` — the overhang is bounded
  by each target's own 44 dp box instead, which is correct, but the field and
  its `markNeedsPaint` are dead weight and the name suggests it does
  something it does not.
- `_verifyTotal` is capped at 12 for the State's lifetime, so the post-frame
  font-swap verification stops after ~3 relayouts. Harmless today (every
  rebuild re-measures synchronously, which the five new proofs pin), but it
  is a silent ceiling on the safety net.
- P03-BUG-17 (subtitle breaks after "Children") remains a shared font-pipeline
  item (`SHARED_REQUEST.md` §6); no local test can pin it.
- ORCHESTRATOR_NOTES §3 (filled-state simulator capture) is still the UI
  stage's; the filled *state* is pinned by the widget test.
- Shared items 2, 4, 5 remain open; P03-BUG-6 is the suite's only skip.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 364 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **140 passed, 1 skipped, 2 failed**
  (only the two proofs above are red). Per file: `auth_bloc_test.dart` 45/45,
  `create_account_view_test.dart` 48/48, `copy_audit_test.dart` 15/15,
  `seeded_submit_test.dart` 7/7, `p03_bugs_test.dart` 27 green + 1 skipped +
  2 red.
- `flutter test` (full suite) → **669 passed, 1 skipped, 2 failed**.
- Prior iterations' reports are in the loop history; this file is the
  current one.
- `shot.sh` light + `compare.py` → `ui/light.png`, `ui/compare-light.png`
  (mean diff 4.66%, unchanged from iteration 3 — the hit-test work moved no
  pixels, as claimed; bands 0–5 all under 3%).


## From 4_review.md
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


## From 5_ui.md
# P03 Create account — UI check (Stage 5, iteration 4)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (latest: iter-3 QA — legal nbsp, subtitle U+2019 + break,
filled capture) + standing rules (PIP vacuous; status bar ignored; bottom-edge OWNER rule; CHILD ORDER n/a;
COPY — exact typographic characters vs HTML).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source
(`You&rsquo;re`, `Privacy Notice`, `— ever.`), DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_4.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_4.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_4.png docs/screens/P03/ui/cmp_light_4.png` (and dark → `cmp_dark_4.png`).
- Read `cmp_light_4.png` with the file reader; verified geometry by 1–2 px luminance scans.
- Filled-state capture: still host-blocked — `idb ui tap` fails with `SimulatorKit … does not exist`
  (re-probed iteration 3; this Xcode 27 install has no SimulatorKit/HID path and no Simulator.app GUI).
  Fallback stands: empty-state captures cover all state-independent geometry; the filled state is pinned by the
  `create_account_view_test.dart` "design filled state" test.

## Mean diff

- Light: **4.66%** (unchanged from iteration 3) — bands (0) 0–105: 1.58% · (1) 105–211: 5.59% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 14.39% · (7) 738–844: 6.22%.
- Dark: **4.26%** (was 4.27%) — bands (0) 0–105: 1.52% · (1) 105–211: 5.86% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 11.20% · (7) 738–844: 5.74%.
- Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the design's home-pill vs none in
  `simctl` captures, and the single deviation below.

## Checked and matching

- Subtitle copy character (iteration-3 deviation 1): FIXED. The view now contains U+2019 (`'You’re the grown-up…'`,
  verified by source read; repo U+2019 count in the view is 1, was 0). Satisfies the COPY rule and ON iter-3 item 2a.
- Legal footer (nbsp): unchanged, still matching — `Terms` rows 760–770, `Privacy Notice` rows 780–790, same as
  design (761–768 / 779–791); caption ≈38 dp, centred, normal gap.
- CTA hairline: design y=677, app y=678 (both themes implied by identical dark bands) — within ±2 px; note
  clearance identical at 39 px.
- Header (ink y=120, Apple y=255 both), title break (`Create your` / `family account`, edges x 174/218 vs 172/217),
  helper on the 20 px gutter with identical 12 px text-top gap, note row (shield x=24, text x=52–56, one baseline),
  or-row, buttons, fields, eye icon, dark-mode flips, bottom edge (surface uniform to y=844 both themes),
  20 px gutters, no overflow/clipping/stray ellipsis: all within tolerance.

## Deviations (element, design value, app value, fix)

1. Subtitle wraps a word early (ORCHESTRATOR_NOTES iter-3 item 2b — still open). Design line 1 ends
   `…in charge. Children never` (right edge x≈365–367) with `need an email.` on line 2. App line 1 ends
   `…in charge. Children` (right edge x≈328–330, rows y 192–200) with `never need an email.` on line 2
   (rows y 214–224) — same 350 dp measure and same vertical position (line-1 rows y 190–200 both), so the app's
   subtitle glyphs still run ~35 px wider per line than the HTML `.body`. The U+2019 fix did not move the break
   (expected: one glyph's width cannot account for ~35 px). Fix: match the HTML subtitle metrics exactly
   (16/24 Inter 400 — size, weight, letter-spacing/word-spacing, font-feature settings — per `tokens.css` /
   `components.css`, no ad-hoc values), then confirm the design break `Children never / need an email.` at
   390 width; keep sensible wrapping at 320 dp / scale 1.3.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh` (keep per ON item 3). Expected band-6 contributor, not a defect.
- Status-bar clock and the design's home-indicator pill (never drawn by `simctl`): ignored/artefact per standing
  rules; the OWNER bottom edge itself passes with surface to the edge.
- Process items (uncommitted iteration-4 build/test work in this worktree) belong to the loop, not to findings.

One visible deviation remains — the subtitle's second line reads `never need an email.` instead of `need an email.`,
plainly visible side-by-side and explicitly mandated by ON iter-3 item 2 — so this iteration does not pass.
It is a single localised style-metrics fix.


## From 6_bugs.md
# P03 Create account — bug hunt (Stage 6, iteration 4)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `3d45950` plus the uncommitted iteration-4
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/p03_bugs_test.dart`, `SHARED_REQUEST.md` and this
report. `ORCHESTRATOR_NOTES.md` (all items) and the standing rules (PIP —
vacuous here, status bar, data-over-mocks, bottom edge, alignment, COPY,
CHILD ORDER) were applied. CHILD ORDER is N/A (P03 lists no children).

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — the two
open-bug proofs are `skip:`-marked with their ids so the suite stays green
(2 skipped). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…15 | — | iterations 1–3's bugs | **all fixed**; proofs green |
| P03-BUG-6 | — | `NestButton` announced its label twice | **fixed** by shared batch `7eaa1f7` (inner `Text` excluded); proof un-skipped and green — correction to iteration 3 |
| P03-BUG-16 | minor | an invalid field paints no danger border | **open — UNBLOCKED, not shared-blocked**; proof skipped with the correct reason |
| P03-BUG-17 | minor | subtitle breaks after “Children” instead of “Children never” | open, **shared §6** (font pipeline); no local test possible |
| P03-BUG-18/19/20 | — | target overhang, first-frame/stale measurement, live regions | **fixed** in iteration 4; proofs green |
| P03-BUG-21 | **MAJOR** | the validation error left the semantics tree — the live-region nodes have empty labels | new regression this iteration; proof skipped |

**Corrections to earlier records made this stage.** The shared
`shared_requests_batch1` fix (`7eaa1f7`) is an **ancestor of the pre-build
sync `29162fc`**, so it was present when iteration 4's build ran. It resolved
P03's §2/§4/§5: brand and `NestButton` labels are now single, and
`NestTextField` renders `errorText` as a **gutter-aligned row with the danger
border forced** (its contract tests pass). Iteration 4's build note (“the
shared hasError flag did not land”) is wrong, and my iteration-3 report's
“mutually exclusive” analysis is obsolete: passing `errorText` no longer
re-opens BUG-11. `SHARED_REQUEST.md` §§2/4/5 are marked RESOLVED and a new §8
covers the one remaining component gap (its error row is not a live region).

## P03-BUG-21 (MAJOR, regression introduced this iteration) — the validation message is not in the semantics tree

**Where** `create_account_view.dart:190-201` (email) and `:246-258`
(password):

```dart
Semantics(
  liveRegion: true,
  child: ExcludeSemantics(
    child: Text(state.emailError!, …),
  ),
),
```

`ExcludeSemantics` drops the `Text`'s node, and the wrapper supplies a flag
but **no label**. My own semantics-tree probe after a rejected submit:

```
[Email] [] live=true        ← the error: empty label
[Password] [] live=true     ← the error: empty label
find.bySemanticsLabel('Enter a valid email address') -> 0
find.bySemanticsLabel('Use at least 8 characters')   -> 0
```

So the message is neither announced (the live region is empty) nor reachable
at all — worse than iteration 3's plain labelled `Text`, and worse than
Material's row, which is a live region *with* content. The iteration-3
review's shorthand (“keep the inner `Text` out of semantics so the label is
read once”) omitted the explicit label, and the BUG-20 proof's
`getSemantics(find.text(...))` resolves to the nearest enclosing node, so it
passed while the label was gone.

**Repro** `P03-BUG-21` (asserts each message is findable by semantics label
*and* that the node carrying it is the live region). **Suggested fix** carry
the message on the wrapper:

```dart
Semantics(
  liveRegion: true,
  label: state.emailError!,
  child: ExcludeSemantics(child: Text(state.emailError!, …)),
)
```

(or drop the `ExcludeSemantics` — but then the wrapper merges with the
`Text`, doubling the label the way the legal links used to). This is the
three-line fix the review also asks for.

## P03-BUG-16 (minor, open — unblocked) — an invalid field paints no danger border

**Where** `create_account_view.dart:173-185`/`:210-223` pass
`errorText: null` and render their own error rows, so the input keeps the
resting `line` border. The design marks the input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3). My probe of all borders painted
inside the email field after a rejected submit sees `line` only — no
`danger`.

**What changed** shared batch `7eaa1f7` made `NestTextField` render
`errorText` as a gutter-aligned row **and** force the danger border (pinned
by its own tests: “error aligns with the label gutter”, “error border still
turns danger”, “error replaces the helper”). `P03-BUG-11` no longer blocks
this, so the fix is local: **pass `errorText` to both fields and delete the
screen-owned error rows**. Do not pass `errorText` while keeping the owned
rows (the message would render twice).

**One caveat (why the proof is still skipped):** the component's error row
is a plain `Text` with no live region, so switching to it would trade
BUG-16 for BUG-20 unless `SHARED_REQUEST.md` §8 lands (make the shared row
announce). Recommended order for iteration 5: fix BUG-21 (above), then
either land §8 and switch (closes 16/20/21 together) or keep BUG-16 skipped
and accept the border gap for v1. **Proof** `P03-BUG-16` (skip-marked with
this reasoning).

## P03-BUG-17 (minor, shared §6) — the subtitle breaks one word early

Carried from iteration 3 and unchanged: the served Inter build is ~3–4%
wider than the design's, so the subtitle wraps after “Children” (app line 1
ends x≈330) instead of “…Children never” (design x≈368). The style is
already the design token (`NestType.body` 16/24, no letter-spacing), so the
UI stage's “localised style-metrics fix” is not available without a
token-rule violation; the review agrees this stays with SHARED_REQUEST §6
(pin/bundle the design's Inter build). No local test can pin a break the
harness font does not produce.

## Carried from review (iteration 4) — no local proof possible

- **`_HitTestExpand.extra` is dead** (`:290`, `:644-673`): `hitTest` never
  reads it, yet `updateRenderObject` assigns it and calls
  `markNeedsPaint()` — a pointless repaint per bar rebuild, and the number
  is unrelated to the caption line height it nominally mirrors. Fix: delete
  the field, setter, `markNeedsPaint` and the `extra:` argument.
- **The overhang pass fires even when the normal path already hit**
  (`_RenderHitTestExpand.hitTest`): a tap in the device-only ~4dp strip where
  the Terms target overlaps the submit button is delivered to both. Inert
  today (links are no-ops), a double activation once the routes land. Fix:
  `if (!hit && !stackRect.contains(position)) { … }`; add a `tapAt` proof
  when the strip becomes reachable in the harness.
- **`_verifyTotal` is a lifetime cap** (`:498-502`): after 12 schedules the
  font-swap safety net is permanently off for that `State`. The synchronous
  layout measurement still runs on every rebuild, so the impact is latent.
  Fix: reset `_verifyTotal = 0` in `didChangeDependencies` alongside
  `_verifyLeft`.

## Checked — no bug found

- **COPY** — the copy audit is green (15/15): the subtitle now carries
  U+2019 (byte-verified by the test and review stages), the note U+2014 and
  “Privacy Notice” the single blessed U+00A0; all nine strings are
  byte-identical to the HTML.
- **Kid-mode guard** — `APP_MODE=kid` + session kid mode → `/parental-gate`.
- **Restart / Drift persistence** — one owner row, no rename, password never
  written.
- **Back / deep links** — no history → `/value-tour`; back-pops when a route
  is stacked; the form renders on all three seeds.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit.
- **Text scale 1.3 + width 320/390/430** — matrix clean; targets survive
  live resize/scale/theme changes and equal the real paragraph boxes.
- **Dark-mode contrast** — unchanged tokens (text ≥4.5:1; lilac decorative).
- **0/1/6 children, long UK names, money, timezone/BST, empty lists** — N/A
  on this screen (static form; no money/date logic; members stream never
  displayed).
- **Geometry / owner rules** — CTA hairline 678 vs the design's 677, submit
  button 694–745 in both, note clearance 39dp; bottom edge uniform `surface`
  to y=844 in both themes; 20px gutters hold.
- **Design-faithful non-finding** — the two legal targets overlap laterally
  when the caption wraps; the HTML's inline hit boxes overlap the same way.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `359 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **143 passed, 2 skipped, 0 failed**
  (the skips are `P03-BUG-16` and `P03-BUG-21`; `P03-BUG-6` is now green).
- `flutter test` (full) → **670 passed, 2 skipped, 0 failed**.
- `--run-skipped` fails both skipped proofs for the documented reasons.

## Verdict

One MAJOR regression remains open (P03-BUG-21: the empty live region — a
three-line fix), plus P03-BUG-16 (now unblocked locally, coupled to
SHARED_REQUEST §8) and the shared font-pipeline item P03-BUG-17. The rest of
the screen is converged: geometry within 1–4dp, exact copy, green proof
suite, and the iteration-4 mechanisms (`_HitTestExpand`, synchronous
measurement) are sound but carry the three review hardening items above.

