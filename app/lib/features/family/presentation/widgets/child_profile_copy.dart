// P15 child-profile copy (`/child-profile`).
//
// Every string is composed from the characters the design's HTML source
// uses (`design/html-source/screens/P15-child-profile.html`), compared
// byte-for-byte:
//
//   `Age 7–9 · Pip is a Fledgling`  U+2013 EN DASH in the band (the seed
//                                    stores `7-9`), U+00B7 MIDDLE DOT
//   `Pip · Fledgling`                U+00B7
//   `175 of 250 · 70%`               U+00B7
//   `On · Maya knows her code`       U+00B7
//   `Change ›`                       `20` SPACE + U+203A SINGLE RIGHT-POINTING
//                                    ANGLE QUOTATION MARK
//   `£3.00 a week · Owed £4.20`      U+00A3, U+00B7
//
// Never ASCII `-`, `|`, `>` or a straight quote in this screen's copy.
//
// The only wording deviation from the HTML is the PIN subtitle's pronoun:
// the design says "Maya knows **her** code", the schema stores no gender, so
// the row reads "knows **their** code" — the same data-driven adaptation
// `1_plan.md` §(a).4 records.

import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/presentation/widgets/child_display.dart';

/// U+00B7 MIDDLE DOT — the P15 clause separator (`Age 7–9 · Pip is …`).
const String kProfileDot = '·';

/// U+203A SINGLE RIGHT-POINTING ANGLE QUOTATION MARK — the list-row
/// trailing chevron (`Change ›`). U+00BB `»` is NOT the design glyph.
const String kProfileChevron = '›';

/// Display name for a Pip stage (design `.hero .sub` / `.piprow` head).
///
/// Same mapping as K03 (`kid_home_view.dart:_pipStageName`) and P08
/// (`today_loaded_body.dart`): 1 Egg, 2 Hatchling, 3 Fledgling, 4 Songbird.
String pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}

/// The indefinite article for a Pip stage name: `a Fledgling` but `an Egg`.
///
/// `children.pipStage` defaults to 1, so every child added through P05 lands
/// on `Egg` — the hard-coded `a` read "Pip is a Egg" (BUG P15-BUG-4). Same rule
/// as [pipStagePhrase], which lower-cases the stage for the spoken label.
String pipStageArticle(int stage) =>
    pipStageName(stage).startsWith('E') ? 'an' : 'a';

/// `Age 7–9 · Pip is a Fledgling` (`· Pip is an Egg` for a stage-1 Pip) —
/// the hero sub-line under the name.
String profileAgeLine(FamilyChild child) {
  final stage = pipStageName(child.pipStage);
  return 'Age ${displayAgeBand(child.ageBand)} '
      '$kProfileDot Pip is ${pipStageArticle(child.pipStage)} $stage';
}

/// `Pip · Fledgling` — the Pip card heading.
String profilePipTitle(FamilyChild child) =>
    'Pip $kProfileDot ${pipStageName(child.pipStage)}';

/// `Evolves at 250 total coins` — under the Pip card heading.
String profileEvolvesCaption(int evolveAtCoins) =>
    'Evolves at $evolveAtCoins total coins';

/// Growth fraction of [totalCoins] against [evolveAtCoins], clamped to the
/// bar's 0…1 range (P05/`.progress > span`).
double pipGrowthFraction(int totalCoins, int evolveAtCoins) {
  if (evolveAtCoins <= 0) return 0;
  return (totalCoins / evolveAtCoins).clamp(0.0, 1.0);
}

/// `175 of 250 · 70%` — the caption under the growth bar. The percentage is
/// the same rounded value the bar is drawn from, so copy and fill agree.
String profileGrowthCaption(int totalCoins, int evolveAtCoins) {
  final percent = (pipGrowthFraction(totalCoins, evolveAtCoins) * 100).round();
  return '$totalCoins of $evolveAtCoins $kProfileDot $percent%';
}

/// `On · Maya knows their code` / `Off · No code set yet`.
String profilePinSubtitle(FamilyChild child) {
  return child.pinSet
      ? 'On $kProfileDot ${child.nickname} knows their code'
      : 'Off $kProfileDot No code set yet';
}

/// `6 active · 4 daily, 2 weekly` — one-off quests are named only when there
/// are any (`· 2 one-off`), so a demo family with none keeps the design's
/// two-clause shape.
String profileQuestsSubtitle({
  required int daily,
  required int weekly,
  required int once,
}) {
  final active = daily + weekly + once;
  final buffer = StringBuffer()
    ..write('$active active $kProfileDot $daily daily, $weekly weekly');
  if (once > 0) buffer.write(' $kProfileDot $once one-off');
  return buffer.toString();
}

/// `£3.00 a week · Owed £4.20` — formatted with the design system's own
/// `formatPounds` (exported from the barrel); `.abs()` matches the ledger's
/// `moneyPounds` sign-free rendering, so the copy is unchanged.
String profileMoneySubtitle(int weeklyBasePence, int owedPence) {
  String pounds(int pence) => formatPounds(pence.abs() / 100);
  return '${pounds(weeklyBasePence)} a week '
      '$kProfileDot Owed ${pounds(owedPence)}';
}

/// `Change ›` — the PIN row's trailing control text.
String profilePinTrailing() => 'Change $kProfileChevron';

/// `Remove Maya from family` — the danger-ghost label.
String profileRemoveLabel(String nickname) => 'Remove $nickname from family';

/// `Remove Maya?` — the confirm dialog title.
String profileRemoveTitle(String nickname) => 'Remove $nickname?';

/// Confirm-dialog body. UK spelling; the design has no modal, so this is the
/// `1_plan.md` §(c) copy.
const String profileRemoveBody =
    'They will lose their quests, coins and Pip. This cannot be undone.';

/// Lower-case stage name with its article, for announcements only — the same
/// wording P08's kid card uses (`today_loaded_body.dart:pipStageName`), so
/// both screens announce Pip identically. Stage 1 takes "an", not "a".
String pipStagePhrase(int stage) => switch (stage) {
  1 => 'an egg',
  2 => 'a hatchling',
  4 => 'a songbird',
  _ => 'a fledgling',
};

/// Accessibility label for the Pip avatar: `Maya's Pip, a fledgling`.
String profilePipSemanticLabel(FamilyChild child) =>
    "${child.nickname}'s Pip, ${pipStagePhrase(child.pipStage)}";
