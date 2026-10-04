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

/// Display name for the pet-stage semantics label (design alt text).
String pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}
