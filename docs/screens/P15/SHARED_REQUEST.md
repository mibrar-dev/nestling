# Shared request — P15 two design-system items P15 cannot fix inside its feature

Both items block a *pixel- and copy-exact* P15 and live in
`app/lib/core/design_system/**`, which RULES §1 forbids this screen from
editing. They are also ORCHESTRATOR_NOTES.md item 2 (mandatory).

## 1. `NestListRow` starves the main column (P15-BUG-5)

Need: `NestListRow` (`app/lib/core/design_system/components/nest_list_row.dart`,
the row's `Row`) lays out `[tile 40, gap 12, Expanded(main), gap 12, Flexible(tail)]`.
Flutter hands each flex child an EQUAL share of the free space, so the
trailing reserves half the row even when its text is 20 px wide, and
`.list-main` gets the rest of only half.

Measured on `/child-profile` at 390, text scale 1.0
(`child_profile_theme_size_test.dart`, bundled fonts loaded):

| row | main column gets | subtitle needs | result |
|---|---|---|---|
| Kid PIN | 129.0 px | 171.2 px (`On · Maya knows their code`) | **ellipsised** |
| Quests | 129.0 px | 162.1 px (`6 active · 4 daily, 2 weekly`) | **ellipsised** |
| Pocket money | 129.0 px | 169.2 px (`£3.00 a week · Owed £4.20`) | **ellipsised** |
| PIN trailing `Change ›` | 129.0 px reserved | 70.7 px intrinsic | 58.3 px wasted |

Every subtitle is also ellipsised at 320 (94.0 px available; 68–77 px cut) and
at 430 (149.0 px; 13–22 px cut), at both 1.0 and 1.3 — and at 320 the row
TITLE `Pocket money` is cut too.

The design's CSS gives the opposite (`design/html-source/components.css:116-119`):
`.list-main { flex: 1; min-width: 0 }` and `.list-trail { flex-shrink: 0 }` —
the trail takes only its intrinsic width and the main column takes the
remainder (≈187 px here, which fits every subtitle). ORCHESTRATOR_NOTES.md item 1
asks for exactly this ("the trailing `Change ›` / `›` must take only its
intrinsic width, and the subtitle column takes the rest (Expanded)").

Suggested shape: take the trailing out of the flex distribution, e.g.
`if (tail != null) Align(alignment: Alignment.centerRight, child: tail)`
(keep `Flexible` only if it is paired with `flex: 0`, or wrap it in an
`IntrinsicWidth`). One line, no public API change, and P05/P08/P11/P12/P14/P16
rows with a trailing get the design's proportions for free.

Blocks: **yes** for copy fidelity — the three subtitles are truncated on every
width (320/390/430) at text scale 1.0, so the row cannot pass a UI check.

> **Update (stage 2b, iteration 2) — §1 is now worked around on the screen, so
> nothing is blocked.** `app/lib/features/family/presentation/widgets/
> child_profile_row.dart` transcribes the design's `.list-row` on top of the
> shared tokens (`NestList`, `NestIcon`, `NestType`, `NestSpacing`,
> `NestTileTint`, the same `Semantics(button:, onTap:)` contract) with the
> trail shrink-wrapped exactly as `components.css:119` says, so all three
> subtitles render in full at 320/390/430 × 1.0/1.3. Please still land §1 on
> `main` and let P15 delete that file — the geometry assertions
> (`child_profile_view_test.dart`, `child_profile_theme_size_test.dart`) are
> identical either way, so the swap is a no-op for the suite.

## 2. Missing assets for two list-row icons (ORCHESTRATOR_NOTES item 2)

> **Update (stage 2b, iteration 2).** §2a needs **no new asset** after all:
> `assets/icons/ic_quests.svg` is already the design's glyph — `<circle
> cx="12" cy="12" r="9"/><path d="M8.5 12.5 11 15l4.5-5.5"/>`, 24 viewBox,
> `currentColor`, stroke 2 — and P15 now passes
> `leading: (fg) => NestIcon(NestIcons.quests, color: fg)` (the builder form,
> because `ProfileRow` has no `leadingAsset`). Only an alias would be nice
> (`NestIcons.checkCircle`),
> purely for naming. §2b still stands for the illustration case, and P15
> works around it with the `leadingWidget` escape hatch this section asks for
> (`app/lib/features/family/presentation/widgets/child_profile_row.dart`
> takes a `Widget Function(Color tileForeground)` and drops
> `SvgPicture.asset(NestlingIllustrations.coin, 24)` into the same 40 px
> tile). Nothing here blocks the screen any more.

Need:

a. **Circled check** for the Quests row. The design draws
   `<circle cx="12" cy="12" r="9"/>` + `<path d="m8.5 12.5 2.5 2.5 4.5-5.5"/>`
   (`design/html-source/screens/P15-child-profile.html`), stroke 2, round caps
   and joins. `NestIcons` has `ic_circle.svg` (r 7, no check) and `ic_check.svg`
   (bare check, no circle) but no combined alias, and P15 passes the builder
   `leading: (fg) => NestIcon(NestIcons.quests, color: fg)` — `ic_quests.svg`
   is already the design's glyph, so no new asset is needed here (see the
   Update above); only a `NestIcons.checkCircle` alias would be nice.
   Please add e.g. `assets/icons/ic_check_circle.svg`:

   ```svg
   <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="m8.5 12.5 2.5 2.5 4.5-5.5"/></svg>
   ```

   and `NestIcons.checkCircle`.

b. **Coin illustration** for the Pocket money row. The design uses
   `<img src="../assets/coin.svg" width="24" height="24">` — the coloured
   `assets/illustrations/coin.svg` — while a tintable `NestIcon` path would
   draw `ic_pound_coin.svg` (a line £ in a circle) and therefore lose the
   gold coin. P15 works around it with the builder form (untinted
   illustration in the tile — see the Update above). `NestListRow.leadingAsset` only accepts a
   tintable line icon (`NestIcon`). Suggest either a `leadingWidget` escape
   hatch on `NestListRow`/`NestIconTile`, or a `NestIcons`-style constant for
   the illustration so a screen can drop `SvgPicture.asset(coin.svg, size: 24)`
   into the same 40 px tile.

   (For reference, the Kid PIN row's `ic_lock.svg` already matches the design's
   `<rect x="4" y="10" width="16" height="10" rx="3"/>` + shackle path.)

Blocks: **no** for the logic/tests. **Yes** for the copy-fidelity part of §1
until the row is fixed — see §3 below for what §1 still blocks.

## 3. `NestPip.rowSlot = 84` (review finding 7, minor)

Need: `.piprow img { width: 84px; height: 84px }` is off the 4 pt grid and
`PipAvatar(size: 84)` is currently a bare literal
(`child_profile_body.dart`, the Pip card). 84 shows up in more than one
screen's design (P15 `.piprow`, K03, K07), and the orchestrator's precedent
for off-grid values is a named token (like `NestSpacing.gap10`). Please add
e.g. `NestPip.rowSlot = 84` (or `NestSpacing.pipSlot`) and use it at the call
site. P15 uses the literal with a citing comment in the meantime.

Blocks: **no** — purely a token-hygiene request.

## 4. Cross-feature test anchor already landed (review finding 9 — record only)

`app/test/features/today/today_view_test.dart:531-546` ("kid card opens the
child profile with its childId") taps the P08 kid card, lands on
`/child-profile?childId=maya`, and asserts the deep-link query parameter plus
`find.byKey(const Key('p15-hero'))` — swapped from the removed `find.text('P15
Child profile')` placeholder title once the real P15 view landed. Correct and
minimal (the placeholder text no longer exists), no production code touched,
outside this screen's RULES §1 test set (`app/test/features/family/**`), so
it is recorded here for the orchestrator to ratify rather than reverted.

Blocks: **no**.

## 5. One-shot roster-order query (review finding 4, minor)

Need: the CHILD ORDER ruling (`createdAt`, then `rowid`) currently lives in
two places — `AppDatabase.watchChildren` (`app/lib/core/data/
app_database.dart`, the shared stream) and `FamilyRepositoryImpl.removeChild`'s
repoint query (same `orderBy`, cited in a comment). The two copies are the
only definition of roster order and can diverge (e.g. if the shared tie-break
changes, `removeChild` picks a different "next child" than the roster the
screen renders). Please add a one-shot
`AppDatabase.childrenInCreationOrder(familyId)` both call sites share. No
behaviour change today.

Blocks: **no**.

## 6. BLOCKING (not P15's) — `test/core/family_time_test.dart` is red on `main`

Need: one shared/core test fails for the whole app, on `main` as well as on
this branch, and P15 cannot legally fix it (RULES §1 — `app/test/core/**` is
shared).

```
test/core/family_time_test.dart
  seed + repository zone plumbing › kid_home completions are stamped with the family zone
  Bad state: Too many elements            (line 319, `leoRows.single`)
```

Evidence it is **not** a P15 regression: `git diff main HEAD -- app/test/core/
family_time_test.dart app/lib/core/data/seed.dart` is **empty** — both files
are byte-identical to `main`, and `git diff --name-only main...HEAD` shows this
branch touches no `lib/core/**` or `test/core/**` file at all. Every other
suite is green (P15's own `test/features/family/` is 272/272).

What changed under the test: the shared demo seed now pre-creates a `to_do`
completion row for `q-plants` in the "Still to do" block
(`lib/core/data/seed.dart:392`, `['q-plants', 'leo', '10']`), which this test
predates (its file was last touched by `eed280d`). The test then calls
`KidHomeRepositoryImpl.completeQuest('leo', 'q-plants')` and asserts
`leoRows.single`. `completeQuest` flips an existing in-period `to_do`/`not_yet`
row in place but **inserts a fresh row** when `inPeriod` is empty
(`kid_home_repository_impl.dart:169-201`); after `Seed.movedToDubai` the
seeded row no longer satisfies `countsForCurrentPeriod(...)` under
`Asia/Dubai`, so the insert branch runs and `q-plants` ends up with two rows —
`Bad state: Too many elements` is that second row. The first leg (`q-reading`,
London) still flips in place and passes, which is why only the Dubai leg is red.

### VERIFIED root cause (probed directly, not reasoned)

A throwaway probe replicating the test's exact sequence against the demo seed
printed:

```
q-plants repeatRule = daily
seeded rows  = 1  status=[to_do]        at=2026-10-03T07:00:00Z  tz=Europe/London
leg1 q-reading (London)      rows = 1   tz=[Europe/London]
leg2 q-plants  (after move)  rows = 2   -> .single THROWS
   [ to_do      Europe/London 2026-10-03T07:00:00Z,
     done_pending Asia/Dubai  2026-10-03T23:59:54Z ]
```

So: the seed's `q-plants` row is stamped `Europe/London` at 07:00Z on the 3rd.
Once `Seed.movedToDubai` flips the family zone to `Asia/Dubai` (UTC+4) and the
real wall clock is past ~20:00Z, "today in Dubai" is already the **4th** while
the seeded row is the **3rd**, so `countsForCurrentPeriod('daily', …)` is false,
`inPeriod` is empty, and `completeQuest` takes its **insert** branch instead of
flipping in place. `q-plants` therefore has two rows and `.single` throws.

**This makes the test wall-clock dependent (flaky, not deterministically
broken).** It passes when the suite runs early enough in the UTC day that Dubai
has not yet crossed midnight, and fails in the evening. Do not "fix" it by
re-running and observing green, and do not loosen the zone expectation — the
stamping behaviour under test is *correct*: the newly written row really is
stamped `Asia/Dubai`, which is exactly what the test wants to prove.

### Ready-to-apply fix (verified on both legs)

Assert on the row the call itself produced — the newest — instead of assuming
uniqueness. Probed against the same sequence, this returns `Asia/Dubai` for
leg 2 and `Europe/London` for leg 1, i.e. both existing expectations still hold:

```diff
-      final rows = await (db.select(
-        db.questCompletions,
-      )..where((c) => c.questId.equals('q-reading'))).get();
-      expect(rows.single.createdAtTz, london);
+      final rows = await (db.select(db.questCompletions)
+            ..where((c) => c.questId.equals('q-reading'))
+            ..orderBy([(c) => OrderingTerm(
+              expression: c.createdAt, mode: OrderingMode.desc)]))
+          .get();
+      expect(rows.first.createdAtTz, london);
       await Seed.movedToDubai(db);
       await repo.completeQuest('leo', 'q-plants');
-      final leoRows = await (db.select(
-        db.questCompletions,
-      )..where((c) => c.questId.equals('q-plants'))).get();
-      expect(leoRows.single.createdAtTz, dubai);
+      final leoRows = await (db.select(db.questCompletions)
+            ..where((c) => c.questId.equals('q-plants'))
+            ..orderBy([(c) => OrderingTerm(
+              expression: c.createdAt, mode: OrderingMode.desc)]))
+          .get();
+      expect(leoRows.first.createdAtTz, dubai);
```

(`OrderingTerm`/`OrderingMode` need `package:drift/drift.dart`.)

Worth considering alongside it, as a shared change rather than a test edit:
`KidHomeRepositoryImpl.completeQuest` hardcodes `DateTime.now().toUtc()`
internally, so no test can pin the instant it stamps. The repo already has the
injectable-`clock` shape (`FamilyRepositoryImpl`, P15-BUG-8); giving
`completeQuest` the same seam would make this whole class of test deterministic.
That is optional — the diff above is enough to unblock every loop.

Blocks: **yes** — the full-suite gate for every screen loop, P15 included.
The P15 loop must not attempt this fix; it needs the shared edit on `main`.
