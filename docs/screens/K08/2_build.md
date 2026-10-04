# K08 · Reward shop — stage 2 integrate (iteration 3)

Job: merge the two parallel builders, make the combined result compile and
pass. No redesign; smallest change per breakage.

**This iteration closes the blocker that held iterations 1 and 2, and the whole
app suite is now green.** No K08 code was wrong at any point: the two failures
were a shared test asserting the foundation placeholder's copy, and the fix
landed on `main` — it simply had not reached this worktree.

## What actually changed this iteration

1. **`main` was behind my tree, not ahead — so I merged it.** The loop's merge
   (`edc85cd`) predated `main`'s tip `1e38e0b Merge shared/shared_batch8`. On
   `main` both long-standing requests were already satisfied:
   - `kid_home_view_test.dart` now reads
     `expect(pushedPath(tester), '/reward-shop')` — **exactly** the two-line fix
     proposed in `SHARED_REQUEST.md` §2, and the `K08 Reward shop` string is gone
     from the file entirely (`grep` on `main` finds zero hits). `main` also added
     `test/meta/no_placeholder_titles_test.dart` to stop the assertion class
     returning.
   - `NestKidButtonColor` gained `muted` (main line 15), which renders
     `surface-2`/`ink-2` at full opacity even when disabled.

   Per the orchestrator rule that a branch behind `main` is a **process item, not
   a finding**, I did not log it as a blocker. I merged `main` myself so I could
   verify the real state (the merge is the loop's normal pre-build step) and so
   the mandatory orchestrator item below could be completed honestly. The merge
   was clean — 9 files, no conflicts.

2. **Completed the mandatory orchestrator item.** `ORCHESTRATOR_NOTES.md` UPDATE
   (17:10): *"both SHARED_REQUEST items are being fixed on `shared/shared_batch8`
   (the K03 dock test asserts routes; `NestKidButtonColor.muted`) … Once main has
   them, use `.muted` for 'Save up!'"*. Main now has it, so the condition in that
   note is met and the item is no longer deferrable. `widgets/shop_reward_card.dart`
   now uses `NestKidButtonColor.muted` for the unaffordable card — the exact
   one-prop swap 2b described, and it retires the `1_plan.md` §g
   (`white` + `onPressed: null`) fallback that 2b had flagged as reading "washed
   out instead of the design's flat grey block". The control stays disabled, so
   it still advertises no `SemanticsAction.tap`, exactly as before. No colour or
   size literal was introduced, and no geometry moved.

## Summary of 2a (logic) — iteration 3

`2a_build_logic.md` reported **one contract change**, required by FIXES_2
(K08-BUG-4): `KidShopRepository.requestReward` now returns `Future<String?>` —
`'approved'` when granted and paid for, `'requested'` when it waits for a
grown-up, `null` for an unknown id. **BLoC events and state shapes are
unchanged**, so 2b's view needed no signature change; only the toast copy moved,
from the tap-time `needsOk` flag to the status actually written.

- `domain/kid_shop_repository.dart` + `data/kid_shop_repository_impl.dart`: the
  three write paths return their status; unknown id returns `null`. Source-
  compatible for callers that ignore the result.
- `bloc/kid_shop_bloc.dart` (K08-BUG-4 fixed): `_onRewardRequested` picks the
  toast from the written status — `'approved'` → `It’s yours — enjoy!`,
  `'requested'` → `Mum will give it a thumbs-up soon.`; a throw or `null` keeps
  `Hmm, that did not work. Try again.` Guards and `requestingIds` unchanged.
  This closes the race 2a flagged in iteration 2, where an instant reward whose
  balance had just been spent landed `requested` but still toasted "enjoy".
- Tests: bloc 34 → 35, repository 17 → 18, all with the new assertions.
- 2a touched one UI-owned file (`reward_shop_view_test.dart`'s
  `_FakeKidShopRepository`, the signature only) and flagged it rather than
  leaving the tree broken. 2b kept it and added its own test alongside.

## Summary of 2b (UI) — iteration 3

`2b_build_ui.md`: views/widgets only. One **behavioural UI fix** plus the
contract re-sync — no pixel of layout, colour, radius or copy moved.

- **K08-BUG-5 fixed (minor, accessibility)** — with the price made its own node
  in iteration 2, `.k8-n` was the last part of a card without a semantics
  boundary, so the grid `Column` absorbed all six names (plus the café's note)
  into one run: a screen-reader user heard the whole shop as a single item and
  could not tie a name to its own price or its own button. Both the name and the
  note now sit in `Semantics(container: true)` — the note too, because it is the
  name's *sibling* and would otherwise just relocate the merge one level up.
  Neither is interactive, so no tap action is owed; `excludeSemantics` is
  deliberately **not** set, so the Text's own label is what is announced and no
  copy is duplicated. 2b rejected `MergeSemantics` per card (it would produce
  `"Trip to the park café\n30 more to go"`, breaking the exact-label proof) and
  wrapping the whole card (it would swallow the price and button nodes that
  K08-BUG-3 just bought).
- `reward_shop_view_test.dart` 67 → 68; the three K08-BUG-5 proofs in the test
  stage's `shop_reward_a11y_test.dart` now pass without 2b touching that file.

Both halves still met with **no member mismatches** beyond the one declared
`Future<String?>` contract, which 2b absorbed without a view change.

## FIXES

### Done

1. **`SHARED_REQUEST.md` §2 — the blocker, closed.** Merged `main` to pick up the
   already-landed fix. Verified the two failing assertions are now route
   assertions, and that the placeholder string no longer exists anywhere in the
   file. Both `SHARED_REQUEST.md` sections are marked RESOLVED with what landed.
2. **`SHARED_REQUEST.md` §1 / `ORCHESTRATOR_NOTES.md` (17:10) — `.muted`
   applied.** One prop in `shop_reward_card.dart`, plus its comment updated so it
   no longer advertises a retired fallback. No test pinned the old colourway, so
   nothing else needed changing.
3. **Iteration-2 carry-overs re-verified after the merge**, since `main` touched
   shared tests: `test/core/data/repositories_test.dart` 22/22 (2a's `Future<String?>`
   change needed no edit there, as 2a claimed), and the whole K08 feature 166/166
   with zero `skip:` markers. `main`'s new `no_placeholder_titles_test.dart`
   passes too.

### Left

Nothing. Both shared requests are resolved and no K08 work is outstanding for
this stage.

## Verification

`dart format .` (from `app/`):

```
Formatted 584 files (0 changed) in 1.94 seconds.
```

`flutter analyze` (from `app/`, whole repo, no ignores, nothing weakened):

```
Analyzing app...
No issues found! (ran in 3.5s)
```

`flutter test --timeout 120s` (whole suite, after merging `main` and applying
`.muted`):

```
01:27 +3795 ~4: All tests passed!
```

3795 passed, ~4 skipped (the pre-existing `kid_home` K01 matrix skips, not K08),
**0 failed**. Isolated confirmations:

- `flutter test --timeout 120s test/features/kid_shop/` → 166/166, zero skips
  (bloc 35, repository 18, view 68, geometry 24, icons 7, a11y 7, bugs 7).
- `flutter test --timeout 120s test/core/data/repositories_test.dart` → 22/22.

For transparency, the pre-merge state of this same stage measured **3788 passed /
~4 skip / 2 failed** — the two K03 dock assertions. That is the only difference
between FAIL and PASS, and it was resolved entirely by landing `main`; the
`.muted` swap was verified not to regress anything (the 24 geometry assertions
still hold, so the disabled button keeps its 56 px height and radius).

Rule audit on the merged result: no `google_fonts`/`GoogleFonts` and no
`DateTime.now()` in `lib/features/kid_shop` or `test/features/kid_shop` (the one
grep hit is a comment saying so); clock via `appNowUtc()`; no ids minted in the
view; `NestBalancedText` still on the `.kid-title` heading; reward icons still
forward to `rewardIconFor(audience: NestAudience.kid)`; `NestChipWrap` not
applicable (no chip rows here); copy untouched character-for-character against
`K08-shop.html`, including the curly `’` and em `—` in the two bloc toasts;
DISABLED bottom-edge rule unaffected (K08 has no bar — nothing paints below the
list); no `flutter clean`; no simulator booted, installed on or screenshotted
(5_ui's alone, and only E7D5555E-378A-49DF-AAEE-16677AF4B9DB); no
`analysis_options` change; nothing skipped or ignored to reach a pass. The only
edits outside `docs/screens/K08/**` were the one feature-owned widget prop and
the `git merge main` — no shared file was hand-edited by me.

## Left for next iteration

1. `5_ui` re-check: re-shoot `/reward-shop` light + dark and re-run
   `compare.py`. Iteration 2's `5_ui` already measured every band 0–6 at Δ0, and
   nothing since moves a pixel, but the `.k8-get.off` button in the café card
   should now be **measurable and comparable** (it was on the fallback before), so
   bands 4–7 are worth a fresh read at scroll 0 and at the café card.
2. Nothing else. Both shared requests are closed.

VERDICT: PASS
