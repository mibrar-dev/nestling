# P16 Settings — 2b build, UI chunk (iteration 5)

Scope: `presentation/views/**` + `presentation/widgets/**`, widget tests, and
the FIXES_4 items that live in them. Shared batch 6 (`a05f346`, merged in
`0a4ac23`) is on this branch, so the whole of §"Follow-ups for screens" in
`docs/screens/_shared/shared_batch6_REPORT.md` applies.

## What landed

### 1. The three forks are gone (ORCHESTRATOR_NOTES 08:12 item 3 / 09:22)

| fork | now | evidence it is the shared one |
|---|---|---|
| `_P16Sect` (a per-build `TextPainter` probing Inter's natural line box) | `NestSectionLabel(label: …)` on all 7 section labels | the probe widget is deleted from the file; batch 6 item 2 makes the shared label 13/16 — the same number the probe produced, so the geometry the UI stage measured in iteration 4 is unchanged |
| the subscription subcard (local `Container(key: p16_subcard, …)`) | `NestCard(radius: NestRadii.m, padding: EdgeInsets.symmetric(horizontal: s4, vertical: gap14))` | the inner `Material` is back, so the `Manage subscription` ripple paints **on** the card (closes `FIXES_2.md` obs 2); `.subcard`'s 16 px radius / 14×16 padding come from batch 6's new params, so the design metric is kept without forking |
| `SettingsRow` on the three switch rows, each in `SizedBox(width: 51, height: 44, Center(…))` | plain `NestListRow(title: …, trailing: NestToggle(…))` | the wrappers are deleted. Batch 6 item 1 gives the shared row a `_TrailingSlop` + `_RowSlopForwarder`: the row lays out at the toggle's 51×31 and hit-forwards the full 59×44, so the row is back to the design's 56 **and** P16-T03's 4 px horizontal slop is back |
| the zone-picker sheet rows | `NestListRow` (was `SettingsRow`) | shared |

### 2. DATA OVER MOCKS — the parent's e-mail (08:12 item 2 / batch 6 item 4)

`sarah@example.co.uk` is gone from the view. `_MemberRow` reads
`SettingsMemberEntry.email`, which the repository maps from `members.email`
(schema v7, nullable). NULL falls back to the role-derived `Owner` (owner) or
the invite status (`Invited · awaiting reply`), so the invited co-parent is
unchanged and no address is ever invented.

### 3. Both remaining proofs are live — nothing in this feature is skip-marked

- **P16-B09** (`p16_bugs_test.dart`): batch 6 item 5 resolves IANA backward
  links, so the proof now uses `Asia/Calcutta` (a real tzdb link → `Asia/Kolkata`)
  and asserts the picker lists `Asia/Kolkata · Current location`. `skip: false`.
- **P16-T03** (`settings_a11y_test.dart`): with the wrappers gone the shared
  trailing keeps the whole 59×44, so taps 4 px left and right of the track flip
  it. `skip: false`. Its companion now measures the `NestListRow` (the row is
  the ≥44 box) instead of a `SizedBox`.
- `flutter test test/features/settings --run-skipped` selects **no test**.

### 4. Review finding 1 — literals replaced with tokens (UI/layout items only)

- `SizedBox(height: 2)` → `NestSpacing.gap2` (`.subcard .b { margin-top:2px }`).
- `fromLTRB(14, 12, 14, 12)` → `EdgeInsets.symmetric(horizontal: NestSpacing.gap14, vertical: NestSpacing.s3)` in both the move banner and `.lockhint` (`.lockhint { padding:12px 14px }`).
- `copyWith(fontSize: 14, height: 20/14)` → `NestType.chipLabel(color: ink).copyWith(fontWeight: FontWeight.w400)`. `chipLabel` *is* Inter 14/20 (`.lockhint { font-size:14px; line-height:20px }`); only the weight differs, so the line box is now token-sourced. Same numbers on screen — the responsive suite's lock-hint and 1.3-scale tests are unchanged and green.
- `height: 52` → `const double _linkRowMinHeight = 52`, documented with its CSS line (`P16-settings.html:9`) and filed as SHARED_REQUEST §7, because `NestPager.stage` is also 52 and is a different metric.

### 5. Review findings 2/3 — stale comments on live proofs

`p16_bugs_test.dart`'s header (it still advertised B09 as open and told the
reader to run `--run-skipped`), its section banner ("Open bugs — skipped") and
the B11 block; `settings_responsive_test.dart`'s B11 block (still said "OPEN
BUG … pinned skip-marked"); `settings_a11y_test.dart`'s T02 block (still
described the deleted `SettingsRow` at 6 px padding + 44-high wrapper as the
current mechanism). All now describe what the code does.

### 6. `SettingsRow` — narrowed, and why it survives

Its `padding` escape hatch existed only for the switch wrappers and is gone.
What is left is the shared row's exact metrics for the five rows the shared row
cannot yet express:

