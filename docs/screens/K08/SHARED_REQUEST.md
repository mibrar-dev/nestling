# Shared request — K08 `.k8-get.off` kid-button variant

**STATUS: RESOLVED (iteration 3, build stage).** `NestKidButtonColor.muted`
landed on `main` via `shared/shared_batch8` (main `1e38e0b`). Per
`ORCHESTRATOR_NOTES.md` UPDATE (17:10) — "Once main has them, use `.muted` for
'Save up!'" — the swap is DONE in `widgets/shop_reward_card.dart`: the
unaffordable card now uses `NestKidButtonColor.muted`, which renders
`surface-2`/`ink-2` at full opacity even when disabled (the shared button
special-cases it out of the 0.45 disabled opacity), so the card finally matches
`.k8-get.off` instead of reading washed out. The `1_plan.md` §g fallback
(`white` + `onPressed: null`) is retired. The control stays disabled, so it
still offers no `SemanticsAction.tap`. Nothing outstanding on this item.

Original request, kept for the record:

Need: `NestKidButton` has no colourway for the kid shop's disabled card
button. `design/html-source/screens/K08-shop.html:29-30` defines
`.k8-get.off { background: var(--surface-2); color: var(--ink-2) }` — the same
3 px ink border, `--sh-kid` and 17 px w900 label as the on variant, but the
greyed pair at FULL opacity. Today `NestKidButtonColor.white` paints
`surface`/`ink` and then wraps the whole control in `Opacity(0.45)` whenever
`onPressed` is null, which K08 shows as a washed-out card instead of the
design's flat `surface-2`/`ink-2` block. K08 currently falls back to
`NestKidButtonColor.white` + `onPressed: null` (`1_plan.md` §g), so the one
card a child cannot afford yet is the one card that does not match the design.

