# Shared request — P14 bottom-sheet keyboard inset

Need: `showNestBottomSheet`
(`app/lib/core/design_system/components/nest_bottom_sheet.dart`) never reads
`MediaQuery.viewInsets`, and its `constraints: BoxConstraints(maxHeight:
size.height * 0.92)` is read once when the sheet opens — before a keyboard
exists. On iOS the keyboard is reported as an inset only (it floats over the
Flutter view rather than resizing it), so any `isScrollControlled` sheet keeps
its buttons behind the keyboard and has no scroll escape: measured on
`/rewards` with a 300 px inset, `Save` 682→734 and `Cancel` 742→794 against a
keyboard top of 544 (P14-B01). Every screen with a form sheet has the same
hole. Two changes fix it once: (a) make the cap keyboard-aware (the sheet may
be `size.height + viewInsets.bottom` tall so the inset becomes trailing space),
or (b) drop the fixed cap and let callers cap themselves, plus make the sheet
body scrollable.

Files: `app/lib/core/design_system/components/nest_bottom_sheet.dart`.

Blocks: no — `/rewards` ships a feature-local opener
(`showRewardEditorSheet` in
`app/lib/features/rewards/presentation/views/rewards_view.dart`) that composes
the same shared `NestBottomSheet` with the unbounded cap, and
`RewardEditorSheet` applies the resting 92 % cap and the keyboard padding
itself. This request is so the other screens stop needing the local copy; P14
would then delete `showRewardEditorSheet` and go back to the shared helper.
