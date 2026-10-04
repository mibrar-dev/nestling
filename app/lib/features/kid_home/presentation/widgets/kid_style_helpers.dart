import 'package:nestling/core/design_system/components/nest_avatar.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// Shared child-style switches for kid_home views and widgets.
///
/// Extracted from `kid_home_view.dart` so the K01 picker tiles render the
/// SAME mapping (avatar colour, Pip look, stage name) without duplicating
/// the switch in a second file. The logic is verbatim from K03.
NestAvatarColor avatarColorOf(String raw) {
  return switch (raw) {
    'lilac' => NestAvatarColor.lilac,
    'peach' => NestAvatarColor.peach,
    'sky' => NestAvatarColor.sky,
    'leaf' => NestAvatarColor.leaf,
    'coin' => NestAvatarColor.coin,
    _ => NestAvatarColor.neutral,
  };
}

/// The child's own Pip look from the database (ORCHESTRATOR_NOTES #1).
PipStyle pipStyleOf(String raw) {
  return switch (raw) {
    'bolt' => PipStyle.bolt,
    'storybook' => PipStyle.storybook,
    _ => PipStyle.mochi,
  };
}

PipSkin pipSkinOf(String raw) {
  return switch (raw) {
    'sky' => PipSkin.sky,
    'berry' => PipSkin.berry,
    'mint' => PipSkin.mint,
    _ => PipSkin.sunny,
  };
}

PipAccessory pipAccessoryOf(String raw) {
  return switch (raw) {
    'bow' => PipAccessory.bow,
    'cap' => PipAccessory.cap,
    'scarf' => PipAccessory.scarf,
    'glasses' => PipAccessory.glasses,
    _ => PipAccessory.none,
  };
}

/// Grapheme-safe avatar initial for a child's nickname.
///
/// `nickname[0]` indexes UTF-16 **code units**, so a nickname opening with a
/// non-BMP character (emoji, regional-indicator flag, many CJK extensions)
/// yields an unpaired surrogate and `toUpperCase()` then throws
/// `ArgumentError: string is not well-formed UTF-16` while laying out the
/// frame — the whole screen fails to build, not just the avatar. P05 accepts
/// such a name (no `inputFormatters`, no character filter), so the crash is
/// reachable: K02-TEST-BUG-A. Runes keep the string well-formed —
/// `String.fromCharCode` can split a grapheme cluster but never a code point,
/// so the frame always builds and the emoji itself renders as the initial.
// TODO(K02): SHARED_REQUEST #3 asks for one `nestAvatarInitial()` in the
// design system covering all seven call sites (four features). Delete this
// and call the shared helper when it lands.
// TODO(K02): the parent row keeps its own `'S'` fallback at
// `features/today/presentation/widgets/today_loaded_body.dart` — pass it via
// [fallback] there rather than branching at the call site.
String kidAvatarInitial(String nickname, {String fallback = '?'}) {
  if (nickname.isEmpty) return fallback;
  return String.fromCharCode(nickname.runes.first).toUpperCase();
}

/// Display name for the pet-stage semantics label (design alt text).
String pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}
