
## UPDATE (19:45) — main (K04) is merged into this branch (k03_bugs_test resolved to main's version)
One K03 test now fails against your real celebration: k03_bugs_test.dart 'edge-case probes › back from the celebration returns to the home with the card flipped'. You MAY update that one test (and only that one) to drive K05's real Back/Done control and assert with pushedPath/currentPath. No placeholder text.
Pass 1 build/test failed only because Space Bunny returned empty runs: redo the integration properly this pass.
