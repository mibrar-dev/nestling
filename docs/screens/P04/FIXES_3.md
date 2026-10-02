# Fix list after iteration 3

## From 4_review.md
# P04 · Privacy consent — QA code review (STAGE 4, iteration 3)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` plus the uncommitted working-tree build
and the untracked `app/test/features/privacy_consent/privacy_consent_copy_test.dart`.
Production code changed this iteration: **two lines** — `privacy_consent_view.dart`
(dropped the `title: ''` workaround + stale `TODO`) and `privacy_consent_bloc.dart`
(revert target now the stored value).

`ORCHESTRATOR_NOTES.md` is mandatory and has been re-read, including the 13:42
UPDATE, which defers the trash glyph to the in-flight shared batch and assigns
"row heights/alignment" to P04 for this iteration. Status table at the end.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 17 files, 0 changed
flutter analyze                            → No issues found! (ran in 2.8s)
flutter test test/features/privacy_consent/ → 00:02 +105 ~3: All tests passed!
flutter test  (whole app)                  → 00:10 +592 ~3: All tests passed!
tools/screens/compare.py vs ui/app_light_3.png → mean diff 4.49%
     bands 1.57 / 6.02 / 1.98 / 7.86 / 7.31 / 6.52 / 0.40 / 4.17 %
tools/screens/compare.py vs ui/app_dark_3.png  → mean diff 5.61%
     bands 1.55 / 8.50 / 9.14 / 7.76 / 7.12 / 6.69 / 0.39 / 3.67 %
```

Pixel probes (logical px, PNG ÷ 3) — design vs `ui/app_{light,dark}_3.png`:

| probe | design | app it. 3 | it. 2 | verdict |
|---|---|---|---|---|
| back-chevron glyph band | 66–80 | 66–80 | 66–80 | Δ0, no regression from dropping `title: ''` |
| h1 glyph band | 113–138 | 113–138 | 113–138 | Δ0 |
| subtitle glyph band | 156–170 | 156–170 | 156–170 | Δ0 |
| promise-list card top | 289 | 289 | 289 | Δ0 |
| promise-list card bottom | 509 | **512** | 512 | **+3 px** — finding 2 |
| opt card (top → bottom) | 532–616 | 535–619 | 535–619 | +3 px |
| bottom-CTA surface | 674–809 | 675–**843** | 675–843 | runs to the edge ✓ |
| strip below CTA (light / dark) | `#FBF7F0` / `#15131F` | `#FFFFFF` / `#1F1C2E` | same | ✓ OWNER rule (app is correct) |

Copy re-verified independently of the new test: I decoded the entities in
`design/html-source/screens/P04-privacy.html` and compared every string the view
draws code point by code point — `Your family’s privacy` (U+2019),
`Exactly what we store — and nothing else.` (U+2014),
`No ads or tracking — ever` (U+2014), all four titles and subs, the opt title and
sub, `Continue`, `Read the full Privacy Notice` and the three `aria-label`s are
identical to the design, with no straight quote, ASCII hyphen, left double quote,
soft hyphen or zero-width character anywhere in the rendered copy. The design
contains no `&nbsp;` on this screen and no phrase that must not split, so the
non-breaking-space half of the COPY rule is satisfied by construction. The
screen-owned failure captions use U+2019/U+2014 correctly.
`privacy_consent_copy_test.dart` locks this against the HTML itself.

CHILD ORDER rule: not applicable — P04 renders no children (the only `Child`
matches in the feature are `child:` widget parameters, the promise copy
`Children only need a nickname`, and the `addChildren` route). No child list is
read or ordered anywhere in this feature.

---

## Findings

### 1. MAJOR — the promise list is still 3 px taller than the design, and this iteration an in-scope fix exists

- **Where:** `privacy_consent_view.dart:90-123` — four `_PromiseRow`s passed as
  four children of `NestList`; shared `NestList` inserts a real
  `Divider(height: 1, thickness: 1, indent: 72, color: tokens.line)` between
  every pair of children
  (`app/lib/core/design_system/components/nest_list_row.dart:131-135`).