Suggested API (design-system owner's call): either a
`NestKidButtonColor.muted` (bg `surface2`, fg `ink2`) that renders at full
opacity — the component keeps its `enabled: false` semantics — or an explicit
`disabledColorway` parameter. The card passes it for the "Save up!" button.

Files: `app/lib/core/design_system/components/nest_kid_button.dart`
(shared — not editable by a screen agent, hence this request).

Blocks: no. K08 builds and tests on the fallback above; the swap is one prop.

---

# Shared request — K08 BLOCKS the suite: K03 dock test asserts K08's scaffold copy

Need: the real K08 build replaced the foundation placeholder
`Scaffold(appBar: AppBar(title: Text('K08 Reward shop')))` with the design's
screen (custom `.k8-top` row, no AppBar) whose heading is the design copy
`Reward shop`. Two tests in `test/features/kid_home/kid_home_view_test.dart`
still assert the placeholder string and now fail:

- `K03 navigation dock › dock Shop opens /reward-shop` (line 2001)
  `expect(find.text('K08 Reward shop'), findsOneWidget);`
- `K03 accessibility actions › every dock button exposes a tap action and routes`
  (line 2059/2077) — the table row `('Shop', '/reward-shop', 'K08 Reward shop')`
  ends in `expect(find.text(screen), findsOneWidget);`

Both are the ONLY two failures in the whole suite (3444 pass, ~4 skip).
Everything the screen is responsible for is green: `flutter analyze` → No
issues found, and all 53 `test/features/kid_shop/` tests pass.

I cannot fix this from the K08 worktree: RULES §1 makes
`app/test/features/kid_home/**` another feature's directory, and RULES §2 sends
shared work to this file.

Suggested fix (2 lines, no production change), and the idiom this very file
already established — see its own comment at lines 1982-1983, "Route assertion,
not placeholder copy: P17 replaces the scaffold title with the real gate, but
the path is stable":

1. Line 2001 → `expect(pushedPath(tester), '/reward-shop');`
   (`pushedPath` is the shared helper in `app/test/test_scope.dart:78`; the
   route is already asserted correctly at line 2076 in the table test, so 2077
   is a redundant copy check.)
2. Line 2059 → drop the third tuple element for Shop, i.e.
   `('Shop', '/reward-shop', null)` and guard line 2077 with
   `if (screen != null) expect(find.text(screen!), findsOneWidget);` — or
   simply delete line 2077, since line 2076 already proves the navigation.

Keep the `K06 Pip nest` / `K09 My jar` assertions as they are: those screens are
still placeholders. The durable fix is to stop asserting scaffold copy for any
real screen, which is what these two lines are doing.

Why I did NOT work around it in the K08 view: the only in-tree ways to satisfy
`find.text('K08 Reward shop')` are to render that wrong string (a direct COPY-rule
violation — the HTML says `Reward shop`) or to hide it in an `Opacity(0)` node
(a screen reader would then announce "K08 Reward shop" on a real screen, and
`find.text` matches such a node because it skips only `Offstage`). Both trade a
correct screen for a stale test, so the test is what should change.

Files: `app/test/features/kid_home/kid_home_view_test.dart` (lines 2001, 2059,
2077).

Blocks: yes — `flutter test` does not go green until this lands. No K08
production or test change is required for it.

---

# Shared request — K08 BLOCKS the suite: K03 dock test asserts K08's placeholder copy

**STATUS: RESOLVED (iteration 3, build stage).** The fix landed on `main` in
`shared/shared_batch8` (main `1e38e0b`) and is exactly what was proposed below:
`kid_home_view_test.dart` now reads
`expect(pushedPath(tester), '/reward-shop')`, and the `K08 Reward shop` string is
gone from the file entirely (main also added `test/meta/no_placeholder_titles_test.dart`
to stop this class of assertion coming back). With `main` merged, the whole-app
suite is green: **3795 passed, ~4 skipped, 0 failed**. Nothing outstanding.

Why it took three iterations to be reported here: the fix was already on `main`
before this stage ran, but the loop's merge into `screen/K08` predated it, so the
K08 tree still carried the stale copy. Per the orchestrator's rule that a
branch-behind-main is a process item and not a finding, I merged `main` into the
worktree myself to verify, rather than logging it as a fourth-iteration blocker.

The original escalation, kept for the record:

STATUS (iteration 2, build stage) — **ESCALATION, 2nd iteration, still open.**
Seven stage reports now cite this request (`1_plan`→`2_build` it1/it2, `2a`,
`2b`, `3_test`, `4_review`, `5_ui`, `6_bugs`) and every one of them re-confirms
the same two failures. Whole-suite numbers moved from 3444 pass (it 1) to
**3765 pass, ~4 skip, 2 fail (it 2)** — the K08-owned tests grew from 53 to 143
and are all green; the 2 failures are unchanged and are both in this file's
scope. The orchestrator owns `main`, and nothing in the K08 worktree can land
the two-line edit, so this needs one action from the orchestrator to unblock the
screen. It is now the single thing standing between K08 and a green suite.

Since iteration 1 the two assertions moved line numbers but the shape is
unchanged — both still expect the foundation placeholder's `K08 Reward shop`,
which the real screen (correctly, per the COPY rule) renders as `Reward shop`.

Iteration 2 also removed the one thing that had made the tree *look* green for a
while: `k08_bugs_test.dart`'s price proof was pumping `NestlingApp` without
`setUpTestScope()`, so GetIt had no `AppModeController` and *every* finder in
that file found nothing (it read as a pass for the two "Sorted" bug proofs, and
as a false failure for K08-BUG-3). Fixed in iteration 2 — see `2b_build_ui.md`
"Verification" — so the feature's own suite now reflects reality:
`k08_bugs_test.dart` is 7/7 green and `test/features/kid_shop/` is 143/143.

Two healthy K03 assertions still fail (they are the only two failures in the
whole suite), exactly as filed above. Suggested fix unchanged:
`pushedPath(tester) == '/reward-shop'` (or drop the third tuple element).
