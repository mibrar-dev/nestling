// K10's own Pip-look switches, copied feature-privately from
// `kid_home/presentation/widgets/kid_style_helpers.dart`: RULES §1 forbids
// importing `kid_home` (which already imports `pip`), and ARCHITECTURE bans
// growing shared code for one feature. Return `mochi`/`sunny` for unknown
// values, exactly like the source switches.
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// `children.pipStyle` -> [PipStyle].
PipStyle pipStyleOf(String raw) {
  return switch (raw) {
    'bolt' => PipStyle.bolt,
    'storybook' => PipStyle.storybook,
    _ => PipStyle.mochi,
  };
}

/// `children.pipSkin` -> [PipSkin].
PipSkin pipSkinOf(String raw) {
  return switch (raw) {
    'sky' => PipSkin.sky,
    'berry' => PipSkin.berry,
    'mint' => PipSkin.mint,
    _ => PipSkin.sunny,
  };
}

/// `children.pipAccessory` -> [PipAccessory].
PipAccessory pipAccessoryOf(String raw) {
  return switch (raw) {
    'bow' => PipAccessory.bow,
    'cap' => PipAccessory.cap,
    'scarf' => PipAccessory.scarf,
    'glasses' => PipAccessory.glasses,
    _ => PipAccessory.none,
  };
}
