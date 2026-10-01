CONTINUE docs/briefs/26_motion_verify.md (re-read it). Your previous run was terminated while sitting inside an INTERACTIVE `flutter run` (it waits for keyboard input forever). RULES this time:
- NEVER run plain `flutter run`. Launch with `flutter run -d 604697A9-11DA-462F-9837-396E9CA2493A --debug --no-resident [--dart-define=MOTION_AUTOPLAY=<name>]` (installs + launches, then exits), or `xcrun simctl launch`. Always `< /dev/null`.
- Background recordings: `xcrun simctl io <UDID> recordVideo --codec=h264 --force <file> &` then `kill -INT <pid>`.
- Disk is tight (~12 GB free): keep each video ≤ 15 s; delete extracted frames after measuring.
DONE ALREADY (orchestrator verified): design/videos/pip_idle.mp4 — PASS (steady breathing motion + blink spike every ~3 s in Pip's rect). Do NOT redo it; add it to MOTION_QA.md as PASS.
REMAINING: fix Play-all sequencing/scrolling; verify + record Pip happy, eating, evolve (3→4), Jar drop + fill 0.2→0.62; the 4 Lottie videos; a clean motion_lab_play_all.mp4; MOTION_QA.md table; flutter analyze clean; flutter test pass. Short final reply = the table.
