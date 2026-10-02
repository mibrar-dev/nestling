# P05 · Add children — bug hunt (STAGE 6, iteration 4 — final)

Route `/add-children` (feature `family`, parent mode). Adversarial re-hunt of
the iteration-4 build (working tree after `d5e5621`, main merged through
`8de83cb`; iteration-4 fixes uncommitted). No screen code was changed and
**no new bug was found**.

Gates on this build: `dart format` clean · `flutter analyze` No issues found! ·
`flutter test test/features/family` **116 passed, 0 skipped, 0 failed** · full
`flutter test` **642 passed, 0 skipped, 1 failed** — the single failure is the
shared `app/test/app/router_push_test.dart`, outside RULES §1 (see *Carried
shared items*) · no file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — **11 proofs, all
un-skipped and green** (P05-BUG-1…10 plus the two iteration-4 fixes). No proof
needed to be re-skipped; no `skip` remains anywhere in
`app/test/features/family/`.

**Result: 0 new bugs, 0 P05-owned bugs open. The screen’s only remaining
deviation is a shared design-system component (the 44 px chip tap box vs the
design’s 32 px row) and the repo gate is red on a shared test file — both are
carried shared items, outside RULES §1 and already escalated.
VERDICT: PASS.**

---

## Iteration-3 findings — closed and re-verified

| # | Finding | Evidence |
|---|---|---|
| P05-BUG-9 (major) | children rendered alphabetically (Leo | Maya) | **fixed** — `FamilyRepositoryImpl._watchChildrenInAddedOrder` orders by `rowid` inside `features/family/data/**`; probes on `Seed.demo` and `Seed.onboarding_kids` both read **Maya left (30), Leo right (210)**; new children append; rename keeps insertion order (test stage’s rename proof) |
| P05-BUG-10 (minor) | kid card 124 vs design 116 | **fixed** — `cardH` = 22 + 44 + 2 + 24 + 6 + 18 = 116; probe measures card height **116.0**, avatar 257–301, name 303–327 (gap 2), age 333–351 (gap 6) — the HTML rhythm exactly |
| review 3 | dead `IntrinsicWidth` wrappers | removed; the shared `NestChip` shrink-wraps; BUG-1 geometry proofs still green |
| review 4 | test pinned the forbidden alphabetical order | flipped to `maya.left < leo.left`; now proves the ruling |
| review 6 | wrong “cannot be done in RULES §1” claims | corrected in the build/test notes |

The iteration-4 diff was re-read adversarially: the rowid query filters by
family and preserves stream re-emission; `combineLatest3` still emits the
roster with quest counts; the card’s Column spacing (`gap2`, `gap6`) matches
the `cardH` formula at 1.0 and 1.3×; the removed wrappers left the group
semantics and tap targets intact.

## Adversarial checks this iteration

| Check | Result |
|---|---|
| Order — demo seed | Maya left, Leo right ✓ |
| Order — `onboarding_kids` seed (UI-check state) | Maya left, Leo right ✓ |
| Order — add + restart over the same DB | `[Ollie]` persisted and rendered; rowids survive restart ✓ |
| Order — rename / append / bloc passthrough | covered by the test stage’s five-test group, all green |
| Card geometry | height 116.0; avatar/name/age gaps 2 and 6 — design-exact ✓ |
| Chip row | boxes 73.8 / 73.8 / 102.3 / 73.8 × **44.0**; one row on device (UI check), 8 px gaps, left-aligned ✓ (the 44 height is the carried shared item) |
| Rapid double taps | two same-frame taps with the real DB insert one child ✓ |
| Kid-mode guard | kid-mode deep link → `/parental-gate` ✓ |
| Dark / owner rules / COPY | UI check iteration 4: dark within 0.5% of light; CTA to the physical edge; curly `’`, em/en dashes, “Avatar colour” character-exact ✓ |
| Data edges (0/1/6 children, long names, 320×1.3) | existing tests + probes: no overflow, no exceptions ✓ |
| Money / timezone / async gaps | P05 renders no money or dates; bloc drops late emits, callbacks `mounted`-guarded — N/A / sound ✓ |

## Carried shared items (not P05 defects — no local fix exists)

1. **`NestChip`’s 44 px layout box vs the design’s 32 px chip row** — the one
   remaining UI deviation (iteration-4 UI check deviation 1: chip labels +5,
   “Avatar colour”/swatches/caption +12, band5 drift 10.8%). The tap minimum
   is the layout box (`ConstrainedBox(minWidth 44)` + 4.5 px padding around the
   35 px pill), so every row below sits 12 px low. I probed the obvious local
   interim — `SizedBox(height: 32)` + `OverflowBox(44)` around each chip — and
   it **cannot** work in P05: the wrapper lays the row out at 32 but the
   6 px of tap area above/below the parent no longer hit-tests (measured:
   above-edge tap 0 hits, centre tap 1 hit), i.e. the effective target drops
   to 32 px and violates the 44-min rule. `core/**` is read-only for this
   screen, so the fix is a shared DS decision (overlay/alternative geometry)
   or an explicit orchestrator accept of the +12. Note for the orchestrator:
   `SHARED_REQUEST.md` #4 is marked “LANDED” for the **width** half only; the
   **height** half is still open and that status header is misleading.
2. **`app/test/app/router_push_test.dart:104`** still passes
   `showsFrom: 'P05 Add children'` (the pre-build placeholder title), so the
   full suite is red. Filed since iteration 3; a shared fix worktree
   (`_shared_router_push_test_fix`) is already briefed.
3. **Shared typography line-box request** (`SHARED_REQUEST.md` §7): its
   premise (a +4/+8 cumulative per-row drift from runtime font metrics) is
   **not reproduced** by the iteration-4 UI landmarks — h3/Nickname/Age-band
   are ±0 vs the design, and the residual +5/+12 is exactly the chip box
   above. Worth re-checking before spending a shared batch on font metrics.

## Notes

* The BUG-9 proof and the test stage’s five-test order group together pin the
  ruling so the durable shared `createdAt` fix cannot regress it.
* `rowid` remains the documented interim (SQLite `VACUUM` caveat noted in the
  repository comment); the shared request stays open as the durable fix.

VERDICT: PASS
