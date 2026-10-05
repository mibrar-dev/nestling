# Shared request — P08b Today empty

Need: move the `todayEmptyRoute` (`/today-empty`) into the Today
`StatefulShellBranch` in `app/lib/app/router.dart` so the design's tab bar
(Today active) renders on P08b and the owner bottom-edge rule holds (the
tab-bar surface currently cannot extend to the physical edge because the
route sits outside any shell branch).

Files: `app/lib/app/router.dart`

Blocks: yes — pixel-perfect UI check (tab bar + bottom edge) is
blocked until this lands. Body work proceeds regardless. The
orchestrator's `shared/p08b_shell` branch is already doing this;
file once on main.
