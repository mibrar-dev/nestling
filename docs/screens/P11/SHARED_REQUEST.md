# Shared request — P11 quote rows have no data source

Need: the P11 design's `.qn` quote lines (“I stacked everything neatly!”
etc.) have no backing column — `quest_completions` carries no child
message/note (only id/questId/childId/familyId/status/coins/createdAt(+Tz)/
decidedAt(+Tz)). Cards render without the quote row. If the owners want the
quotes, add `note TEXT DEFAULT ''` to `quest_completions` (+ seed values)
and P11 will render it.

Files: `app/lib/core/data/app_database.dart`, `app/lib/core/data/seed.dart`

Blocks: no.

---

# Shared request — P11 stale placeholder-title probes in `test/features/today/**`

Need: landing the real P11 view retired the foundation placeholder's
`AppBar('P11 Approvals')`, which two P08-owned tests used as an anchor to
locate the pushed `/approvals` page:
`p08_bugs_test.dart` `[P08-B07] system back from approvals returns to Today`
and `today_view_test.dart` `Review opens approvals`. Both failed on
`screen/P11` (`Found 0 widgets with text "P11 Approvals"`) — this is P11
deleting the placeholder, not a P11 defect. Fixed with the swap already
prescribed by `_shared/router_push_test_fix_REPORT.md` §"Optional, not
blocking": anchor on the shared `pushedPath(tester)` helper (route path,
never a placeholder view title) instead of `find.text`. Both files already
import `../../test_scope.dart`, so no new import. The now-unused local
`currentUri` helper in `p08_bugs_test.dart` was deleted with its last call
site (`_currentUri` in `today_view_test.dart` stays — 7 other scenarios
still use it).

NOTE for the orchestrator / the P08 loop: these two files belong to P08
(RULES.md §1), so P11 applied the 4-line swap in its stage-2 integration to
keep the full suite green. The identical change should land on `main` (or be
accepted from `screen/P11`) so `screen/P08` does not re-break the same two
tests. Merge order/conflict is a process item, not a finding.

Files: `app/test/features/today/p08_bugs_test.dart`,
`app/test/features/today/today_view_test.dart`

Blocks: no — applied locally on `screen/P11` (stage 2); needs orchestrator
confirmation so `main` carries it.

---

# Shared request — `NestBottomCta` sits ~8 px low vs the P11 design

Need: `ORCHESTRATOR_NOTES.md` (15:31) item 3 — match the P11 "Approve all"
button to the design. The cause is the shared component
(`app/lib/core/design_system/components/nest_bottom_cta.dart`): SafeArea +
`EdgeInsets.symmetric(vertical: 16)`, so the button bottom is
`safeArea.bottom + 16` from the physical edge. This is a design-system change
(RULES §1 — screens cannot touch `core/`), and it shifts every
`NestBottomCta` user, so it needs an orchestrator ruling.

Measured numbers (all logical px, 390×844):

| | panel top | button (x, y, w×h) | button centre y | surface to edge |
|---|---|---|---|---|
| design PNG | ≈718 | 20–370, 734–786, 350×52 | 760 | design: to 810 + paper home strip; OWNER rule replaces the strip with surface |
| app (simulator, 34 px home inset) | ≈726 | 21–369, 742–793, 349×52 | ≈768 (+8) | surface to 844 ✓ |
| app (widget test, zero inset) | 760 | 20–370, 776–828 | 802 | surface to 844 ✓ |

Requested behaviour (per the note): button top 16 px under the panel top and
the panel surface still runs to the physical edge — i.e. at the simulator's
34 px home inset the button is 734–786 (centre 760), leaving 58 px of surface
below it (34 home + 24). Concretely: keep the top pad 16 and use a bottom pad
of `safeArea.bottom + 24` instead of `safeArea.bottom + 16` (at zero inset the
button then sits 24 px above the edge: 768–820).

Files: `app/lib/core/design_system/components/nest_bottom_cta.dart` (shared);
P11's `app/test/features/approvals/approvals_view_geometry_test.dart`
currently pins the old zero-inset position (`screen.bottom - button.bottom ==
16`, button 776–828) and must be updated in the same change or the deviation
stays green.

Blocks: no — P11 ships; the −8 px UI delta stays until the shared change
lands.
