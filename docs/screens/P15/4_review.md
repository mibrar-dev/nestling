# P15 · Child profile — Stage 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` on branch `screen/P15` (59 files, +9436/−51;
merge-base = current `main` at `7afc8ad`). The reviewable surface is small now:
all feature code under `app/lib/features/family/**` (+5 lib files vs
iteration-2 checkpoint `31a44b8`), tests under `app/test/features/family/**`,
docs under `docs/screens/P15/`. The rest of the lib-adjacent diff
(`nest_toggle.dart`, `nest_stepper.dart`, `nest_text_field.dart`,
`nestling_assets.dart`, four new quest SVGs, `test/core` adjustments) is the
`main` shared_batch5 merge — reviewed as input, not as P15 output. **No code
edited by this stage; no simulator booted, installed on, driven, or
screenshotted (stage-4 policy); no `flutter clean`.**

Iteration-2 review (`4_review.md`, written 18:15 in the previous round) found
one major (P15-BUG-9) and seven minors. All eight are audited below.

## Gates (run in `app/`)

```
$ dart format --output=none --set-exit-if-changed lib/features/family \
    $(git ls-files test/features/family | grep '\.dart$')
Formatted 32 files (0 changed)

$ flutter analyze lib test/features/family
No issues found in P15-tracked files. (8 info-level lints, all in two
untracked in-flight scratch files: p15_probe4_test.dart — combinators_ordering,
document_ignores. The committed tree is clean.)

$ flutter test $(git ls-files test/features/family) test/features/today
00:17 +382: All tests passed!          # iteration-2 bug proofs un-skipped,
                                      # P15-BUG-9a/9b and the second-deep-link
                                      # widget test now green
$ grep -rn "skip:" $(git ls-files test/features/family)
(no skips in tracked tests)

$ flutter test test/core/family_time_test.dart
00:03 +21 -1: one shared test red — “seed + repository zone plumbing ›
kid_home completions are stamped with the family zone”: `leoRows.single`
→ “Too many elements”. Files byte-identical to main (git diff empty), so
this is a shared -main- seed/test drift, not a P15 regression.
docs/screens/P15/SHARED_REQUEST.md §6 records it and correctly tells the
loop not to fix it here.
```

## Iteration-2 findings — disposition

| # | Finding | Iteration-3 disposition |
|---|---|---|
| 1 | **MAJOR** — `?childId=` ignored on the live branch page | **FIXED + pinned.** `_ChildProfileRoute` (StatefulWidget) re-dispatches `FamilyChildSelected` in `didUpdateWidget` when the query changes (`family_routes.dart:66-92`); `ChildProfileView` re-dispatches from `didChangeDependencies` via `GoRouterState.of(context)` (`child_profile_view.dart:39-62`); `selectChild` is idempotent and membership-gated (`family_repository_impl.dart:339-361`). Proofs: `p15_bugs_test.dart` P15-BUG-9a/9b un-skipped and green; `child_profile_view_test.dart:482` second-deep-link repro now green; `child_profile_selection_test.dart` covers overlap/unknown/last-wins and the cascade re-subscription. |
| 2 | MINOR — cross-feature `moneyPounds` import | **FIXED.** `child_profile_copy.dart:104-114` formats with the design-system barrel's `formatPounds(pence.abs()/100)`; output is provably identical to the old `moneyPounds` (same `£`+`toStringAsFixed(2)`, same sign-free `abs()`), so copy is byte-identical. |
| 3 | MINOR — `watchProfile` re-entrancy / orphaned ledger listeners | **FIXED.** Both branches of the base-stream listener now claim `ledgerSub = null` synchronously, await the previous cancel, and gate the continuation on `identical(latestParts, parts)` so only the newest run subscribes/clears (`family_repository_impl.dart:135-172`); `_selectedOf` single-sources the resolve step (`:184-191`). Two targeted tests (`child_profile_selection_test.dart:445`, `:488`) prove a live single subscription and a clean re-subscribe after addChild. |
| 4 | MINOR — duplicated roster order in `removeChild` | **Documented + requested.** `removeChild`'s repoint query cites the shared source and points at `SHARED_REQUEST.md` §5 (new one-shot `childrenInCreationOrder`) so both sites stay in sync by contract. Acceptable. |
| 5 | MINOR — `debugPrint` of child-scoped error ships to release logs | **FIXED.** Both call sites are gated `if (kDebugMode)` (`family_bloc.dart:130`, `:155`). |
| 6 | MINOR — `size: 84` bare literal | Carried consciously; `SHARED_REQUEST.md` §3 still owns the token (`NestPip.rowSlot = 84`). Code comment updated to cite the request. Acceptable. |
| 7 | MINOR — screen-local `ProfileRow` duplicates `NestListRow` + bare geometry | **Partially fixed.** Padding, tile width/height now use `NestSpacing.s3/s4/s10/gap10` (`child_profile_row.dart:99-111`); `minHeight: 56` stays a bare literal with a justification comment (off-grid, `NestDevice.tapKid` is parent-inappropriate… see finding 3 below). The duplication itself remains, explicitly temporary pending `SHARED_REQUEST.md` §1 on `main` (which would make the geometry tests swap-neutral). Accepted. |
| 8 | MINOR — `SHARED_REQUEST.md` duplicate `## 3.` and stale §2 text | **FIXED.** Renumbered to §1–§6, §2 now says `leading: (fg) => …` (the builder form P15 actually ships), §5 (roster query) and §6 (shared red test) added. Honest, complete. |