- **Evidence:** list card 289→512 in the app vs 289→509 in the design (same top,
  +3 px at the bottom); opt card 535 vs 532; rows sit 57 px apart where the
  design is 56 px. The design draws the separators as absolutely positioned 1 px
  overlays (`.list-row + .list-row::before`), so 4 × 56 px rows stay 224 px.
  Bands 3–5 remain the worst in both themes (7.86 / 7.31 / 6.52 % light).
- **Ownership:** the 13:42 UPDATE assigns "row heights/alignment" to P04 for
  this iteration, and unlike the trash glyph this one is **not** in the
  in-flight shared batch (`git log main -- app/lib/core/design_system/` tops out
  at the compact-nav commit `fc981bc`; no `NestList` change exists). The build
  recorded it as shared-only and skipped it; iteration 2's review repeated that
  "no in-scope fix exists", which was too strong — `NestList` only injects
  dividers *between* its children, so a conforming in-scope fix exists without
  touching `lib/core/**` and without re-implementing any `Nest*` component:
  1. Pass the four rows as a **single** child (a `Column` of rows), so
     `NestList` adds no dividers and the card chrome (surface, `NestRadii.allM`
     r16, `cardShadow`) is unchanged.
  2. Give `_PromiseRow` a `showDivider` flag and wrap its content in a `Stack`
     whose only extra child is
     `Positioned(top: 0, left: 72, right: 0, height: 1, child: Divider(height: 1, thickness: 1, color: context.nest.line))`
     for rows 1–3 only. A `Stack` sizes to its non-positioned children, so the
     separator contributes **zero** layout height, and `left: 72` measured from
     the row's left edge is the same reference point `NestList`'s `indent: 72`
     uses today — the rendered line is pixel-identical to the design's `::before`.
  Net effect: list height 224 px, rows 56 px apart, opt card top 528, matching
  the design. Keep SHARED_REQUEST item 6 filed — the shared component is still
  wrong for every other `NestList` screen — but do not let it block P04.
- **Severity rationale:** a cumulative 1 px-per-row offset is the "nothing a few
  px off" case of the OWNER ALIGNMENT rule, the owner named it for this
  iteration, and it is fixable inside RULES §1.

### 2. MINOR — the first-run upsert is not last-write-wins when two writes overlap

- **Where:** `data/privacy_consent_repository_impl.dart:72-86`
  (`UPDATE` → if `changed == 0` `insert … mode: InsertMode.insertOrIgnore`).
- **Why:** each `setCrashConsent` call is a read-then-write pair, so two
  overlapping calls can both see `changed == 0` and both insert. With the
  iteration-2 optimistic toggle, two rapid taps are now easy to make. Drift
  queues statements in issue order, and the order is `U1` (tap 1), `U2` (tap 2,
  queued after tap 1's first `await` yields), `I1`/`I2` — so which insert wins
  depends on scheduling. If `I1` wins, a database with no `settings` row keeps
  the **first** tap's value while the parent's last intent was the second, and
  the stream reconciles the switch to that stored value (self-consistent, no lie
  on screen, but the last tap is lost). Only reachable on a first-run database
  (once the row exists, the UPDATE branch handles every write correctly), and
  only on a rapid double tap — minor.
- **Fix:** serialise the writes in the bloc instead of relying on the repository
  being atomic. Keep a `Future<void> _writes = Future<void>.value();` on the bloc
  and append each write to it, so `setCrashConsent` calls never interleave:
  ```dart
  _writes = _writes.then((_) => _repository.setCrashConsent(consent: event.value));
  await _writes;
  ```
  (Keep the optimistic emit and the try/catch as they are.) Alternatively make
  the repository do it with a single transaction
  (`_db.transaction(() => …)`), which is the better home if the orchestrator
  wants the fix shared with P16's `SettingsRepositoryImpl._write`.

### 3. MINOR — `2_build.md` quotes a test tail that the tool does not print

- **Where:** `docs/screens/P04/2_build.md` — "00:11 +585 ~3: All other tests
  passed!". A real `flutter test` run prints `All tests passed!` (I re-ran the
  whole app: `00:10 +592 ~3: All tests passed!`; the count differs only because
  stage 3 adds its own tests after the build note is written). "All other tests
  passed!" reads like a failure in a done-criteria block and will be quoted
  back by the next reviewer.
