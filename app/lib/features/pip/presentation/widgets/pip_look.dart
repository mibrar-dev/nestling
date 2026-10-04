// K06's own Pip-look switches and wardrobe glyphs.
//
// Pip look comes from the ACTIVE CHILD's row (`PipProfile.style/skin/
// accessory/stage`), never from a hard-coded mascot (orchestrator PIP rule):
// Maya renders Mochi/sunny/stage 3, Leo Bolt/sky/stage 2. The maps are
// deliberately feature-local — `1_plan.md` §1a keeps Pip copy (the stage
// name lives in `domain/entities/pip_nest.dart`) inside the pip feature, so
// K07 can reuse them without importing kid_home (which already imports pip).
import 'package:nestling/core/design_system/components/nest_icon.dart';
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

/// Wardrobe tile glyph for a wardrobe row id
/// (`scarf | sunhat | wellies | crown`), from the design's inline SVGs in
/// `.k6-ward`. Unknown ids fall back to the paw so a new seed row still
/// renders a glyph instead of an empty circle.
String pipWardrobeIcon(String item) {
  return switch (item) {
    'scarf' => NestIcons.scarf,
    'sunhat' => NestIcons.sunHat,
    'wellies' => NestIcons.wellies,
    'crown' => NestIcons.crown,
    _ => NestIcons.paw,
  };
}
