# P03 Create account — bug hunt (Stage 6, iteration 6)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: the iteration-6 INTEGRATE checkpoint `520cd82` plus its
`2_build.md` (PASS), `4_review.md` (PASS, iteration 6) and `5_ui.md`
(PASS, iteration 6). **No screen code was changed by this stage** — only
this report. `ORCHESTRATOR_NOTES.md`'s items and the standing rules (PIP —
vacuous here, status bar, data-over-mocks, bottom edge, alignment, COPY,
CHILD ORDER — N/A, FONTS, LETTER SPACING, CHIP ROWS — N/A) were applied.

**Concurrency note (process, not a finding):** the iteration-6 **test stage
was running in this same worktree while this stage worked** (it owns
`app/test/features/auth/**`). I left its in-flight `zz_probe3_test.dart`
alone and removed two stale probe leftovers (`zz_probe_test.dart`,
`zz_probe2_test.dart`) that were breaking `flutter analyze`; they contained
no test logic and appear in no report. The suite numbers below are the
checkpoint's; stage 3 will publish the iteration-6 run.

## Ledger — nothing open on P03

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…15 | — | iterations 1–4's bugs | **all fixed**; proofs green regression guards |
| P03-BUG-16 | minor | invalid field painted no danger border | **fixed iteration 6** (Decision B: shared row wins) |
| P03-BUG-17 | minor | subtitle broke after “Children” | **resolved shared-side** (bundled Inter/Nunito) |
| P03-BUG-18…21 | — | overhang reachability, first-frame/stale measurement, live regions | **all fixed**; proofs green |
| P03-BUG-22 | minor | overhang fallback double-fired in the button/link overlap | **fixed iteration 6** (gesture-entry gate) |

Only `SHARED_REQUEST.md` §7 remains open on the screen — the non-blocking
`NestType.legalCaption` (13/20) token request; the current override is pinned
by P03-BUG-12 and the geometry matches the design. No proof on this screen is
skip-marked.

## Independent verification done this stage

- **P03-BUG-16 (danger border + announcement).** Both fields now pass
  `errorText` to the shared field and the screen-owned rows are gone. My own
  probe of the invalid state finds: the shared row is a labelled live region
  (`emailLive=true, emailLabel="Enter a valid email address"`, same for the
  password), the helper row is hidden (`At least 8 characters` → 0 nodes),
  and the danger border comes from the field's `InputDecoration`
  (`enabledBorder` switches on `errorText`, asserted by the green
  `P03-BUG-16` proof). BUG-11's gutter message is preserved because the
  shared row renders on the same 20dp gutter.
- **P03-BUG-22 (overlap double-fire), plus BUG-18 preserved.** At the
  harness-synthesised device geometry (390×844, `textScale 0.7`, because the
  test font is ~2× wider than Inter) the measurements are: button
  `y 740–792`, Terms target `y 785–829`, caption Stack `y 800–828`. A hit
  test at the overlap point now yields **`terms=false, button=true`** (fixed);
  a point in the gap above the Stack (`796`) and one on the bottom overhang
  (`828`) still yield **`terms=true`** (BUG-18 intact).
- **The `!hit` question is settled.** Probing an empty bar point outside the
  caption Stack (100, 835) shows the bar chain in the hit path — the bar's
  `RenderDecoratedBox` claims via its decoration (`RenderDecoratedBox`
  overrides `hitTestSelf` with `_decoration.hitTest`), so `hit` is **true**
  across the painted bar and an `if (!hit)` gate would indeed have starved
  the overhang. The shipped gesture-entry gate
  (`RenderPointerListener`/`RenderSemanticsGestureHandler` in
  `entry.path`) is the correct form. This corrects my iteration-4/5 read.
- **P03-BUG-17.** `body_text_width_test.dart` passes, including its two P03
  pins (“P03 subtitle unwrapped advance matches the browser render”, “P03
  subtitle wraps after ‘never’ in a 350 px column”), and the iteration-6 UI
  capture shows the subtitle ink at x 21–368 / 22–128 — identical to the
  design. Resolved with no local change.