- **Fix:** quote the real string, or write "P04 scope green; see `3_test.md` for
  the current suite tail."

---

## Verified correct (no action)

- **Architecture:** unchanged and compliant — `domain/` holds the entity (plus
  `ConsentOptionIds`) and the abstract repository only; one bloc per feature with
  `LoadRequested` and initial/loading/loaded/failure; DI and routes per feature
  and untouched. `analysis_options.yaml` untouched. `git diff main --name-only`
  filtered for RULES §1 paths returns nothing.
- **Design-system usage:** `NestStatusBar`, `NestNavBar`, `NestList`, `NestCard`,
  `NestToggle`, `NestButton`, `NestBottomCta`, `NestIcon`, `showNestModal` all
  reused; the only feature-private widgets are the promise row and the notice
  link, each justified inline. Colours only from `context.nest` /
  `context.nestText`, type only from `NestType`, spacing from `NestSpacing`;
  the literals that remain (`84`, `13`, `56`, `22 / 16`, `decorationThickness: 1`)
  have no token and match `NestListRow` exactly.
- **Iteration-2 fixes verified in place:** the nav workaround is gone — the bar
  is `NestNavBar(compact: true, onBack: …)` with a **null** title, the bar still
  measures 60 px, and the new test asserts no empty `Text` node is left in the
  bar (nothing for a screen reader to announce); the failure revert now uses
  `_crashFrom(state.items)`, the value the `items` mirror carries from the
  database, with `[P04-8]` un-skipped and green plus a direct bloc test for the
  double-failure path. No pixel regression from either change (probes above are
  byte-identical to iteration 2).
- **DESIGN_SPEC §5 P04:** every element present in order; copy identical to the
  HTML source (see above); single equal-weight primary `Continue` (ICO nudge
  rule); opt-in toggle OFF by default; footnote link present; UK spelling.
- **Accessibility:** unchanged and green — h1 is a header, the shield is an
  `image` node with the HTML alt text, promise rows are containers and never
  buttons, the toggle exposes label + `toggled` + `enabled`, Back / Continue /
  notice link are labelled buttons, every target ≥ 44 px, rows wrap with no
  `maxLines` (SPACING_SPEC §9.3/§9.4), and the 320/390/430 × scale 1.0/1.3 matrix
  plus the 320×568 short screen still pass. Contrast: sky link 5.42:1 light /
  7.21:1 dark, danger caption 4.73:1 light / 7.37:1 dark.
- **Performance:** `const` widgets throughout; `BlocBuilder` outside the scroll
  view so scroll position survives; the optimistic emit adds one rebuild per tap
  and the toggle is disabled after a failure, so no rebuild storm; `emit.forEach`
  is cancelled when `BlocProvider` disposes the bloc on `go`/`pop` (the
  "write fails after leaving" guard is green).
- **Error handling:** `Continue` is never disabled; the caption is state-aware
  and now truthful about the stored value; a stale message is cleared by the next
  successful stream emission; the first-run upsert makes the screen's only write
  actually persist.
- **Children's Code:** no analytics, ads, trackers or SDKs in the diff; no child
  data read; the one write is an optional, parent-only, default-OFF consent flag;
  the kid-mode guard redirects `/privacy` to `/parental-gate` (proof green).
- **OWNER BOTTOM-EDGE rule: correct.** The CTA surface reaches the physical edge
  in both themes (`#FFFFFF` / `#1F1C2E` at y 820 and 838) while the design PNGs
  show a cream/near-black strip there, because the HTML `.home-indicator` sits
  outside `.bottom-cta`. The app is the intended behaviour; do not "fix" it
  toward the PNG.
- **OWNER ALIGNMENT:** 20 px gutters shared by headline, list, opt card and CTA
  at 320/390/430; the header block is pixel-exact; the only remaining
  misalignment is the 3 px divider rhythm in finding 1.

