// K06's own Pip-look switches and wardrobe glyphs.
//
// Pip look comes from the ACTIVE CHILD's row (`PipProfile.style/skin/
// accessory/stage`), never from a hard-coded mascot (orchestrator PIP rule):
// Maya renders Mochi/sunny/stage 3, Leo Bolt/sky/stage 2. The maps are
// deliberately feature-local — `1_plan.md` §1a keeps Pip copy inside the pip
// feature, so K07 can reuse them without importing kid_home (which already
// imports pip).
//
// The stage-name helper lives HERE, not in `domain/`: ARCHITECTURE allows
// domain = entities + abstract repository only, and this is presentation copy
// (4_review.md #2).
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// Display name for a Pip stage. Pip's own copy — do NOT import the
/// kid_home/family helpers: 1 Egg, 2 Hatchling, 3 Fledgling, 4 Songbird.
String pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}

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
    // to".
    //
    // The sun hat joins them in `shared/k06_glyphs` (commit 5ff0c40):
    // `NestIcons.wardrobeSunHat` is the design's two paths
    // (`M3 16h18l-1.6 2.4H4.6z` brim + `M7 16a5 5 0 0 1 10 0z` dome), while
    // the old `NestIcons.sunHat` drew the brim 2.2 units higher, a flatter
    // dome (ry 7 vs 5) and a third band stroke. That mismatch was K06's one
    // open design-fidelity major (6_bugs.md "ORCH item 2 residual";
    // SHARED_REQUEST §7) and is now closed — the parked byte proof in
    // `pip_orchestrator_notes_test.dart` is un-skipped and green.
    // Crown keeps its existing icon: batch 7 verified its geometry matches.
    'scarf' => NestIcons.wardrobeScarf,
    'sunhat' => NestIcons.wardrobeSunHat,
    'wellies' => NestIcons.wardrobeWellies,
    'crown' => NestIcons.crown,
    _ => NestIcons.paw,
  };
}
