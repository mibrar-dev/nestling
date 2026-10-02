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

VERDICT: FAIL