## Open shared dependencies — owner: orchestrator, not P04

- **SHARED_REQUEST item 1 — trash glyph (orchestrator item 1).** Explicitly
  deferred by the 13:42 UPDATE ("keep the reserved 40×40 peach tile + TODO for
  now; when main contains `NestIcons.trash` … use it"). The asset is still
  absent from this worktree (`app/assets/icons/` has no `ic_trash.svg`; `ic_bin`
  is a wheelie bin and `ic_basket` a laundry basket — both re-read), so P04
  complied. When the batch merges, P04 needs one line:
  `leadingAsset: NestIcons.trash` on row 4 (`privacy_consent_view.dart:111-121`),
  delete the `TODO(P04)`, un-skip `[P04-2]`, and flip the contract test's
  `findsNothing` to `findsOneWidget`.
- **SHARED_REQUEST item 6 — `NestList` real dividers.** Still correct to file for
  the shared component (every `NestList` screen inherits the 1 px-per-divider
  drift), but it must not be used as a reason to skip P04's own fix — see
  finding 1.
- **SHARED_REQUEST item 2 — dark shield.** `privacy_shield.svg` still bakes the
  light `#E6EFFE` disc; the dark design uses `#1A2A4A` (dark band 2 is 9.14 %,
  the worst band in the app). Named in the 13:42 batch; `[P04-7]` stays skipped.
- **SHARED_REQUEST item 4 — P16 half.** `SettingsRepositoryImpl._write` has the
  same UPDATE-only shape; needs the shared helper.
- **Skipped proofs.** `[P04-2]`, `[P04-4]`, `[P04-7]` remain `skip`-marked
  red-by-design proofs of core-owned defects, each annotated with its repro and
  the shared change that turns it green, and each runnable with
  `flutter test --run-skipped`. Flip each `skip` the moment its shared fix
  lands; until then "all tests pass" does **not** mean "no defects open" —
  findings 1 and 2 above are the open ones.

## Process (not findings, recorded for completeness)

`main` advanced after the last merge: `9b8d70b` ("Screen rules: child order =
order added; exact typographic copy") is not an ancestor of `HEAD`, which is why
`tools/screens/stages/common.md` in this worktree lacks the CHILD ORDER / COPY
lines even though this review received them. That is the loop's merge cadence
handling, not a P04 change; both rules were honoured above. `2_build.md` also
carries a test-tail string copied from an earlier run (finding 3).

## ORCHESTRATOR_NOTES status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + a test that all four rows find a glyph | Deferred to the shared batch by the 13:42 UPDATE. Rows 1–3 proven (asset, 24 px, tile ink, `colorFilter`, light+dark); row 4 reserved behind `TODO(P04)` with the flip instructions recorded in the tests. **Owner: orchestrator** |
| 2 — 16 px header offset | **Met** by the shared merge; probes show Δ0 on chevron, h1 and subtitle. Nothing moved locally |
| 3 — row heights / dividers → opt card ≈528 | Row heights, tiles and indent are exact; the residual +3 px is `NestList`'s dividers and **is fixable in scope** this iteration → finding 1 |
| 4 — bottom panel to the edge, perfect alignment | **Met** (bottom edge in both themes, gutters 20 px, header exact) |
| 13:42 UPDATE — fix "everything else" (row heights/alignment, review findings, bug findings) | Review findings 3–6 all closed this iteration; row heights/alignment not closed → finding 1 |
| COPY rule | **Met** — verified code point by code point and locked by a new test |
| CHILD ORDER rule | N/A — no children on this screen |


## From 5_ui.md
# P04 · Privacy consent — UI check (STAGE 5, iteration 3)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_3.png`, `docs/screens/P04/ui/app_dark_3.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_3.png`, `docs/screens/P04/ui/cmp_dark_3.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + 12:03 + 13:42 updates).

## Mean diff

- Light: **4.57%** (unchanged from iteration 2) — bands: 0 (0–105) 1.56% ·
  1 (105–211) 6.02% · 2 (211–316) 1.98% · 3 (316–422) 7.86% · 4 (422–527) 7.31% ·
  5 (527–633) 6.52% · 6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.61%** (unchanged from iteration 2) — bands: 0 (0–105) 1.54% ·
  1 (105–211) 8.50% · 2 (211–316) 9.14% · 3 (316–422) 7.76% · 4 (422–527) 7.12% ·
  5 (527–633) 6.69% · 6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs (mock `9:41` vs OS clock)
ignored per STATUS BAR rule; bottom-edge strip is the OWNER-rule override (app correct).

## Unchanged since iteration 2 (still correct)

- Header alignment from the shared compact-nav fix: chevron/H1 at design y.
- Presence/order/copy all exact (curly ’, em dashes per COPY rule); 20 px gutters; 40 px
  tiles r12; divider indent 72; opt-card 13 v/16 h; toggle OFF 51×31; CTA anchored at design
  y; surface-to-edge bottom panel; no overflow/clipping/ellipsis. No Pip → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels `#BA562E`/`#B9542B` inside the peach tile (x=52, y≈478/490).
   App value: plain `#FFEDE4` — blank tile. Verified `ic_trash.svg` / `NestIcons.trash`
   still absent from `app/assets/icons/` + design system (only `ic_bin.svg`, the cart, exists);
   the 13:42 orchestrator update keeps the reserved 40×40 tile + `TODO(P04)` until the shared
   batch lands, so no local fix is possible in this stage.
   Fix: use `NestIcons.trash` in the design's red-ink colour once main provides it + widget test
   that all four row icons render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only).
   Design value: `#1A2A4A` (patch (160,228)).
   App value: `#E6EFFE` — `privacy_shield.svg` bakes the light hex.
   Fix (shared, SHARED_REQUEST item 2, in the 13:42 shared batch): token-coloured shield asset.
   Designer-visible in dark mode.
3. Residual row-text drift, bands 3–5 ≈ 6.5–7.9% light / ≈ 6.7–7.8% dark (ORCHESTRATOR_NOTES
   item 3).
   Design value: row text lines land exactly; opt card top ≈ y 528, Continue ≈ y 690.
   App value: ~1 px doubling per row in the heat-map, accumulating down the list (rows ~1–2 px
   taller than the HTML); header and CTA anchor correctly so this is intra-list height only.
   Fix (P04 scope, next build stage): match row heights/divider insets exactly from
   `design/html-source/screens/P04-privacy.html` (SPACING_SPEC §9: pad-v 7, wrap, indent 72).

No code edited in this stage (UI check is read-only).


## From 6_bugs.md
# P04 · Privacy consent — bug hunt (Stage 6, iteration 3)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run (empty DB). **No screen code was changed.** Re-hunted the
iteration-3 tree after the P04-8 / null-title fixes and before the shared
batch (`ic_trash`, themed shield) lands.

`app/test/features/privacy_consent/p04_bugs_test.dart` now has **16 proofs:
12 green + 4 skipped** (P04-2/P04-4/P04-7 open, P04-9 new). Run the skipped
ones with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 12 passed, 4 failed (the four open defects, by design)
```

Method: re-read the two iteration-3 production changes, the new copy test and
the review; re-ran every previous proof; probed the untested edges with
throwaway tests (first-run upsert overlap at repository and widget level,
same-frame vs one-frame double taps, guard/deep-link/persistence/async-gap
re-checks); re-measured the iteration-3 shots against the design. Every claim
below has a committed proof.

**New finding this iteration: P04-9 (minor) — the first-run upsert is not
atomic.** P04-8 is fixed and pinned; four defects remain open (P04-2/P04-4
majors, P04-7/P04-9 minors). The screen still cannot pass: `VERDICT: FAIL`.

## Iteration state

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** — upsert (it. 2); proof green |
| P04-2 | major | row 4 empty peach tile (no trash glyph) | **OPEN — shared batch** (orchestrator 13:42 UPDATE: deferred; flip instructions ready) |
| P04-3 | major | compact nav bar 16 px short | **FIXED** — shared merge (it. 2); proof green |
| P04-4 | major | real 1 px dividers inflate the list by 3 px | **OPEN — now fixable in scope** per review it.-3 finding 1 (below); shared §6 stays for the component |
| P04-5 | minor | rapid double-tap wrote the same value twice | **FIXED** — optimistic emit (it. 2); proof green |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** — state-aware caption (it. 2); proof green |
| P04-7 | minor | dark mode renders the light-baked shield | **OPEN — shared batch** (themed shield queued) |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (it. 3) — `_crashFrom(state.items)`; proof un-skipped and green, re-verified here |
| P04-9 | minor | overlapping first-run writes keep the earlier value | **NEW** (below) |

## New finding

### P04-9 — the first-run upsert is a read-then-write pair, not an atomic write — MINOR

- **Where:** `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart:72-86`
  — `UPDATE … ; if (changed == 0) INSERT … InsertMode.insertOrIgnore`.
  (Also raised by the iteration-3 review, finding 2.)
- **Why:** two overlapping `setCrashConsent` calls both execute their UPDATE
  before either INSERT, so both see the empty `settings` table; the first
  INSERT wins and the second is silently ignored. On a first-run database —
  exactly P04's first visit, before the row exists — the parent's **later**
  tap can be dropped, and the `watchItems` re-emit then reconciles the switch
  to that earlier value. If the earlier value is ON, the opt-in silently
  survives the parent's last attempt to switch it off.
- **Repro (proof, deterministic — 5/5 runs):** `--run-skipped … --plain-name
  '[P04-9]'` — `Seed.fresh(db)`, then issue
  `setCrashConsent(true)` and `setCrashConsent(false)` without awaiting
  between them, `await Future.wait` both → expected stored `false`, actual
  `true` (one row). A widget-level same-frame double tap shows the same, but
  that variant is dominated by the pre-rebuild stale value, so the
  repository-level proof is the one committed.
- **Reachability:** only when the two writes overlap (rapid double tap /
  slow DB). With a frame between taps the repository serialises in practice —
  my iteration-2 guard ("first run: a double tap persists the last tap") is
  still green — but the non-atomic pair is the real defect behind it.
- **Failing test:** `[P04-9] overlapping first-run writes keep the last value`.
- **Fix (feature-local, one of):**
  1. wrap UPDATE + conditional INSERT in `_db.transaction(() async { … })`
     so the pair is atomic and the second call sees the committed row; or
  2. serialise writes in the bloc with a `Future<void> _writes =
     Future<void>.value(); _writes = _writes.then(…)` chain (keeps the
     optimistic emit and error handling unchanged).
  Option 1 is the better home; the same pattern can later be shared with
  P16's `SettingsRepositoryImpl._write`.

## Open defects

### P04-4 — list 3 px too tall; fixable in P04 scope — MAJOR

- **Where:** `privacy_consent_view.dart:94-127` (four rows as four children of
  shared `NestList`, which injects real `Divider(height: 1)`s).
- **Current evidence:** iteration-3 shots: list card 289→512 vs design
  289→509; tile tops 295 / 352 / 409 / 466 (57 px apart) vs 295 / 351 / 407 /
  463 (56 apart); opt card 530 vs 527; `compare.py` bands 3–5 remain the worst
  (7.86 / 7.31 / 6.52 % light). `[P04-4]` fails with list = rows + 3.
- **Fix (review it.-3 finding 1, do this next build):** pass the four rows as
  a **single** child of `NestList` (a `Column`), so no dividers are injected
  and the card chrome (surface, r16, shadow) is unchanged; give
  `_PromiseRow` a `showDivider` flag and wrap its content in a `Stack` with
  one non-layout `Positioned(top: 0, left: 72, right: 0, height: 1, child:
  Divider(height: 1, thickness: 1, color: context.nest.line))` for rows 2–4.
  The Stack sizes to its non-positioned child, so the separator adds zero
  height and the line is pixel-identical to the design's `::before`. Keep
  `SHARED_REQUEST` §6 filed — the shared component is still wrong for every
  other `NestList` screen — but it no longer blocks P04.

### P04-2 — row 4 empty peach tile — MAJOR (shared batch)

- Deferred by the orchestrator's 13:42 UPDATE. `app/assets/icons/ic_trash.svg`
  and `NestlingIcons.trash` are still absent from this worktree; row 4 keeps
  the reserved 40×40 tile + `TODO(P04)`. When the batch merges: add
  `leadingAsset: NestIcons.trash`, delete the TODO, un-skip `[P04-2]`, flip
  the contract test's `findsNothing` to `findsOneWidget`. Evidence: the
  iteration-3 shot still shows a continuous `#FFEDE4` tile at x=52,
  y 466–505.7 (design has rust glyph pixels in 463–502.7).

### P04-7 — dark shield artwork — MINOR (shared batch)

- The themed shield is named in the same shared batch. Current probes on
  `ui/app_dark_3.png`: disc `#E6EFFE` vs design `#1A2A4A`; body `#FFFFFF`
  vs `#1F1C2E`. Flip `[P04-7]` when the themed asset lands.

## Verified this iteration (passing proofs and probes)

- **P04-8 fix:** the double-failure revert now restores the stored value; my
  `[P04-8]` proof is un-skipped and green, and the direct bloc test added by
  stage 3 covers the same path. No regression in either failure direction
  (P04-6 proof still green).
- **Null-title nav:** the `title: ''` workaround removal changes nothing
  visually (iteration-3 probes: chevron 66–80, h1 113–138, list top 289 — Δ0
  vs both the design and iteration 2) and the new widget test pins the 60 px
  bar with no empty `Text` node.
- **Copy rule:** the new `privacy_consent_copy_test.dart` reads the HTML
  source, decodes entities and compares every rendered string; the review
  independently decoded the same strings code point by code point. No drift
  found; typographic characters are exact.
- **Same-frame double tap:** two taps inside one frame send `true` twice (the
  widget has not rebuilt), which is a harness artefact — a human double tap
  spans frames, and the one-frame-apart behaviour is correct and pinned
  (`[P04-5]`, and the first-run last-write guard). Not reported as a bug;
  the genuine overlap defect is P04-9 at the repository level.
- **Re-run green:** kid-mode guard (`/parental-gate`), deep-link back
  (`/create-account`), restart persistence (demo + first-run), async-gap
  after leaving the screen, single-dialog double tap, 320 px / scale 1.3
  matrix, dark contrast, 20 px gutters, CTA surface to the physical edge.
- **N/A:** children/long names/coins/£ values (no such data on P04), timezone
  and money rounding (no dates or money), child-order rule (no children).

## Mandatory notes status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + all-four-glyph test | Deferred to the shared batch by the 13:42 UPDATE; P04 side ready (`TODO`, reserved tile, proof + flip instructions) |
| 2 — header 16 px offset | **Met** (shared merge; probes Δ0) |
| 3 — row heights/dividers → opt card ≈528 | Rows/tiles/indent exact; residual +3 px is P04-4, **fixable in scope** per review it.-3 finding 1 — not closed this iteration |
| 4 — bottom edge + alignment | **Met** (both themes, gutters 20 px, header exact; the only misalignment is P04-4) |
| COPY / CHILD ORDER | Copy **met** (new test + independent review decode); child order N/A |

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → 358 files, 0 changed.
- `flutter analyze` → No issues found.
- `flutter test test/features/privacy_consent/` → **105 passed, 4 skipped,
  0 failed**.
- `flutter test` (whole app) → **592 passed, 4 skipped, 0 failed**.
- `--run-skipped` on the bug file → 12 passed, **4 failed** (P04-2, P04-4,
  P04-7, P04-9), each with its repro above.

## Verdict

All iteration-1/2 bugs are fixed and pinned, the iteration-3 changes (P04-8
revert, null-title nav) are verified with no regression, and the copy rule is
locked by a test. Two majors remain open on this screen: P04-4 (the +3 px
divider drift — now proven fixable inside RULES §1, review finding 1) and
P04-2 (empty row-4 tile, deferred to the shared batch). Plus P04-7 (shared
batch) and the new P04-9 (non-atomic first-run upsert). "All tests pass" does
not mean "no defects open".

