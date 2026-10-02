# P05 · Add children — bug hunt (STAGE 6, iteration 3)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on the
iteration-3 build (working tree after `21a7e02 P05: loop iteration 2`, main
merged through `8de83cb`; iteration-3 fixes uncommitted).

Gates on this build: `dart format` clean · `flutter analyze` No issues found! ·
`flutter test test/features/family` **108 passed, 2 skipped, 0 failed** · full
`flutter test` is **red on one shared test file outside RULES §1**
(`app/test/app/router_push_test.dart`, pre-existing, see *Repo-gate blocker*
below) · no file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — P05-BUG-1…8 run
un-skipped and green; the two new proofs carry `skip: true` with the id in the
name so the suite stays green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ the nine fixed proofs pass, P05-BUG-9 and P05-BUG-10 fail exactly as
recorded.

**Result: 1 major open (P05-BUG-9, the mandatory CHILD ORDER ruling is still
unsatisfied and is fixable inside RULES §1), 1 minor open (P05-BUG-10, kid
card 8 px taller than the design), 0 other new bugs. VERDICT: FAIL.**

---

## P05-BUG-9 — MAJOR — children are still listed alphabetically (Leo | Maya), not in the order they were added (Maya | Leo)

**Where:** `app/lib/features/family/data/family_repository_impl.dart:37-41`
consumes the core helper `_db.watchChildren(...)`, which orders by `nickname`
(`app/lib/core/data/app_database.dart:307-312`), so the grid renders
**Leo left, Maya right** — the reverse of the design and of the mandatory
ruling (“children are always listed in the order they were added … never
alphabetically — in every screen and repository”; iteration-3 note 2 also says
*“order by rowid meanwhile”*).

**Repro / proof:** `[P05-BUG-9] Maya renders before Leo (order added, never
alphabetical)` — demo seed (Maya inserted first, then Leo), 390×844:
`maya.left = 210`, `leo.left = 30`; expected `maya.left < leo.left`.

**This is fixable inside RULES §1 — the build notes’ “cannot be done” claim is
wrong** (review finding 2). `features/family/data/**` is an allowed path and
`FamilyRepositoryImpl` owns its database handle, so it can run its own ordered
query instead of the core helper. I verified the fix independently against the
demo DB — rowid ordering returns exactly `[Maya, Leo]`:

```dart
// app/lib/features/family/data/family_repository_impl.dart  (data/** = RULES §1)
Stream<List<ChildrenData>> _watchChildrenInAddedOrder() {
  return (_db.select(_db.children)
        ..where((c) => c.familyId.equals(Seed.familyId))
        ..orderBy([
          (c) => OrderingTerm(expression: CustomExpression<Object>('rowid')),
        ]))
      .watch();
}
```

**Suggested fix:** use the query above in `watchChildren()` (keep the filed
shared request as the durable fix), drop the `TODO(P05)` deferral in
`kid_card_grid.dart:13-16`, and **flip or delete**
`add_children_test.dart:1487-1501` (`'roster order comes from the database
(nickname order)'` asserts `leo.left < maya.left` — it pins the exact order the
ruling forbids and will contradict the fix; review finding 4).

---

## P05-BUG-10 — MINOR — kid card renders 124 px tall against the design’s 116, pushing the whole form region 8 px low

**Where:** `app/lib/features/family/presentation/widgets/kid_card_grid.dart:28-35`
— `cardH` ends in a trailing `NestSpacing.gap10` “pencil clearance” and uses
4 px (`s1`) between the name and age, where the design’s flex column has
`gap: 2` + `margin-top: 4` = 6.

Design math (HTML/CSS): `12` padding + `44` avatar + `2` gap + `24` name +
`2+4` gap/margin + `18` age + `10` padding = **116**; `.edit` is
`position: absolute`, so the 44 px pencil adds no height. App `cardH` =
`22` chrome + `44` + `2` + `24` + `4` + `18` + `10` = **124**.

