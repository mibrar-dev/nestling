# Shared request — P11 quote rows have no data source — RESOLVED (schema v6)

> Update (iteration 2): landed on main as `shared/completion_note` —
> `quest_completions.kid_note TEXT NULL` (schema v6) + seed notes for the two
> pending rows (dishwasher/table-NULL/bed). P11's `Approval` entity/model/
> repository now carry `kidNote` (NULL = no quote line). Rendering the quote
> line is UI-builder work (their iteration 2). Original request kept below
> for history.

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

> Update (iteration 2, UI builder): **worked around locally; the shared change
> is still wanted.** Screens cannot edit `core/` (RULES §1), so P11 now uses a
> P11-private `ApprovalsBottomCta`
> (`app/lib/features/approvals/presentation/widgets/approvals_bottom_cta.dart`)
> — same surface fill, same 1 px top `line`, same 20 px gutters, same 16 px
> above the pill, but `bottom: MediaQuery.padding.bottom + 24`. Measured after
> the change: at the design's 34 px home inset the panel top is **717** (the
> `--line` pixel sits exactly where the design draws it) and the pill is
> **734–786, centre 760** — the design's rects, with the surface still running
> to the physical edge (OWNER rule); at the zero-inset test surface the pill is
> 768–820. Both are pinned in `approvals_view_geometry_test.dart`. When the
> shared component adopts the 24 px pad, P11 can go back to `NestBottomCta`
> (one import, one class name).

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
| design PNG | 717 (1 px `--line`, surface below) | 20–370, 734–786, 350×52 | 760 | design: to 810 + paper home strip; OWNER rule replaces the strip with surface |
| app before (simulator, 34 px home inset) | ≈726 | 21–369, 742–793, 349×52 | ≈768 (+8) | surface to 844 ✓ |
| app before (widget test, zero inset) | 760 | 20–370, 776–828 | 802 | surface to 844 ✓ |
| app now (simulator, 34 px inset) | **717** | **20–370, 734–786** | **760** | surface to 844 ✓ |
| app now (widget test, zero inset) | 752 | 20–370, 768–820 | 794 | surface to 844 ✓ |

Requested behaviour (per the note): button top 16 px under the panel top and
the panel surface still runs to the physical edge — i.e. at the simulator's
34 px home inset the button is 734–786 (centre 760), leaving 58 px of surface
below it (34 home + 24). Concretely: keep the top pad 16 and use a bottom pad
of `safeArea.bottom + 24` instead of `safeArea.bottom + 16` (at zero inset the
button then sits 24 px above the edge: 768–820).

Note for whoever changes the shared component: `SafeArea` resolves
`max(inset, minimum)`, so `minimum: EdgeInsets.only(bottom: 24)` does NOT add
the 24 on top of the inset — read `MediaQuery.paddingOf(context).bottom`
directly, as `ApprovalsBottomCta` does.

Files: `app/lib/core/design_system/components/nest_bottom_cta.dart` (shared).

Blocks: no — P11 ships on the local panel above; the shared change only
unblocks every other `NestBottomCta` screen.
