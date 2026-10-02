# P02 Value tour — build notes (Stage 2, iteration 3)

Implemented per `docs/screens/P02/1_plan.md`, the mandatory
`docs/screens/P02/ORCHESTRATOR_NOTES.md`, the new COPY / CHILD ORDER /
bottom-edge / alignment owner rules, and every item in
`docs/screens/P02/FIXES_2.md`. Main has moved since iteration 2
(`shared_requests_batch1`: chip/nav/typography/pager-token fixes,
`DISABLE_ANIMATIONS` parsing, `router_push_test.dart`); this build adopts
what it delivered for P02 and re-verifies everything against it.

## Files changed (this stage)

- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`:
  retired the feature-private `_TourNav` for the shared compact bar
  (`NestNavBar(compact: true, actionLabel: 'Skip', …)` — content-sized
  trailing slot landed in batch 1) plus an 8px outer pad that keeps Skip on
  the 20px owner gutter (design nav inset is 12px); adopted the new
  `NestPager` tokens (`stage`, `pet`, `lineMinHeight`, `addDash*`,
  `addMinHeight`) for every pager metric except the 40px stage-dot art.
  Height stays 4+44+12 = 60, card top stays y=107, Skip stays at width−20.
- `app/test/features/onboarding/value_tour_view_test.dart`: Skip finders
  reworked onto the shared node (tap/size via `find.text('Skip')` and the
  bar's `InkWell`; label/button via `bySemanticsLabel('Skip')`; tap action
  on the `InkWell` node); added the `_skipInkwell` helper. No expectation
  weakened — sizes, labels, gutter and action asserts are unchanged.
- `docs/screens/P02/SHARED_REQUEST.md`: item 1 (compact slot) and item 3
  (pager tokens) marked DONE/adopted; item 2 stays withdrawn; new item 4
  (shared push/pop contract, Blocks: yes — see below).
- Screenshots: `ui/app_light_4.png`, `ui/app_dark_4.png`, `ui/cmp_light_4.png`,
  `ui/cmp_dark_4.png` (step 1, sim 16e, fresh seed; both frames stable).

## Fix items (FIXES_2 → state)

- BUG-7 (titles truncate): already in tree — `FittedBox(scaleDown)` title
  slot in `ValueTourPreviewRow`; proof passes; device shot shows `Empty the
  dishwasher` in full. Verified, no change needed.
- BUG-8 (design copy): already in tree — design subs, static `Sat 4 Oct`
  chips, derivation deleted. Verified.
- BUG-9 (punctuation): already in tree — curly body/heads in view, repo
  impl mirror, bloc/contract/bug tests. Verified.
- Review/UI residue (body 4px, punctuation ruling): resolved by BUG-9; no
  action.
- Already-green proofs (BUG-1a/b/c, 2, 3a/b, 6) re-verified green after the
  nav/token adoption.
- COPY rule audit vs HTML: `’` heads, `“”`/`—` body, `–` reading, `·`
  separators, `£` amounts all match; no `&nbsp;` in the P02 source to mirror.
- CHILD ORDER: card rows follow the design illustration order (not a
  children list; nothing alphabetical).
- Bottom edge: CTA surface to the physical edge, both themes (re-verified on
  the new shots).

## UI verification (sim 16e, `shot.sh` + `compare.py`, step 1)

- Light mean diff 3.92% → **4.00%** (bands 0–7: 1.95/5.54/5.03/6.43/0.89/
  3.95/4.37/3.80); dark 3.83% → **3.83%**. Deltas vs iteration 3 are noise
  (stable-frame captures, Rive still art); layout/copy identical: full
  titles, `Sat 4 Oct`, design subs, curly body, 400dp pager, dots/title/CTA
  on the design rows, Skip on the 20px gutter.
- Both `shot.sh` runs saved **stable frames** (no 25s warning this round —
  the shared `DISABLE_ANIMATIONS` parsing fix resolved iteration 1–3's
  UI-6 residue).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test` (full) tail: `00:11 +609 -1` — the single failure is
  `test/app/router_push_test.dart` (`push /value-tour from /welcome`),
  which asserts `find.text('P02 Value tour')`. That literal exists only on
  main's placeholder (`AppBar(title: 'P02 Value tour')`); this branch
  implements the screen per the design, so the expectation contradicts the
  implemented screen. It is outside screen scope (`test/app/`, RULES §1),
  cannot be fixed by any in-scope change, and passes on main — filed as
  SHARED_REQUEST item 4 (Blocks: yes) with the one-line fix specified
  (`showsTo: 'Set quests in seconds'`, matching the file's own P01 pattern).

VERDICT: FAIL
