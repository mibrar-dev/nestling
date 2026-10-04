# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 5)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it added no
tests (the iteration-5 build had already unskipped every proof) and rewrote
this report. No simulator was booted, installed on, screenshotted or driven.

Tree tested: iteration-5 checkpoint `d5a05fa` (`main` merged at `0a4ac23`,
shared batch 6 in-tree) plus the concurrent test stage's iteration-5 pass,
which pinned one new minor (P16-T04) during this run.

## Result

**No open major bugs; one open minor, found by the test stage.**
Everything from iterations 1–4 (B01–B11, T01–T03) is fixed with live proofs,
the 09:22 mandate (un-fork, email from the DB, B09) is done, and this
iteration's adversarial re-attack of the shared-component consumption found
no new defects. Verdict: **PASS**.

| id | severity | status | proof |
|---|---|---|---|
| P16-T04 | minor | **open (new, test stage)** | `settings_a11y_test.dart` `[P16-T04] the initial trims a leading space and falls back to "?" for a whitespace-only name` (skipped; fails under `--run-skipped`) |
| P16-B09 | minor | fixed iter-5 | `[P16-B09] …` unskipped, green |
| P16-B10/B11 | major/minor | fixed iter-4, no regression | live |
| P16-T01/T02/T03, B01–B08 | — | fixed, no regression | live |
| P16-T02 | major | fixed iter-3 | live |

P16 now has **one** skipped test (T04, above); my own file has **zero**.

## P16-T04 · minor · avatar initials do not trim

`settings_view.dart:418-420` (member) and `:440-442` (child) treat a
whitespace-only nickname as non-empty, so `' Maya'` renders a **space** as
its avatar initial and `'   '` renders a blank avatar instead of `'?'`. The
new shared `nestAvatarInitial` (on `main`) trims and supplies the `'?'`
fallback; the helper is absent from this worktree, but the trim itself is a
local one-liner.

**Repro/proof:** set Leo's nickname to `' Maya'` / `'   '`; the Leo row's
`NestAvatar.initial` is a space. Proof:
`settings_a11y_test.dart` `[P16-T04] …` (`skip: true`;
`flutter test test/features/settings/settings_a11y_test.dart --run-skipped`
fails as designed).

**Suggested fix:** trim before both the empty check and the first grapheme
(`final t = name.trim(); initial = t.isEmpty ? '?' : t.characters.first.toUpperCase();`),
or swap in `nestAvatarInitial(name)` once `main` is merged (the integrator's
two one-liners). Not a crash — `.characters.first` is already grapheme-safe;
an emoji nickname renders correctly (verified).

## Iteration-5 changes, independently verified

**The un-fork is metric-preserving** (checkpoint `d5a05fa`; probes on the
real app):

| check | measured |
|---|---|
| `_P16Sect`/subcard/`SettingsRow` refs gone; shared components used | `NestSectionLabel` ×7, `NestCard(radius: 16, padding: 14×16)`, switch/link/picker rows plain `NestListRow` |
| switch track vs row right content edge (B11) | gap **0.0** at 390 and 320; rows **56** |
| section label height | 16.0 @1.0, 21.0 @1.3 (13/16 shared) — no clipping |
| subcard | `NestCard.radius=16.0`, padding `EdgeInsets(16, 14, 16, 14)`; inner `Material` restored (ripple fix) |
| 320×844 @1.3 dark | no overflow, gap 0, row 56 |
| picker at 320×568 @1.3 (B03) | still scrolls; proof green |

**Shared-row hit slop is correct** (`NestListRow._TrailingSlop` +
`_RowSlopForwarder`): centre, ±5 px vertical and ±4 px horizontal taps flip
the switch; a tap over the title (80 px left of the track) and taps 15 px
above/below do **not** — no false toggles from the padding retry.

**DATA OVER MOCKS:** Sarah's subtitle reads `members.email`; updating the DB
row updates the screen live; `NULL` email falls back to `Owner` (owner) or
`Invited · awaiting reply` (invited co-parent) — no invented address.

**P16-B09:** with a reader returning the link `Asia/Calcutta`, the picker
leads with the canonical `Asia/Kolkata · Current location` (batch 6's link
resolution). Proof green.

**Emoji nickname:** `'🐻 Bo'` renders its row and avatar without exception.

**New rules:** every run used `--timeout 120s` (foreground, all under
10 min); no id is minted on this screen (`newId` N/A); no simulator touched.

## Open shared/carried items (not screen bugs)

1. `nestAvatarInitial` swap (T04's clean form) waits on the next `main`
   merge — the helper is absent from this worktree.
2. `SettingsRow` still renders five rows (avatar leading + danger title) —
   `SHARED_REQUEST.md` §6; `.linkrow` 52 px — §7.
3. `P16TransientGuard`'s process-wide static lifetime — needs a shared
   variant (review 6).
4. Legacy `SettingsItem`/`watchItems()`/`getItems()` stay until the shared
   `repositories_test` settings group stops calling them.

## Gates (snapshot, `app/`, `--timeout 120s`)

```
$ dart format .                     # 553 files, 0 changed
$ flutter analyze                   # No issues found!
$ flutter test --timeout 120s test/features/settings/p16_bugs_test.dart
                                    # +24: all pass, 0 skips
$ flutter test --timeout 120s test/features/settings
                                    # +141 ~1 (the one skip is P16-T04)
$ flutter test --timeout 120s       # +3278 ~3: all non-skipped green;
                                    # skips = P16-T04 + K01's + P12's
```

VERDICT: PASS
