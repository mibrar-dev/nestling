# K08 · Reward shop — QA code review (stage 4, iteration 3)

Scope reviewed: `git diff main...HEAD` (merge-base `1e38e0b`) on `screen/K08`,
read against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K08, `docs/design/SPACING_SPEC.md` §10.7/§10.11,
`design/html-source/screens/K08-shop.html` (copy compared character-by-character)
and the design system in `app/lib/core/design_system/`. No code was edited in
this stage; no simulator was booted, installed on or driven.

Iteration 3's delta is small and surgical: `requestReward` returns the status it
wrote (K08-BUG-4), the reward name/note gained their own semantics nodes
(K08-BUG-5), and the unaffordable button switched to the shared `muted`
colourway (the mandatory `ORCHESTRATOR_NOTES.md` 17:10 item). No layout, colour
token, radius or design copy moved.

## Scope / RULES §1

`git diff main...HEAD --name-status` is clean: `app/lib/features/kid_shop/**`
(lib + tests) and `docs/screens/K08/**` only. The K08-authored commit
(`90df940`) touches 4 lib files, 3 feature test files and docs — all inside
RULES §1. The `nest_kid_button.dart` / `kid_home_view_test.dart` /
`no_placeholder_titles_test.dart` changes in the merge history came from `main`
(`shared/shared_batch8`), not from this branch's authors. No
`analysis_options.yaml` edit and no `// ignore:` anywhere in the diff.
`dart format --output=none --set-exit-if-changed .` → *0 changed*.

## Architecture

- Feature-first shape intact: `domain/` holds only entities
  (`KidShopData`, `ShopReward`) plus the abstract `KidShopRepository`;
  `data/` holds the Drift impl; `presentation/` holds one bloc
  (`KidShopBloc`) with Initial/Loading/Loaded/Failure and one view per route.
  DI + routes stay per-feature (`kid_shop_di.dart`, `kid_shop_routes.dart`),
  no cross-feature nesting, no use-case layer, imports all `package:nestling/`.
- BLoC lifecycle: the `watchActiveShop()` subscription is guarded
  (`_sub == null`) so the failure card's "Try again" cannot stack never-ending
  handlers; released on error and cancelled in `close()`
  (`kid_shop_bloc.dart:26-46,125-130`). RULES §4 (never re-add load events to
  refresh) respected — the view only adds `KidShopLoadRequested` on retry.
- The `Future<String?>` contract change is properly owned: the interface
  documents all three outcomes, the impl returns exactly
  `'approved' | 'requested' | null`, and the bloc maps them. `Future<void>`
  → `Future<String?>` is source-compatible for the one other caller
  (`watchShop` untouched, `test/core/data/repositories_test.dart` needed no edit).

## Design system / spec conformance

- No hard-coded colour, font family or font metric literal anywhere in the
  feature (`grep` for `Color(0x`/`Colors.`/`0xFF` returns only
  `Colors.transparent` for the invisible `.nav-back` box). Sizes are
  documented named constants where no token exists (26 chevron, 15/19 name,
  20 coin, 14/18 note, 17 button label) — each cites its HTML line, matching
  the codebase's precedent.
- Components reused, not re-implemented: `KidScope`, `NestStatusBar`,
  `NestHomeIndicator`, `NestIconButton`, `NestLockButton`, `NestCoinPill`,
  `NestBalancedText`, `NestEmptyState`, `NestKidButton`, `NestIcon`, `NestType`,
  `SvgPicture.asset`. `shop_reward_icons.dart` is a one-line forwarder to the
  shared `rewardIconFor(key, audience: NestAudience.kid)` (ICONS rule), and the
  kid branch is the exact `.k8-art` set.
- §5 K08 elements all present: title, live coin pill, 2-column grid
  (icon/name/price/`Get it`), disabled `Save up!` + "N more to go" for the one
  out-of-reach card, centre footer. Copy matches the HTML character for
  character (`Reward shop`, `Spend your coins on things you actually want.`,
  `Get it`, `Save up!`, `more to go`, `You have $coins coins. Pip is helping you
  save!`), including `’`/`—` where used. Numbers come from the DB (creation
  order, `r.title`, live balance) — nothing design-number is hard-coded. UK
  spelling throughout.
- Orchestrator rules: BALANCED HEADINGS honoured (`.kid-title` →
  `NestBalancedText`, and correctly NOT on `.k3`-style name/h3 text); no
  letter-spacing added; no chips, no avatar initials, no Pip slot on this design;
  `appNowUtc()` for the write timestamp, no `DateTime.now()`; ids come from the
  DB; no `subscription_status` write.