- **FONTS rule.** No `google_fonts` import or `GoogleFonts.*` call anywhere
  in `lib/` or `test/`; Inter/Nunito are bundled assets in
  `app/assets/fonts` with `pubspec.yaml` families; P03's tests carry none.
- **LETTER SPACING rule.** No local tracking anywhere in the feature;
  `NestType`'s zero default applies, and the design's P03 styles set no
  tracking. **CHIP ROWS** N/A (no chips).

## Checked — no bug found

- **Kid-mode guard / deep links** — `APP_MODE=kid` + session kid mode →
  `/parental-gate`; no history → `/value-tour`; back-pops when stacked; the
  form renders on all three seeds.
- **Restart / Drift persistence** — one owner row, no rename, password never
  written.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit;
  all three buttons disable/spin together.
- **Text scale 1.3 + width 320/390/430** — matrix clean; five consecutive
  resizes keep both legal targets on their words; no overflow.
- **Dark-mode contrast / bottom edge / alignment** — unchanged tokens; the
  iteration-6 UI check passes with uniform `surface` to y=844 and 20px
  gutters (compare 3.50% light / 3.00% dark, bands 1–3 at noise level).
- **Copy** — the copy audit is green; subtitle U+2019, note U+2014 and the
  single U+00A0 inside “Privacy Notice” all byte-exact.
- **0/1/6 children, long UK names, £0.00/£999.99/9999 coins, empty lists,
  money rounding, timezone/BST, CHILD ORDER** — N/A on this screen (static
  form; no money/date logic; the members stream is never displayed; no
  children listed).
- **Async gaps / lifecycle** — controllers disposed, no timers, the
  verification chain is bounded and re-armed per dependency change, `emit`
  after close is a no-op; no pending-timer warnings.

## Observations (not bugs, not blocking)

- **`formError` can be announced twice in principle.** The shared error row
  is now a live region *and* the screen's `BlocListener` still calls
  `SemanticsService.sendAnnouncement` for `formError`. This predates the
  iteration-6 switch (the screen-owned row was a live region too) and the
  live-region half cannot be observed in a widget test, so no proof is
  filed. If the owner wants a single utterance, drop the `sendAnnouncement`
  once the row announces, or scope it to messages with no visible row.
- **Stale comment in `P03-BUG-22`'s proof tail** (“gates the overhang
  fallback behind `!hit`”) — the implementation is the gesture-entry gate.
  The concurrent test stage owns that file right now; flagged for its pass.
- **Filled-state simulator capture** (ORCHESTRATOR_NOTES item 3) remains
  host-blocked (no SimulatorKit/HID, no Simulator GUI); the filled state is
  pinned by the widget test, as the UI stage records.

## Suite state

- Checkpoint `520cd82` (build report, re-verified by the iteration-6 review):
  `flutter test test/features/auth` → **147/147 green, 0 skipped**;
  full suite **841 green**; `dart format` and `flutter analyze` clean.
- A full-suite run during this stage (with the shared tests merged since)
  → **845 passed, 0 failed**. The iteration-6 test stage is concurrently
  adding its own tests; its transient probe files are excluded from the
  checkpoint figures above.

## Verdict

No major bug remains — and no minor one either: iteration 6 closed the last
two (P03-BUG-16 via the landed §8 shared live-region row, P03-BUG-22 via the
gesture-entry gate) and BUG-17 was resolved shared-side by the bundled fonts.
I re-verified both closures with independent hit-test and semantics probes,
settled the `!hit` mechanism question in the shipped gate's favour, and
confirmed the FONTS/letter-spacing rules are clean. Only the non-blocking
shared §7 token request remains, owned by the orchestrator. The screen is
converged: geometry within ~1–2dp of the design in both themes, exact copy,
clean bottom edge and alignment, and no loose end in the bloc, persistence,
guards or async paths.

VERDICT: PASS
