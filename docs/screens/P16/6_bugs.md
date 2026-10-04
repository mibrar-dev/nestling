# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 6)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it refreshed
one stale proof comment in `app/test/features/settings/p16_bugs_test.dart`
(B09) and rewrote this report. No simulator was booted, installed on,
screenshotted or driven.

Tree tested: iteration-6 checkpoint `7189047` (`main` merged at `ee5841b`;
the shared `nestAvatarInitial` is in-tree) plus the concurrent test stage's
iteration-6 edits, which were still landing during the run.

## Result

**No open bugs in the screen.** Every finding from iterations 1–5 is fixed
with a live, un-skipped proof; the iteration-6 mandate (T04 + the FIXES_5
review findings) is independently verified below; no new defect was found in
the changed code. Verdict: **PASS**.

| id | severity | status | proof |
|---|---|---|---|
| P16-T04 | minor | fixed iter-6 | `settings_a11y_test.dart` `[P16-T04] …` — live, green |
| review 2 (guard swallowed switch flips) | major | fixed iter-6 | verified by probe (below) + suite |
| review 1 (`nestAvatarInitial`) | major | fixed iter-6 | same change as T04 |
| review 3 (ripple behind the card) | minor | fixed iter-6 | verified by probe (below) |
| review 4/5/6 (hint style, `watchMembers`, DI zone service) | minor | fixed iter-6 | verified by probe/code + suite |
| P16-B01…B11, T01–T03 | — | fixed iter-1…5, no regression | all live |

P16 has **zero** skip-marked tests (second iteration running); my file has
zero.

## Iteration-6 changes, independently verified

**P16-T04 / review 1 — shared `nestAvatarInitial`.** Both call sites now use
the helper (`settings_view.dart:434,455`); no `.characters.first` and no
`package:characters` import remain in the feature. Measured on the Leo row:

| nickname | avatar initial |
|---|---|
| `' Maya'` | `M` (was a space) |
| `'   '` | `?` (was a space) |
| `''` | `?` |
| `'Maya'` | `M` |
| `'🐻 Bo'` | `🐻` (grapheme-safe) |

**Review 2 (major) — the guard no longer swallows switch flips.** The three
`NestToggle.onChanged` handlers dispatch straight to the bloc; the fence
remains on the rows that open a modal/route (10 call sites). Measured:
open the picker → pick a zone → tap the Approvals switch **100 ms later**:
`before=true after=false flipped=true`. Same after the delete dialog closes.
The B08/B10 double-tap proofs (rows) stay green, so the fall-through is still
fenced where it can actually re-fire something.

**Review 3 (minor) — the link row's own ink surface.** `Material(color:
Colors.transparent, child: InkWell(…))` wraps the manage row. Ground truth:
`Material.of(inkWell)` is **not** identical to `Material.of(planTitle)`
(the ripple no longer resolves to the Scaffold's Material behind the card),
the InkWell rect is 52 px high (647–699), and a tap in its empty lower band
still navigates to `/paywall`.

**Review 4 (minor) — one hint style.** `settingsHintStyle()` =
Inter 14/20 **w400** (measured), used by both the lock hint and the move
banner; `SHARED_REQUEST.md` §9 asks for a real `NestType.hint`.

**Review 5/6 (minor) —** `watchMembers` delegates to the shared
`AppDatabase.watchMembers()`; `SettingsRepositoryImpl` takes the injected
`FamilyZoneService` (DI singleton) instead of building its own. Both layers'
tests green.

**New rules:** AVATAR INITIALS compliant (helper used, no `name[0]`);
every run used `flutter test --timeout 120s` (foreground, all under
10 minutes); no id is minted on this screen (`newId` N/A); no simulator.

## Open shared/carried items (not screen bugs)

* `SHARED_REQUEST` §6 (`NestListRow.leading` widget + danger title) — the
  `SettingsRow` mirror survives for five rows until it lands.
* §7 `.linkrow` 52 px literal; §8 fence the modal/sheet exit at the shared
  helpers; §9 `NestType.hint`.
* Legacy `SettingsItem`/`watchItems()`/`getItems()` — the shared
  `repositories_test` settings group still calls `watchItems()`.
* Shared `NestListRow`'s no-`onTap` branch announces the Family list as one
  node; shared `NestButton` wraps "Cancel" at 320 @1.3; subcard bottom edge
  +2.0 px (within the ±2 px rule, tracked).

## Observations (concurrent stages, not findings)

1. The test stage's scratch `zz_probe_test.dart` was mid-flight at the
   snapshot: it holds 6 `document_ignores` infos and its `subcard layout`
   probe is currently red. It declares itself temporary; the settings suite
   is otherwise `+149` and the navigation test's ripple assertion passed
   after the test stage's own edit.
2. My full-suite run had one failure — `pocket_money/p13_iter2_audit_test.dart`
   — which passes in isolation (external flake/behind-`main` noise, not P16).
   The build checkpoint's full suite was `+3528 ~2` green.

## Gates (snapshot, `app/`, `--timeout 120s`)

```
$ dart format .                     # 565 files, 0 changed
$ flutter analyze                   # clean for lib + P16 files; the only
                                    # issues (6 infos) are in the concurrent
                                    # test stage's scratch zz_probe_test.dart
$ flutter test --timeout 120s test/features/settings/p16_bugs_test.dart
                                    # +24: all pass, 0 skips
$ flutter test --timeout 120s test/features/settings
                                    # +149 -1 — the 1 red is the test stage's
                                    # scratch probe above, not a P16 test
$ flutter test --timeout 120s       # +3538 ~2 -1 — the 1 red is P13's test
                                    # (passes alone); skips are K01 + P12
```

VERDICT: PASS
