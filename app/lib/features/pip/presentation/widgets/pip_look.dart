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
    // ORCHESTRATOR_NOTES 11:30 item 2 ("wardrobe icons must be the design's
    // glyphs … do not substitute") + 13:52. `shared/shared_batch7` added the
    // exact `K06-pip.html` paths as `NestIcons.wardrobeScarf` /
    // `NestIcons.wardrobeWellies`; `NestIcons.scarf` / `.wellies` are
    // look-alikes (a fringed blanket and a side-profile boot) and are no longer
    // what this screen may draw. See
    // docs/screens/_shared/shared_batch7_REPORT.md §1 + "What K06 must switch
    // to". Sun hat and crown keep their existing icons — batch 7 verified
    // their geometry already matches the design.
    'scarf' => NestIcons.wardrobeScarf,
    'sunhat' => NestIcons.sunHat,
    'wellies' => NestIcons.wardrobeWellies,
    'crown' => NestIcons.crown,
    _ => NestIcons.paw,
  };
}
