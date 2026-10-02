# P05 · Add children — build notes (STAGE 2)

Route `/add-children` (feature `family`, parent mode). Implemented exactly per
`docs/screens/P05/1_plan.md` except for the deviations logged below (each
with evidence).

## Files changed (RULES §1 only)

- `app/lib/features/family/presentation/bloc/family_event.dart` — added
  `FamilyChildrenRequested`, `FamilyDraftChanged(nickname/ageBand/
  avatarColour)`, `FamilyAddChildRequested(onSaved)`. `FamilyLoadRequested`
  untouched.
- `app/lib/features/family/presentation/bloc/family_state.dart` — additive
  fields only: `children` (`[]`), `draftNickname` (`''`), `draftAgeBand`
  (`'7-9'`), `draftAvatarColour` (`'peach'`), `nicknameError` (null),
  `saveInProgress` (false). `copyWith` clears `nicknameError` only when
  `null` is passed explicitly (sentinel default), so existing call sites
  keep their behaviour.
- `app/lib/features/family/presentation/bloc/family_bloc.dart` — handlers
  for the three new events; `FamilyLoadRequested` now subscribes to the
  combined `watchItems` + `watchChildren` stream (single `emit.forEach`,
  RULES §4). Helpers `avatarColourFor` / `displayAgeBand` (hyphen → en-dash,
  `13+` passes through).
- `app/lib/features/family/presentation/views/add_children_view.dart` —
  replaced the placeholder: status bar + compact `NestNavBar` + scroll
  (head, kid grid / empty shrink, form card) + `NestBottomCta` (Add another
  48 + Continue 52 + caption). Loading → spinner; failure → message +
  secondary Try again (re-adds `FamilyLoadRequested`). Controller/focus live
  in the stateful view (see deviation 4).
- `app/lib/features/family/presentation/widgets/kid_card_grid.dart` — new:
  2-up grid, computed columns and text-scaler-derived row height (hugs
  content at 320 px and 1.3×), `NestCard` + `NestAvatar` + `Edit <name>`
  pencil (`editChild-<id>`, 44×44, 20 px `ink3` icon).
- `app/lib/features/family/presentation/widgets/add_child_form_card.dart` —
  new: `NestCard` padding 14, `NestTextField` (`nicknameField`), 4
  `NestChip`s (`ageChip-<band>`, 7–9 default), 5 swatch circles
  (`swatch-<colour>`, peach default, 3 px ink ring when selected), caption.
  Label/field rhythm 10/8/4/8/4/6 per plan.
- `app/test/features/family/add_children_test.dart` — new: 28 tests (bloc
  roster/draft/save/validation/failure/helpers + widget light/dark/empty/
  states/navigation/size).
- `docs/screens/P05/SHARED_REQUEST.md` — new (2 non-blocking requests).
- `docs/screens/P05/2_build.md` — this file.

No files outside RULES §1 touched (`git status` shows only the above plus
these notes).

## Deviations from 1_plan.md (with evidence)

1. **Retry re-adds `FamilyLoadRequested` only** (plan §d said both). Two
   concurrent `emit.forEach` subscriptions deadlock: the first never
   completes, so the second handler never runs. The load subscription covers
   both streams, so one event recovers both.
2. **Navigation uses `go`, not `push`/`pop`** (plan §c). A widget probe
   proved `GoRouter.of(ctx).push('/pocket-money-setup')` from a top-level
   route leaves `currentConfiguration` unchanged (silent no-op), while
   `go(...)` navigates. The funnel precedent (P01 `welcome_view.dart`) and
   the P08→child-profile precedent (`go` + `?childId=`) both use `go`, and
   the funnel keeps a depth-1 stack so `pop` could never return to P04.
   Edit → `go('/child-profile?childId=<id>')` (same contract P08 sends;
   P15 should read `queryParameters`, not `extra`). Filed as shared request
   2 (blocks: no).
3. **`NestNavBar` compact + `title: null` crashes** (plan §a). The middle
   `Expanded` builds a `Spacer` (itself an `Expanded`) → competing
   `FlexParentData` assertion. Workaround behind `TODO(P05)`: `title: ''`
   (visually identical back-chevron-only bar). Filed as shared request 1
   (blocks: no).
4. **Controller/focus owned by the stateful view**, not a stateful form
   widget: the bottom CTA must read the field (Continue-with-text) and
   refocus it (add-another), so ownership sits one level up; the bloc stays
   the source of truth (every keystroke → `FamilyDraftChanged`, save clears
   both via `BlocListener`). Behaviour matches plan §c exactly.
5. **Nickname submit (done action)**: `NestTextField` exposes no
   `onSubmitted` passthrough (DS, read-only here), so the Done key only
   dismisses the keyboard. Not filed as shared (minor, non-blocking):
   add-another and Continue cover the action; revisit only if the UI stage
   demands it.
6. **Post-navigation DB assertion uses one-shot `get()`**, not
   `watchChildren(...).first`: the watched-first future never resolved after
   navigating away (test hung past all timeouts); `get()` is deterministic
   and asserts the same row.

## Fix items (plan §f test plan → what was done)

- Bloc: roster/load/draft/add/validation/failure paths covered with
  `blocTest` + mock repository (`addChild` arg-verified trimmed).
- Widget: demo roster (Maya `Age 7–9`, Leo `Age 4–6`, edit labels), chip
  single-select, swatch ring, add-another save + clear, empty-field inline
  error, Continue empty/direct + Continue save-then-setup, back → privacy,
  edit → child-profile + `childId`, fresh-seed form-only, dark mode,
  loading spinner, failure + Try-again recovery (+ dark), 320 px @ 1.3×
  scroll-through with no overflow. Every app-pumping test ends with
  `disposeApp`.
- Tokens only: no hard-coded colours/sizes (gutters 20, spacings via
  `NestSpacing`, type via `NestType`, radii via DS components). Bottom edge:
  `NestBottomCta` is last in the `Column` with its own `SafeArea(top:
  false)` surface-to-edge — no strip under the bar.

## Verification tails

`dart format .` — clean (re-ran after every edit).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:09 +507: All tests passed!` (exit 0),
including the 28 new `test/features/family/add_children_test.dart` tests.
Every widget test that pumps the app ends with `disposeApp(tester)`.

VERDICT: PASS