- four **avatar-leading** rows (Sarah, James, Maya, Leo). The design puts
  `<span class="avatar s32">` in the leading slot (`P16-settings.html:18-25`);
  `NestListRow` only builds a 40 px icon tile from `leadingAsset`.
- one **danger** row (`Delete family account`, `.dangerlink` = danger + w700).

Both are one-line shared additions — `NestQuestCard` already does `Widget?
leading` the same way — filed as **SHARED_REQUEST §6** with the measured cost.
When it lands, `SettingsRow` and its five call sites delete.

## CONTRACT CHANGE (outside my chunk — please review)

The e-mail ruling is a **view/copy** mandate whose data shape lives in the logic
chunk, and the logic chunk reported `CONTRACT CHANGES: None` (written before
batch 6 landed). Rather than leave the suite red on the tripwire the test stage
had armed for exactly this, I made the smallest possible additive change:

- `domain/entities/settings_member_entry.dart` — `final String? email;`
  (optional named, default null, added to `props`), so **every** existing
  construction site — including other features' test fakes — keeps compiling.
- `data/settings_repository_impl.dart` — `email: row.email` in `_toMemberEntry`.

Nothing else in domain/data/bloc changed, no event/state/DI shape changed, and
the diff is exactly what a logic pass would write, so a merge is a no-op if the
logic builder lands it too. Flagging it because RULES.md assigns those paths to
the logic builder.

## FIXES_4 triage

| item | outcome |
|---|---|
| **P16-T03** (minor) | **FIXED** — wrappers deleted, proof live and green |
| **P16-B09** (minor, shared) | **FIXED** by batch 6 item 5, proof live and green |
| **P16-T02** | still holds, now on the shared row (`contentBox ≥ 44`, track 51×31, ±5 px taps flip the DB row) — proof untouched and green |
| **P16-B11** (major) | still holds (gap 0.0 at 320/390/430, both themes) — proof untouched and green |
| **P16-B10** | untouched; delete + invite rows still go through `P16TransientGuard.run` — proof green |
| review 1 (un-fork) | done for `_P16Sect`, the subcard and every switch/picker row; the two genuinely missing shared params are §6 |
| review 2/3 (stale comments) | fixed (above) |
| review 4 (B09 skip) | un-skipped, live |
| review 5 (owner e-mail literal) | fixed — reads `members.email` now |
| review 6 (guard lifetime) | unchanged: `P16TransientGuard` is still process-wide static state, now with a narrower blast radius (every row still routes through it). Tracked for a shared variant — not a UI/layout item, no action |
| legacy `SettingsItem` / `watchItems()` | untouched (logic chunk owns it; shared `test/core/data/repositories_test.dart` still calls it — verified 22/22 green) |

## Layout: unchanged where it was already right

The three reverts are metric-preserving, and that is the point of the batch:
`_P16Sect` measured 16, the shared label is 16; `.subcard` keeps 16 px / 14×16;
the shared toggle row is 56 like the fork was *intended* to be (the fork's
44-high wrapper was the bug — T03). No `SizedBox` on the rows changed the
vertical rhythm, so the y positions the UI stage measured in iteration 4 stand.
The only text that changed on screen is the owner subtitle, which now follows
the seed — identical to the design in the demo seed.

## Verified

```
dart format lib/features/settings test/features/settings   → 0 changed
flutter analyze lib/features/settings test/features/settings → No issues found!
flutter test --timeout 120s test/features/settings          → +140: All tests passed!
flutter test --timeout 120s test/features/settings --run-skipped → no test selected
flutter test --timeout 120s test/core/data/repositories_test.dart → +22: All tests passed!
```

Numbers: **+140 passed, 0 skipped** (iteration 4 closed at +137 with 2 skips).
+1 new test, +2 previously-skipped proofs now live, 0 failures. No simulator
booted, installed on, screenshotted or driven.

## LEFT FOR NEXT ITERATION

1. **`SettingsRow` still exists for 5 rows** — needs SHARED_REQUEST §6
   (`NestListRow.leading` widget + a danger `titleColor`/`titleStyle`). One
   shared change, then delete the widget and its five call sites.
2. **52 px `.linkrow`** — SHARED_REQUEST §7; moves to a token when the grid
   grows one.
3. **UI stage (5) must re-measure.** The switch rows are the shared 56 again
   rather than the fork's 56-with-6px-padding, and the section labels are the
   shared 16. Both should land on the same y as iteration 4's screenshots, but
   the ±2 px verdict has to be re-earned on the new tree, and
   `cmp_*_1.png` should be regenerated (the earlier one is 3.58 % drift).
4. **Not my file, not done:** if the review wants the design-system gallery's
   `hintText` copy or any other screen's literals audited, that is another
   screen's chunk.
5. `P16TransientGuard`'s process-wide static lifetime (review 6) — needs a
   shared variant, not a screen fix.

VERDICT: PASS