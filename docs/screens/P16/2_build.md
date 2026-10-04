# P16 Settings — Stage 2 INTEGRATE (iteration 5)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS — analyze clean, full suite green, no integration breakage, and
I changed no product code and no test.**

This is the iteration where the screen's shared-request arc closed. Shared batch
6 landed on this branch and made every previously-blocked item buildable, so 2b
could un-fork all three components, make DATA-OVER-MOCKS real, and un-skip the
last two proofs. **P16 now has no skip-marked test at all.**

## Gates (this worktree, `app/`, `--timeout 120s` per the new rule)

```
$ dart format .
Formatted 553 files (0 changed) in 1.63 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.2s)

$ flutter test --timeout 120s
02:07 +3277 ~2: All tests passed!

$ flutter test --timeout 120s test/features/settings --run-skipped
00:14 +140: All tests passed!
```

Zero failures. The last line is the headline: **`--run-skipped` selects no
test** — the settings feature is +140 passed, 0 skipped (iteration 4 closed at
+137 with 2 skips). The `~2` in the full run are **not** P16's: `k01_bugs_test.dart:566`
(another screen) and `p12_bugs_test.dart:321` (pre-existing).

## Summary of the two halves

The loop merged **shared batch 6** (`a05f346`, via `0a4ac23`) before this build.
Its five items are exactly the shared asks P16 had filed across iterations 2-4,
so this build is mostly consumption:

| batch 6 item | unblocked |
|---|---|
| `NestListRow` `_TrailingSlop` + `_RowSlopForwarder` | T02 / T03 without local wrappers |
| section label 13/16 | `_P16Sect` revert |
| `members.email` (schema v7, nullable) + seeded | DATA-OVER-MOCKS owner row |
| IANA backward links resolved | P16-B09 |

**2a — logic: no changes.** Verified, not trusted: no touched path under
`settings/domain`, `settings/data`, `settings/presentation/bloc` or
`settings_di.dart` in its own diff. It triaged all seven FIXES_4 items and
correctly found no logic hook for any. It also re-verified that the legacy
`SettingsItem` / `watchItems()` / `getItems()` trio is **not** safely removable —
the shared `test/core/data/repositories_test.dart` settings group still calls
`repo.watchItems()` — so removing it would break a file outside the feature.
Same conclusion as iteration 2, now with the caller named.

**2b — UI: the un-fork, done properly.**

1. **All three forks are gone.** `_P16Sect` → `NestSectionLabel` on all 7
   labels; the local subcard `Container` → `NestCard(radius: NestRadii.m,
   padding: …)`; the switch rows and picker rows → plain `NestListRow`, with
   every `SizedBox` wrapper deleted. Because the shared components now expose the
   metrics, the reverts are **metric-preserving** (the probe measured 16 and the
   shared label is 16; `.subcard` keeps 16 px / 14×16), and using `NestCard`
   brings back its inner `Material` — which closes `FIXES_2.md` observation 2,
   the ripple that painted behind the card.
2. **DATA-OVER-MOCKS (08:12 item 2) — done.** `_MemberRow` reads
   `SettingsMemberEntry.email`, mapped from `members.email`; NULL falls back to
   the role-derived `Owner` or the invite status, so no address is invented.
   `sarah@example.co.uk` is gone from the view.
3. **Both remaining proofs un-skipped and green** — T03 (taps 4 px left/right of
   the track flip it) and B09 (now uses the real link `Asia/Calcutta` →
   `Asia/Kolkata`).
4. **Token literals replaced** — `SizedBox(height: 2)` → `NestSpacing.gap2`,
   `fromLTRB(14,12,14,12)` → `gap14`/`s3`, and the 14/20 paragraph style →
   `NestType.chipLabel` (which *is* Inter 14/20). Stale "open bug" comments on
   four now-live proofs rewritten to match the code.
5. `SettingsRow` survives, narrowed: its `padding` escape hatch (which existed
   only for the deleted wrappers) is gone, leaving the shared row's exact metrics
   for the five rows the shared row still cannot express.

## The one cross-chunk change — reviewed and accepted

2b touched two files in the logic chunk's territory and **flagged it explicitly**
under "CONTRACT CHANGE (outside my chunk — please review)". I reviewed it, and it
is the right call and the minimal form:

- `settings_member_entry.dart` — `final String? email;` as an **optional named
  parameter defaulting to null**, added to `props`. Additive, so every existing
  construction site keeps compiling, including other features' test fakes.
- `settings_repository_impl.dart` — one mapping line, `email: row.email`.

Total diff: 2 files, 3 hunks, no event/state/DI shape change. The trigger was
that 2a's "CONTRACT CHANGES: None" was written *before* batch 6 landed, so the
logic builder never saw the field the email mandate requires; leaving it would
have meant shipping a red suite. This is the disclosure pattern I want from a
builder crossing a chunk boundary, and it is why the merge will be a no-op if a
later logic pass writes the same two lines.

## Correction to my own iteration-4 finding

I reported that "the seed holds that parent email" was **false**, and filed
`SHARED_REQUEST.md` §4 asking the orchestrator to choose between a role-derived
subtitle and a schema change. Batch 6 item 4 shipped the schema change, and I
have now verified the premise is true in this tree: `members.email` exists
(`app_database.g.dart:585`) and `Seed` writes `sarah@example.co.uk`
(`seed.dart:83,127,180`).