## What holds up (re-audited, iteration-3 tree)

- **ARCHITECTURE** — feature-first intact. `ChildProfile` entity unchanged; `family_repository.dart` gained only abstract methods; one BLoC per feature; DI (`family_di.dart`) and routes unchanged in shape; `presentation/widgets` imports are feature-private again (iteration-2's pocket_money import gone). The only cross-feature reads are route path constants from sibling `*_routes.dart` files and the sibling domain constant `PipProfile.evolveAtCoins` — the usual sanctioned edges.
- **RULES §1 file scope** — every P15 source edit is inside `app/lib/features/family/**`, `app/test/features/family/**`, or `docs/screens/P15/**`. The `today_view_test.dart` anchor swap (iteration 1) is recorded in `SHARED_REQUEST.md` §4. No `lib/core/**`, `lib/app/**`, another feature's directory, or `tools/screens/**` touched. `SHARED_REQUEST.md` exists and is complete.
- **Design system reuse** — tokens only for colour/spacing; `NestType` variants with `copyWith`; `NestCard`, `NestList` (+ its overlay dividers), `NestProgress` (base, not kid), `NestAvatar`, `NestButton`, `NestModal`, `NestEmptyState`, `NestStatusBar`, `showNestToast`, `NestIcon`, `PipAvatar` all reused. Zero `Color(0x…)`/`Colors.*`/raw hex in new files. The one justified escape hatch (`SvgPicture.asset(NestlingIllustrations.coin)`) mirrors `nest_icon.dart:78-83`'s documented illustration rule and `pocket_money`'s own usage.
- **DESIGN_SPEC §5 P15** — every element present and at the right geometry (hero card, 3-up stats, Pip card with "Evolves at 250 total coins"/70%/"175 of 250 · 70%", three list rows, danger "Remove Maya from family"); UK spelling throughout ("Evolves", "Owed", "No children yet"); copy byte-compared to the HTML source (U+2013, U+00B7, U+203A, U+00A3 asserted in tests). DB-driven numbers, CHILD ORDER, the `their` pronoun ruling, Pip from the child's own row (Mochi·sunny·stage 3 for Maya, Bolt·sky·stage 2 for Leo), status-bar reserve only — all per the orchestrator rules.
- **Accessibility** — every control proves `hasAction(SemanticsAction.tap)` **and** that a semantics-driven tap changes real state/DB or navigation; hero name carries `Semantics(header: true)`; the Pip avatar is `Semantics(image: true, label: …)` over `ExcludeSemantics`; every `Semantics(excludeSemantics: true)`-style wrapper in the row forwards `onTap`.
- **Performance** — no rebuild storms: bloc emissions are DB-stream-driven, `ChildProfileBody` is stateless over an immutable entity, subtitles/avatars/tiles are `const` or keyed narrowly; the redundant double-dispatch (finding 1 below) costs one extra `selectChild` write, not a rebuild loop.
- **Error handling** — load-failure renders in place + `Try again` re-adds `FamilyLoadRequested` (the stream was closed by `_closeOnError`, so retry really re-subscribes — proven in `child_profile_states_test.dart`); remove failure keeps the screen `loaded` and toasts; a *repeated* identical remove failure toasts again (iteration-3 test at `child_profile_view_test.dart:833` green); unknown/removed child ids fall back instead of throwing; `_clearOnError` prunes orphans correctly.
- **Children's Code** — parent-mode only; kid-mode redirect lives in the shared router; no analytics/ads; no child personal data in release logs anymore (finding 5 closed); the PIN subtitle's "their" reflects owner policy (no gender field).
- **Tests** — no `google_fonts`, no skips, no ignored lints in tracked files; `disposeApp(tester)` terminates every widget test (Drift timer drain, RULES §7); geometry is asserted as rects against the design at 390×844 in light *and* dark themes plus at 320/430 × 1.0/1.3, with `IntrinsicHeight` and fractional stat widths carrying the narrow-width cases; copy is asserted with exact code points; the remove flow, deep link, empty state, failure/toast paths are all covered.

## Findings

### 1. MINOR — `FamilyChildSelected` is dispatched twice on every child switch

`app/lib/features/family/family_routes.dart:52-58` (`_ChildProfileRoute`) **and**
`app/lib/features/family/presentation/views/child_profile_view.dart:45-62`
(`_ChildProfileViewState.didChangeDependencies`).

Both fire on the same in-place page update: `didUpdateWidget` sees the new
`requested` value, and `didChangeDependencies` sees the router-state registry
notify (the template the two stages were given — wrapper OR view-state —
shipped as both). The view test acknowledges this explicitly
(`child_profile_view_test.dart:546-548` — "At most twice on a cold entry: the
route dispatches it, and the view sees the same value once"). `selectChild` is
idempotent and membership-gated, so the effect is one redundant transaction and
one duplicate `app_state` emission per switch, never wrong output.

It is bounded and tested, so it does not block PASS — but it is exactly the
kind of belt-and-braces that drifts (e.g. if a future repo change makes
`selectChild` non-idempotent, the app shows two toasts of the same failure
event or an extra app_state write).

**Fix:** pick one follower. The wrapper is the cheaper one
(`didUpdateWidget` is exactly the "page re-used with a new query" signal), so
delete `_ChildProfileViewState`'s `didChangeDependencies` override, or vice
versa; then tighten the test to `expect(onEntry, 1)` instead of
`lessThanOrEqualTo(2)`.

### 2. MINOR — stale comment: `child_profile_view.dart:76-78` says BUG P15-BUG-3 "stays with the logic builder"

The text reads *"A repeated IDENTICAL remove failure is still swallowed here …
clearing `errorMessage` needs a new bloc event, so BUG P15-BUG-3 stays with the
logic builder."* BUG P15-BUG-3 was closed in iteration 2
(`family_bloc.dart:132-138` — the clear-then-raise sequence;
`family_state.dart:72-76` — the `clearErrorMessage` flag), and its widget proof
(`child_profile_view_test.dart:833`) is green. The listener-scope note is
correct; the "stays with the logic builder" half describes a defect that no
longer exists and will mislead the next stage's bug hunt. Same class of
staleness at `family_event.dart:44-48` ("Dispatched before the first load, so
the profile stream already follows the requested child" — only true for the
create-time dispatch now, not the didUpdateWidget/didChangeDependencies one).

**Fix:** rewrite both as the iteration-3 behaviour — BUG-3 is closed via
clear-then-raise; the create path dispatches the first selection, the two
followers dispatch *subsequent* query changes.

### 3. MINOR — `child_profile_row.dart:91` comment names the wrong token owner

The comment says the 56 px row meter "matches `NestSpacing.tapKid`" — but
`tapKid` lives on `NestDevice` (`core/design_system/tokens/spacing.dart:82`),
not `NestSpacing`. A copy-pasting builder reading the comment will import the
wrong owner. Same stale-owner risk at the kid-floor justification.

**Fix:** change the comment to `NestDevice.tapKid`.

### 4. NOTE (not a finding) — `flutter test test/core/family_time_test.dart` is red

One shared, `main`-shipped drift: `Seed.demo` now seeds a `to_do` row for
`q-plants`/`leo` (`lib/core/data/seed.dart:392`), so the Dubai leg of the
zone-plumbing test inserts a second row and `leoRows.single` throws. Files are
byte-identical to `main`; P15 cannot fix it under RULES §1. `SHARED_REQUEST.md`
§6 documents it and routes the one-line fix to the orchestrator. Every other
P15 suite is green (`+382 All tests passed!` on tracked family tests + today).
Flagging so the full-suite gate is not assumed green at the P15 stage boundary.

## Notes for the next stages (not findings)

- PROCESS ITEMS observed and excluded: `app/test/features/family/p15_probe4_test.dart`
  and `probe_test.dart` (untracked scratch), and the modified `.brief_*.md`/UI
  captures. The only tracked file-set the review could grade on is what `git
  diff main...HEAD` yields; that diff contains no skipped tests, no weakened
  lints, no new hard-coded colours or sizes.
- The UI check (5_ui) for iteration 3 is in flight (new `app_*_3.png`/`cmp_*_3.png`
  untracked). Per the UI verdict rule it must re-measure every band at ±2 px on
  the iteration-3 tree before it can PASS; nothing in this code diff moves
  geometry (the BUG-9 fix changes *which* child's data renders, not where), so
  a green geometry check is expected.
- The `removeChild` roster-order duplication, the `size: 84` literal, and the
  `ProfileRow`/`NestListRow` duplication are all documented in
  `SHARED_REQUEST.md` as owned-by-main work (§5, §3, §1). When the orchestrator
  merges those shared changes back, P15's diff *shrinks*: delete
  `child_profile_row.dart`, import `NestSpacing.tapKid`'s CSS equivalence from
  the design system, and drop the local `orderBy` replica — the tests already
  constrain both replacements to no-ops.
- Watch item for the bugs stage: iteration-3 added a second dispatch channel
  (finding 1). The bugs stage's in-flight `probe_test.dart`/`p15_probe4_test.dart`
  are exactly the right place to confirm `selectChild` fires at most twice per
  switch and never across a theme/text-scale rebuild — but they must not be
  committed; the assertion already lives in `child_profile_view_test.dart:546-560`.

VERDICT: PASS
