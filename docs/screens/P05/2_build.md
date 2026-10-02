# P05 · Add children — build notes (STAGE 2, iteration 5)

Route `/add-children` (feature `family`, parent mode). Iteration 4 record is
superseded below. Every item in `docs/screens/P05/FIXES_4.md` is addressed;
no skipped bug tests exist or are referenced. No product-code change was
needed this iteration: all remaining FIXES_4 items are shared/out-of-scope
with standing filings, and the one gate that was red is green again via
main. Working tree is clean apart from these notes.

## Files changed (RULES §1 only)

- `docs/screens/P05/2_build.md` — this file. Nothing else.

No product, test, or shared file touched: there was nothing in RULES §1
left to fix (details per item below).

## What was done about each fix item

- **Test bug 1 — `router_push_test` placeholder copy: RESOLVED via main,
  verified.** `cdd4cf5` ("shared/router_push_test_fix: push/pop contract
  asserts router paths, not placeholder titles") reworked the shared test
  to assert router paths. Full-suite tail this run: `00:29 +669: All tests
  passed!` (exit 0) — the BLOCKING filing in `SHARED_REQUEST.md` is now
  historical; the gate is green on this branch unmodified.
- **Test bug 2 — residual drift is a shared typography effect: no P05
  action, filing verified.** The `SHARED_REQUEST.md` entry is complete and
  its factual claims re-checked: `pubspec.yaml` carries no bundled fonts
  (only the template comment), `google_fonts` fetches at runtime, and every
  P05 gap/row is a literal `SizedBox`/DS height pinned by the iteration-4
  tests — so per-row line-box growth is the only remaining variable and it
  lives in the shared type scale. The delegated brief
  (`docs/screens/_shared/body_text_width.md`) explicitly scopes its fix to
  shared styles with "no per-screen hacks", so touching P05 here would
  contradict it.
- **UI deviation 1 (+12 from the 44 px chip tap box): shared, already
  filed, no P05-local workaround exists.** Verified against the HTML/CSS
  sources that every P05-owned vertical value is already exact: `.field`
  margin-top 10, label→input 6 (DS field internals), `.lbl` margin-top 8,
  `.chip-row` margin-top 4, `.swatches` margin-top 4, gap 8, swatch 44×44,
  `.form-note` margin-top 6 — all literal in `add_child_form_card.dart` via
  tokens. Taking a 32 px chip height locally would mean overriding the DS
  component's height, breaking the 44-min tap targets the suite pins and
  `SPACING_SPEC` §10.6 ("keep visual size"); negative spacing or fixed
  heights would break tokens and text-scale behaviour, exactly as the UI
  stage concluded. Standing `SHARED_REQUEST.md` #3 (overlay construction:
  32 px layout row, 44 px tap area overlaid) remains the fix.
- **UI note 6 (orchestrator §18.2–3 targets): no action.** The UI stage
  showed those numbers do not reproduce from the design PNG; its own
  measured table is the reproducible record, and the only open residual in
  it is the +12 above.
- **Orchestrator iteration-5 targets: met where P05-owned.** Chips render
  one row left-aligned with 8 px gaps (verified iteration 2 on-simulator,
  still the code); swatches 44 px diameter with 8 px gaps (literal
  `NestDevice.tapParent` + `spacing: s2`); chip-row→label 8 and
  label→swatch 4 taken exactly from the HTML (see table above). The +5/+12
  centres are the shared chip-box effect, not gap errors.
- **No skipped tests.** `grep -c "skip:"` returns 0 in both family test
  files; FIXES_4 references no skipped proofs. P05-BUG-1…10 proofs all run
  un-skipped and green inside the suite.
- **Main merges consumed, not re-patched.** `family_time_zone` (UTC
  instants, Drift migration) and the router-test fix merged cleanly; core
  `watchChildren` still orders by nickname and the table still has no
  `createdAt`, so the iteration-4 `rowid` interim stands as the ruling's
  implementation. Suite green throughout.

## Verification tails

`dart format .` — clean (0 changed, 362+ files).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:29 +669: All tests passed!` (exit 0,
zero skips in `test/features/family/`). Every widget test that pumps the
app ends with `disposeApp(tester)`.

VERDICT: PASS
