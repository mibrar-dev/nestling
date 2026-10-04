
## UPDATE (07:13) — the keypad layout is SHARED
NestKeypad's pitch (rows 88 / cols 96 vs design 82 / 88) is being fixed on shared/keypad_grid to match CSS `.keypad`. Do not re-space keys locally. After main has it (merged before your build), re-check the key centres against the design.

## UPDATE (10:32) — a test in k02_bugs_test.dart HANGS
`flutter test test/features/kid_home/k02_bugs_test.dart` never finished (one run was alive for 1 h 08 min), and full-suite runs hang on it too. The orchestrator killed the stuck processes.
- Find the hanging test (likely pumpAndSettle on a never-ending animation, an un-awaited Drift stream, or a missing runAsync) and make it finish: use pump(Duration) or runAsync, and close streams.
- Every test file must finish in under 60 s. Run single files with `--timeout 60s` while investigating.
- A test that can hang is itself a bug: fix it before anything else.