**Repro / proof:** `[P05-BUG-10] kid card height matches the design 116 (±2)` —
both cards measure **124.0** (expected ≤118). This is the P05-local half of the
stage-5 iteration-3 deviation 2 (h3/Nickname/Age-band +8, chips +13,
swatches/caption +20); the remaining +12 at the chips is the shared `NestChip`
44-tall tap box around a 32 px visual (`SHARED_REQUEST.md` #3 — not fixable in
P05).

**Suggested fix:** make the name→age spacing 6 (`gap2` + `s1`) and drop the
trailing `gap10` from `cardH` → 116; keep the existing pencil-inside-card
assertion (the pencil overlays the top-right and fits in a 116 card).

---

## Iteration-1/2 bugs — all fixed and regression-proofed

| # | Bug | Fix landed | Proof status |
|---|---|---|---|
| P05-BUG-1 | Chips stacked full-width; swatches under the CTA | shared `NestChip` fix + P05-local shrink (workaround now redundant) | green |
| P05-BUG-2 | Same-frame double submit | `saveInProgress` guard | green |
| P05-BUG-4 | Retry leaked watchers | `_closeOnError` | green |
| P05-BUG-5 | Typing mid-save discarded | `lastSavedNickname` conditional clear | green |
| P05-BUG-6 | `ageYears` always 7 | band → age mapping | green |
| P05-BUG-7 | H1 had no header landmark | `Semantics(header: true)` | green |
| P05-BUG-8 | Grid re-applied device insets | `padding: EdgeInsets.zero` | green (proof with 47/34 insets) |

Re-read the iteration-3 diff adversarially: the `lastSavedNickname` sentinel
clears correctly, the `debugPrint` on an unknown colour logs only the token
(no child data), and the h1’s `\u2019` matches the HTML’s `&rsquo;`.

## Verified sound (adversarial probes on this build)

| Area | Result |
|---|---|
| Rapid double taps | two same-frame taps with the real DB insert **one** child |
| Data edge cases | 0/1/6 children, “Maximilian-Alexander” + long names at 320/1.3 → no overflow, no exceptions |
| Chips | one row on device (UI check), left-aligned on the card edge, 8 px gaps; in-test 2 rows only from the wider fallback font |
| Back / deep links | Back → `/privacy`; direct launch lands on the screen |
| Kid-mode guard | kid-mode deep link → `/parental-gate` |
| Restart / Drift persistence | child added, fresh app launch over the same DB → card present |
| Dark mode | tokens unchanged; UI check dark ≈ light (4.88% vs 4.87%) |
| Async gaps | bloc drops late emits; `onSaved` callbacks `mounted`-guarded |
| Money / timezone | P05 renders no money or dates — N/A by construction |
| COPY ruling | h1 `’` U+2019, subtitle `—` U+2014, bands/ages `–` U+2013, “Avatar colour”, all other literals character-exact vs the HTML |
| Owner rules | bottom edge and 20 px gutters unchanged and green (existing tests + UI check) |

## Repo-gate blocker (shared file, not a P05 code defect)

`app/test/app/router_push_test.dart:104` still passes
`showsFrom: 'P05 Add children'` — the pre-build placeholder title — so the full
`flutter test` run is red (reproduced: `+3 -1`, line 37). The file arrived from
main in `7eaa1f7`; `app/test/app/**` is outside RULES §1. Already filed with
the one-string fix (`'Who\u2019s in your nest?'`) in `SHARED_REQUEST.md`;
listed here only so the gate record is honest. Not counted against the P05
diff.

## Fix-pass notes (from the iteration-3 review, still open)

* Drop the four now-redundant `IntrinsicWidth` wrappers in
  `add_child_form_card.dart` (the shared chip shrink-wraps by construction) and
  refresh the stale comments (review finding 3).
* Correct the “cannot be done in RULES §1” feasibility claims in `2_build.md`
  and `3_test.md` (review finding 6).

VERDICT: FAIL
