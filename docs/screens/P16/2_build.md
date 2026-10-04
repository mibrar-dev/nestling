# P16 Settings — Stage 2 INTEGRATE (iteration 6)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS — analyze clean, full suite green, no integration breakage, and
I changed no product code and no test.** P16 still has **zero** skip-marked
tests for the second consecutive iteration.

This iteration the mandate was one small rule ("nothing else: the layout is
done"), both briefs post-dated the notes so there was no dispatch gap, and the
substantive work was review findings. It also surfaced **an error in my own
iteration-5 report**, which I correct below.

## Gates (this worktree, `app/`, `--timeout 120s` per the rule)

```
$ dart format .
Formatted 564 files (0 changed) in 2.77 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 9.6s)

$ flutter test --timeout 120s
03:18 +3528 ~2: All tests passed!

$ flutter test --timeout 120s test/features/settings --run-skipped
00:13 +145: All tests passed!
```

Zero failures. `--run-skipped` still selects no test in this feature. The `~2`
are `k01_bugs_test.dart:569` and `p12_bugs_test.dart:321` — neither is P16's.
All runs foreground, none over 10 minutes; no simulator booted, installed on,
screenshotted or driven.

## Correction: my iteration-5 "confirmed" row was wrong

In iteration 5 I wrote into `SHARED_REQUEST.md` §3 — and into my own
verification table as **"confirmed"** — that un-forking the subcard back to
`NestCard` closed the "ripple paints behind the card" defect, because
`NestCard` wraps its child in a `Material`. I checked that the `Material` exists
at `nest_card.dart:71`. **I did not check that P16's card takes the branch that
renders it.** It does not:

- the `Material` + `InkWell` + `Ink` construction lives only on the
  `if (tap != null)` branch (`nest_card.dart:88-98`);
- the non-tappable branch is `final plain = Container(...)` — a bare
  `Container`, no `Material` (`nest_card.dart:96-101`);
- P16's subscription card is **not** tappable as a card: the design's
  `.linkrow` is a link *inside* it, so the tap lives on an inner `InkWell` and
  `NestCard` receives `onTap: null`.

I re-verified this myself this iteration before accepting 2b's account: the
subcard's `NestCard` call site contains no `onTap`, so it takes the plain
branch. The defect therefore **survived the un-fork**, and my "confirmed" row is
retracted. 2b corrected §3 in place with a dated block and fixed the defect
screen-side by giving the link row its own ink surface — the same
`Material(color: Colors.transparent, child: InkWell(…))` shape
`NestListRow`/`SettingsRow` already use.

The lesson is narrow and worth keeping: *verifying that a component has a
capability is not verifying that this call site gets it.* Branch-dependent
constructs have to be read on the path the screen actually takes.

## Summary of the two halves

**2a — logic: one additive change, two review findings closed.**

1. `SettingsRepositoryImpl` now takes an **optional** `FamilyZoneService?
   zoneService` defaulting to a local instance, so every existing
   `SettingsRepositoryImpl(db: …)` construction still compiles. It previously
   built its own service inline (review 6); `settings_di.dart` now injects the
   DI singleton. `setFamilyTimeZone` goes through the injected service.
2. **Review 5** — `watchMembers` delegates to the shared
   `AppDatabase.watchMembers()` (batch 6) instead of feature-local raw SQL.
   Order (Sarah → James) and mapping unchanged.
3. Repository tests gained DB-driven owner/co-parent e-mail assertions and an
   explicit-service zone-write test. 40/40 in its own layer.

**2b — UI: the mandated rule plus three review findings.**

1. **P16-T04 / review 1 — shared `nestAvatarInitial` (the 12:52 mandate).**
   Both hand-rolled `name.isEmpty ? '?' : name.characters.first.toUpperCase()`
   sites now call the helper. It trims first and owns the `'?'` fallback, so
   `' Maya'` renders `M` and `'   '` renders `?` instead of a blank avatar — and
   it removes the feature's last undeclared use of `package:characters`.
2. **Review 2 (major) — the guard was swallowing switch flips.** All three
   `NestToggle.onChanged` handlers wrapped their write in
   `P16TransientGuard.run`. Notifications sits **immediately below** the zone
   picker, so the natural sequence (open picker → pick a zone → tap a switch)
   put the user's very next tap inside the 300 ms window: the switch did not
   move and gave no feedback. A switch flip cannot re-trigger itself, so the
   double-tap fall-through the guard exists for (B08/B10) can never apply to
   it — the same reasoning that already exempted the move banner's buttons.
   Three wrappers deleted; the guard stays on the rows that do open a route or
   dialog, and **§8** asks for the fence at the shared source.
3. **Review 3 — the link row's ink surface** (the correction above), fixed
   geometry-neutrally: a `Material` wrapper adds no padding and no height, so
   the subcard rects the UI stage measured are untouched.
4. **Review 4 — one hint style.** The lock hint and move banner both rendered
   `.lockhint` copy (Inter 14/20) as `NestType.chipLabel(…).copyWith(w400)` —
   the right line box from the wrong token, so a chip-label weight change would
   silently move hint text. The literal now lives once in
   `settingsHintStyle(context)`; **§9** asks for a real `NestType.hint`.
5. Stale "OPEN BUG" comments rewritten on the proofs that are now live.

## Independent verification

| claim | how I checked | result |
|---|---|---|
| T04 really uses the shared helper | `settings_view.dart:434,455` both call `nestAvatarInitial(…)`; no `.characters.first` left in the feature | confirmed |
| the guards really left the switches | 10 `P16TransientGuard.run` call sites remain on rows; **0** inside any `onChanged:` | confirmed |
| the link row really has its own ink surface | `Material(color: Colors.transparent, child: InkWell(…))` wraps the row, and the enclosing `NestCard` has no `onTap` | confirmed |
| 2b's §3 correction is right, not deference | read `nest_card.dart:88-101` myself: `Material` only on the tappable branch, `plain = Container(...)` otherwise | confirmed — my iteration-5 claim was wrong |
| T04 proof is not self-agreeing | it drives the DB via `prepare:`, pins the **Leo** row specifically, and computes the expectation by hand rather than via the helper | confirmed |
| 2a's zone service is genuinely injected | `zoneService ?? FamilyZoneService(_db)` with the DI singleton wired in `settings_di.dart`; `setFamilyTimeZone` uses `_zoneService` | confirmed |
| `watchMembers` really delegates | `return _db.watchMembers().map((rows) => rows.map(_toMemberEntry).toList());` | confirmed |
| nothing skip-marked in P16 | `flutter test test/features/settings --run-skipped` → `+145`, no test selected; the tree's 2 skips are K01's and P12's | confirmed |
| CLOCK rule | `DateTime.now()` → 0 hits across `lib/features/settings/` | confirmed |
| accessibility rule on the new ink wrapper | the `Semantics(excludeSemantics: true, …)` beside it passes `onTap:` | confirmed |
| nothing outside the allowed paths | all changes under `lib/features/settings/**`, `test/features/settings/**`, `docs/screens/P16/**` | confirmed |
| no dispatch gap this iteration | briefs 12:50, `ORCHESTRATOR_NOTES.md` 12:50 — the mandate was visible (unlike iteration 4) | confirmed |

## FIXES accounting

| item | severity | status |
|---|---|---|
| **P16-T04** hand-rolled avatar initials | minor | **DONE** (2b) — proof live; the rule the helper adds is trim + `?` fallback + first grapheme |
| review 1 avatar initials re-implemented | major | **DONE** — same change, seen from the review stage |
| review 2 guard swallows switch flips | major | **DONE** (2b) — 3 wrappers removed; §8 filed |
| review 3 "Manage subscription" paints no ripple | minor | **DONE** (2b) — §3's status line corrected |
| review 4 `.chip` label reused as hint body copy | minor | **DONE as far as a screen can** (2b) — one documented `settingsHintStyle()`; §9 filed for a real `NestType.hint` |
| review 5 `watchMembers` duplicated the shared query | minor | **DONE** (2a) |
| review 6 repository built its own `FamilyZoneService` | minor | **DONE** (2a) |
| review 7 legacy `SettingsItem` / `watchItems()` / `getItems()` | minor | **LEFT — correctly kept** (2a, third confirmation): the shared `repositories_test` settings group still calls `repo.watchItems()`, so deleting it would break a file outside the feature |
| review 8 `_linkRowMinHeight` / `SettingsRow` metrics | minor | **already §6/§7**, no new action |
| P16-B09 IANA links | minor | closed in iteration 5 by batch 6; proof live |
| 3_test obs 2 Family list announces as one node | observation | **LEFT — shared** `NestListRow`'s no-`onTap` branch; a local label breaks the tappable-node contract |
| 3_test obs 4 `.ptitle` has no `text-wrap: balance` | observation | unchanged; plain `Text` + `NestType.h1` matches the CSS as written |
| 3_test obs 5/6 (300 ms fence, dialog Cancel wrap) | observation | unchanged; fence kept deliberately, Cancel wrap is shared `NestButton` padding |

## LEFT for the next iteration

1. **Stage 5 must re-measure** and re-issue `cmp_*_6.png`. The three fixes are
   geometry-neutral by construction and the layout is otherwise untouched, but
   the ±2 px verdict has to be re-earned on the new tree. Known open deviation:
   the subcard bottom edge at **+2.0 px** — at tolerance, tracked, invisible
   side-by-side.
2. **`SettingsRow` still exists for five rows** (four avatar-leading + the
   danger row) — needs **§6** (`NestListRow.leading` widget + danger
   `titleColor`/`titleStyle`). One shared change, then delete the widget and its
   call sites. Not re-doable screen-side.
3. **`P16TransientGuard` itself** — **§8**: the modal/sheet helpers stay
   hit-testable through their exit animation. Its process-wide static lifetime
   is unchanged and is the last shared-behaviour workaround left in this
   feature.
4. **`settingsHintStyle()`** — **§9**: becomes `NestType.hint` when the scale
   grows one.
5. **`_linkRowMinHeight = 52`** — **§7**, cosmetic.
6. Legacy `SettingsItem` / `watchItems()` / `getItems()` stay until the shared
   `repositories_test` stops calling them.

Process note, not a finding: 2b reported that `dart format` (which RULES §7
requires per-directory) normalised `data/settings_repository_impl.dart` while 2a
was still writing it. Whitespace only, and the tree is format-clean now
(`564 files, 0 changed`), so it needed no action — but it is a real hazard of
two builders formatting a shared directory concurrently.

## Code changed by this stage

**None** — no `lib/**` change, no test edit, no lint weakened, no `// ignore:`,
no test skipped, `analysis_options.yaml` untouched, no shared file touched.
2b had already corrected `SHARED_REQUEST.md` §3 in place, so no docs edit was
needed from me either; this file is the record.

---

# Appendix — iterations 1-5 in one line each

- **Iteration 1:** built from `1_plan.md`; fixed the one integration breakage
  (`today_view_test.dart` anchoring on the deleted placeholder `P16 Settings` →
  `pushedPath`) and proved the combination green on `main` (`+2741 ~1`).
- **Iteration 2:** integrated clean; proved the remaining skip was honest;
  filed `SHARED_REQUEST.md` §1-§4 — the file batch 6 would later answer.
- **Iteration 3:** T02 + B08 closed with live proofs; flagged the unactioned
  06:58 un-fork mandate.
- **Iteration 4:** B11 + B10 closed; measured that the email premise was false
  *in that tree*; found a mandatory mandate appended 2 minutes after the briefs
  went out.
- **Iteration 5:** batch 6 landed — all three forks un-forked, email made
  DB-driven, B09 closed, last two proofs live, `+140 / 0 skipped`. Filed the
  `nestAvatarInitial` blocker as main-only, and got the §3 ripple reasoning
  wrong (see the correction above).

VERDICT: PASS