## Accessibility

- Every interactive element is operable: `Back`, `Grown-ups` and each card's
  button expose `SemanticsAction.tap`, and `performAction` drives the real
  navigation / DB write (proved in `reward_shop_view_test.dart`). The disabled
  `Save up!` reports `enabled: false` with no tap action (RULES §8).
- The only `excludeSemantics: true` wrapper is `_ShopPrice` (a reading, not a
  control) and it carries a `'$price coins'` label + `container: true`, so no
  bare number is announced. `NestKidButton`'s own wrapper passes `onTap`.
- K08-BUG-5's fix is the right shape: `container: true` (not
  `MergeSemantics` per card, which would have glued the café note onto its
  name) on the name and the note; decorative art stays `ExcludeSemantics`; no
  duplicated announcements (both the per-node and the whole-tree proofs pass).

## Performance

- No rebuild storm: the `BlocBuilder` is scoped to the routed body, the toast
  listener is keyed on `noticeSeq`, cards are stateless, and nothing rebuilds on
  a timer/animation. `IntrinsicHeight` per grid row costs one extra pass per
  row (3 rows) — the price paid for CSS-grid `align-items: stretch`, and it is
  what keeps the café card's note from stretching its neighbour.
- `const` used on the chrome (`NestStatusBar`, `_ShopTopRow`,
  `NestHomeIndicator`, `SizedBox`s); the six `SvgPicture`s are cache-backed.

## Error handling / data integrity

- Stream failure → explicit failure body with a working retry; write failure or
  vanished reward → honest "Hmm, that did not work. Try again." toast; no
  swallowed exception (the bloc catches `Object` deliberately so the spinner
  always stops).
- Money: payment is a precondition of the `approved` row inside one Drift
  transaction, so two affordable cards tapped in one frame cannot both land
  `approved` unpaid; the loser is left `requested` for a grown-up, and
  `approveRedemption` in P14 only ever deducts from a `requested` row, so
  there is no double charge and no negative balance (proved with
  `Future.wait` bursts).
- K08-BUG-4 is genuinely fixed: the toast is chosen from the status the write
  produced, not from a tap-time flag, so the child is never told "It's yours"
  for a reward that is waiting for a grown-up.

## Children's Code

- Kid mode contains no analytics, ads, tracking pixels, network calls or
  third-party loads (`grep` for `http`/`analytics`/`firebase` in the feature:
  none). The only writes are `reward_redemptions` rows and the child's own coin
  balance, both inside the family database. Coins only — never £ (K09 is the only
  £ kid screen). No shaming copy: an out-of-reach reward reads "Save up!" and
  "30 more to go", never "locked"/"you need". PASS.

## Findings