So the ruling was not mistaken — it described the destination, and I measured the
tree it had been written against. I added a dated RESOLVED note to §4 so the
stale "unsatisfiable as written" framing cannot mislead the next reader, and
kept the measurement as the record of how the gap was found.

## The one mandatory rule that could not be applied in this tree

**AVATAR INITIALS — "use `nestAvatarInitial(name)` … never `name[0]`"** is a new
rule this iteration, and neither builder could act on it: the helper lives on
`main` at `core/design_system/components/nest_avatar_initial.dart` (already used
by approvals, family and kid_home) but is **absent from this worktree** — the
branch is 25 commits behind `main` and the last merge predates the file.
Importing it here would fail `flutter analyze`.

State of P16's two call sites, for whoever picks this up after the merge:

- `settings_view.dart:420` — `member.name.characters.first.toUpperCase()`
- `settings_view.dart:442` — `child.nickname.characters.first.toUpperCase()`

Neither violates the rule's actual prohibition (`.characters.first` is
grapheme-safe; neither is `name[0]`), but both should become `nestAvatarInitial(…)`
so the initial rule lives in one place. Two one-line swaps.

Also new this iteration and satisfied: **TEST TIMEOUTS** — every run above used
`flutter test --timeout 120s`, all foreground and none over 10 minutes.
**IDS** (`newId(prefix)`) — no id is minted on this screen, so nothing to check.
**SIMULATORS** — the permitted udid changed this round; no simulator was booted,
installed on, screenshotted or driven by me.

## Independent verification

| claim | how I checked | result |
|---|---|---|
| nothing left to un-skip | `flutter test test/features/settings --run-skipped` → `+140`, no failures | confirmed |
| 2a changed no logic file | its diff filtered for domain/data/bloc/DI paths | empty — confirmed |
| three forks really gone | `_P16Sect` 0 refs, `p16_subcard` 0 refs, `NestSectionLabel` ×7, `NestCard` ×2 | confirmed |
| `SettingsRow` count reconciles | 3 call sites render 5 rows: `_MemberRow` (Sarah, James), `_ChildRow` (Maya, Leo), danger (Delete) — matches 2b's "five rows" | confirmed |
| un-fork used shared capability, not a new local hack | shared `NestCard` has `final double? radius` (`nest_card.dart:29`) and P16 passes `radius: NestRadii.m`; the shared doc comment even cites P16's `.subcard` | confirmed |
| email really comes from the DB | schema `members.email` (line 585) + `Seed` writes the address; the view reads `SettingsMemberEntry.email` | confirmed |
| ripple defect genuinely fixed | using `NestCard` restores its inner `Material` (line 71), which the local `Container` lacked | confirmed |
| shared requests are real, not claimed | §1-§5 exist and are marked LANDED (batch 6); §6/§7 exist and are OPEN | confirmed |
| CLOCK rule | `DateTime.now()` → 0 hits across `lib/features/settings/` | confirmed |
| nothing outside the allowed paths | all changes sit under `lib/features/settings/**`, `test/features/settings/**`, `docs/screens/P16/**` | confirmed |
| no dispatch gap this time | brief 11:38 post-dates `ORCHESTRATOR_NOTES.md` 09:20, so unlike iteration 4 the mandate was visible | confirmed |

## LEFT for the next iteration

1. **`nestAvatarInitial` swap** at `settings_view.dart:420` and `:442`, once
   `main` is merged (2 one-liners). The only unmet rule in this tree.
2. **`SettingsRow` still exists for five rows** — needs `SHARED_REQUEST` §6
   (`NestListRow.leading` widget + danger title colour). One shared change, then
   the widget and its call sites delete.
3. **52 px `.linkrow`** — `SHARED_REQUEST` §7, cosmetic.
4. **Stage 5 must re-measure.** `ui=PASS` was earned on iteration 4's tree.
   Three components changed underneath, and 2b's claim that the reverts are
   metric-preserving is an argument, not a measurement — the ±2 px verdict has to
   be re-earned, and `cmp_*_1.png` regenerated (the current one is 3.58 % drift).
5. **`P16TransientGuard`'s process-wide static lifetime** (review 6) — needs a
   shared variant, not a screen fix.
6. Legacy `SettingsItem` / `watchItems()` / `getItems()` stay until the shared
   `repositories_test` stops calling them (2a, twice).

## Code changed by this stage

**None** — no `lib/**` change, no test edit, no lint weakened, no `// ignore:`,
no test skipped, `analysis_options.yaml` untouched, no shared file touched.

Docs only: added a dated RESOLVED note to `SHARED_REQUEST.md` §4 correcting my
own iteration-4 framing now that batch 6 has made the email premise true.

---

# Appendix — iterations 1-4 in one line each

- **Iteration 1:** built from `1_plan.md`; fixed the one integration breakage
  (`today_view_test.dart` anchoring on the deleted placeholder `P16 Settings` →
  `pushedPath`) and proved the combination green on `main` (`+2741 ~1`).
- **Iteration 2:** integrated clean; proved the remaining skip was honest rather
  than hiding a green test; filed `SHARED_REQUEST.md` §1-§4 for four "LEFT"
  items with no carrier — the file that batch 6 would later answer.
- **Iteration 3:** T02 + B08 closed with live proofs; flagged the 06:58 un-fork
  mandate as unactioned and argued shared-fix-first.
- **Iteration 4:** B11 + B10 closed with live proofs; measured that the email
  premise was false in that tree; found that a mandatory mandate had been
  appended two minutes *after* the briefs went out, so three items were lost to
  dispatch order.

VERDICT: PASS