1. **minor** — `app/test/features/kid_shop/shop_reward_a11y_test.dart:1-22` and
   `:182-185` still describe K08-BUG-5 as OPEN and assert the buggy shape in
   prose ("K08-BUG-5 minor OPEN …", "Today every card's name Text has no
   semantics container, so the grid Column absorbs all six into one label").
   The fix landed and the three proofs in that very file now run green, so the
   header actively misleads the next reader into thinking the defect is live.
   Fix: rewrite lines 1-22 in the same past-tense form `k08_bugs_test.dart:1-24`
   now uses ("K08-BUG-5 minor FIXED … its three proofs are here"), and reword
   the 182-185 comment to describe what the assertion *guards* ("without the
   container the grid Column absorbs all six names into one run — that is the
   regression these proofs catch"). No production change.

2. **minor** — `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart:96-108`:
   when the child row is missing, the repository still inserts a `requested`
   redemption for a child that does not exist (`kid == null` and a short
   balance share one branch). That row can never be approved or paid
   (`approveRedemption` early-returns on `kid == null`), and P14's
   `watchRequests` renders it as a request from a child named "Child" — an
   unpayable orphan in a grown-up's list, pinned as intended behaviour by
   `kid_shop_repository_test.dart:388-407`. Not reachable in the shipped flow
   (parent and kid mode are exclusive, so a child row cannot vanish mid-screen),
   hence minor, not major. Fix: split the two cases —
   `if (kid == null) return null;` (write nothing, and the bloc's existing
   `written == null` path already toasts "Hmm, that did not work. Try again.")
   before the balance check, and change that test to
   `expect(written, isNull); expect(redemptionsFor('r-baking'), isEmpty);`.

3. **minor** — `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart:145-180`:
   `_switchMap` is a ~35-line verbatim private copy of the public
   `switchMapStream` in `app/lib/features/kid_home/domain/kid_home_repository.dart:59-87`
   (the "no cross-feature import" comment is why, but `core/` is importable, not
   just editable-by-orchestrator). Two hand-maintained copies of stream
   plumbing is exactly the drift risk the design-system/shared-core layering
   exists to prevent, and K08's copy drops a warning the original carries
   (an outer stream that completes must not close the result). Fix: file a
   `SHARED_REQUEST.md` item to move `switchMapStream` into
   `app/lib/core/data/stream_combine.dart` next to `combineLatest2/3/4`, have
   both features call it, and delete `_switchMap`. Nothing to change in K08's
   behaviour; no blocker today.

4. **minor (copy consistency)** — `app/lib/features/kid_shop/presentation/bloc/kid_shop_bloc.dart:112-114`
   toasts "Mum will give it a thumbs-up soon.", while the same screen says
   "Grown-ups" (the design's own lock label, `reward_shop_view.dart:26`) and
   "Ask a grown-up to add something coins can buy." (`:30`). A screen that
   offers a "Grown-ups" route and then names Mum is internally inconsistent, and
   the toast is the one string a child reads at the exact moment they wait for
   an answer. Fix: "A grown-up will give it a thumbs-up soon." — note the string
   is pinned by 15 assertions across the feature suite
   (`k08_bugs_test.dart:303`, ten in `kid_shop_bloc_test.dart`, four in
   `reward_shop_view_test.dart`), so the edit is mechanical but must touch every
   proof. Counter-argument to
   weigh before changing it: K10's design copy in `DESIGN_SPEC.md:208` says
   "Mum marked £4.20 as paid", so "Mum" is this app's established voice — if the
   owner prefers that, keep it and delete nothing; this is a judgement call, not
   a defect.

## Notes (no action required)

- `app/lib/features/kid_shop/domain/kid_shop_repository.dart:8-9` — "Coins leave
  the child's balance only on approval" is technically true (an instant reward's
  row *is* `approved` in the same transaction) but reads as if P14 is the only
  thing that can deduct. Worth one clarifying clause now that `requestReward`
  returns the status.
- `shop_reward_card.dart:10,39` — `_artSize`/`_getMinHeight` are both `56`, i.e.
  `NestDevice.tapKid`. Not a hard-code violation (the HTML fixes both at 56),
  but referencing the token would keep the two in step.
- The `.muted` swap changes what a child SEES on the one card they cannot
  afford (washed-out white → the design's flat `surface-2`/`ink-2`). Geometry is
  untouched (the geometry test still pins the 56 px painted box, radius 16,
  3 px border and `--sh-kid` band), but the UI stage should re-measure that
  button's rect and both themes rather than inherit iteration 2's screenshot
  verdict.
- Process, not findings (per the orchestrator's rules): the loop runs stages
  concurrently, and while this review was being written the test/UI stages were
  adding untracked files under `app/test/features/kid_shop/` and
  `docs/screens/K08/ui/` and editing committed test files in this worktree. The
  review deliberately covers committed `HEAD`.

## Verification evidence

- `flutter analyze` (from `app/`, whole repo, no ignores) → **No issues found!**
- `dart format --output=none --set-exit-if-changed .` → 585 files, **0 changed**
- `flutter test --timeout 120s test/features/kid_shop/` → **168 passed, 0 failed,
  0 skipped** (the K08-BUG-1…5 proofs all run un-skipped and green; no `skip:`
  markers remain in the feature).
- Whole-suite `flutter test --timeout 120s` → **3809 passed, 4 skipped, 2 failed,
  0 kid_shop failures**. Both failures are in `test/features/rewards/**`
  (`rewards_view_test.dart`, `rewards_a11y_test.dart`) and both throw
  `Failed to load dynamic library .../build/native_assets/macos/libsqlite3.dylib
  (no such file)` — the parallel UI stage rebuilt `build/` underneath the test
  process. Environment artefact, not a K08 defect; re-run in isolation to
  confirm.
- No simulator used; no code edited in this stage.

**All four iteration-2 findings are resolved**: the toast now follows the written
status (K08-BUG-4), `k08_bugs_test.dart`'s header states the fixes it guards,
`.k8-get.off` uses the shared `muted` colourway instead of the washed-out
fallback, and the two stale K03 placeholder-copy assertions are gone from `main`.
No blocker or major finding remains.

VERDICT: PASS