// K07's own screen copy (`/pip-evolution`, `1_plan.md` §(a).10).
//
// Every string here is byte-checked against
// `design/html-source/screens/K07-evolution.html`:
//
//   line 55  `Pip grew into a Songbird!`   -> [evolutionTitle] pattern
//   line 56  `Because you helped 25 times` -> [evolutionSub] pattern
//   line 57  `Hear that? That is Pip's new song!` -> [evolutionSpeech] (4)
//   line 59  `quests done` / line 60 `coins grown` / line 61 `of 4 stages`
//   line 63  `Pip still loves a chin scratch.` -> [evolutionCaption]
//   line 66  `Meet Songbird Pip`           -> [evolutionCta] pattern
//
// The design writes a LITERAL ASCII apostrophe (0x27) in `Pip's` — verified
// with a byte dump of line 57 (`50 69 70 27 73`), never `&rsquo;`. The
// orchestrator COPY rule makes the source byte the oracle, so this file uses
// ASCII `'` throughout (the K06-BUG-3 / K01 BUG-A precedent).
//
// The stage NAMES are not duplicated here: [pipStageName] in `pip_look.dart`
// is the feature's single Pip stage table (1 Egg, 2 Hatchling, 3 Fledgling,
// 4 Songbird), already used by K06, so the two screens can never disagree.
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

/// The stage name this screen shows (delegates to the feature's shared
/// table). `stage` is expected clamped to 1..4 by the caller.
String evolutionStageName(int stage) => pipStageName(stage);

/// `an Egg` / `a Hatchling` / `a Fledgling` / `a Songbird` — `an` only before
/// a vowel-initial name (same rule as the family's `pipStageArticle`).
String evolutionStageArticle(int stage) =>
    evolutionStageName(stage).startsWith('E') ? 'an' : 'a';

/// `.k7-hero` — HTML line 55. ASCII `!`, no curly quotes:
/// demo (Maya, stage 3) -> `Pip grew into a Fledgling!`.
String evolutionTitle(int stage) =>
    'Pip grew into ${evolutionStageArticle(stage)} ${evolutionStageName(stage)}!';

/// `.k7-sub` — HTML line 56. [questsDone] is the LIFETIME count, so the
/// singular form matters: `1` -> `Because you helped 1 time`.
String evolutionSub(int questsDone) => questsDone == 1
    ? 'Because you helped 1 time'
    : 'Because you helped $questsDone times';

/// `.k7-cheer .speech` — HTML line 57 verbatim for the design's stage 4; the
/// other stages are parallel kid-tone lines (no HTML source, so they follow
/// the design's ASCII-apostrophe byte).
String evolutionSpeech(int stage) => switch (stage) {
  1 => 'Shh... Pip is still growing!',
  2 => 'Hello! Pip is out of the egg!',
  4 => "Hear that? That is Pip's new song!",
  _ => "Flap, flap! Look at Pip's wings!",
};

/// `.btn-kid.lilac` — HTML line 66 (`Meet Songbird Pip`); demo Maya ->
/// `Meet Fledgling Pip`.
String evolutionCta(int stage) => 'Meet ${evolutionStageName(stage)} Pip';

/// `.kcap` — HTML line 63 verbatim.
String evolutionCaption() => 'Pip still loves a chin scratch.';

/// The stage name as an a11y phrase, for the new Pip's image label
/// (`Maya's Pip, a fledgling`). No HTML source (the design's `alt` is
/// `Songbird Pip, all grown up`, which cannot carry the DB's stage), so this
/// is feature copy shaped like [evolutionStageName].
String evolutionStagePhrase(int stage) => switch (stage) {
  1 => 'an egg',
  2 => 'a hatchling',
  4 => 'a songbird',
  _ => 'a fledgling',
};

/// VoiceOver label for the new Pip: `{Nickname}'s Pip, {phrase}` (ASCII
/// apostrophe, matching the design's byte). Stated here rather than imported
/// from the family feature: cross-feature imports of presentation copy are not
/// established practice, and the phrasing is K07's own.
String evolutionNewPipLabel(String nickname, int stage) =>
    "$nickname's Pip, ${evolutionStagePhrase(stage)}";

/// One merged VoiceOver summary for the three stat cards, so the numbers are
/// announced as a sentence instead of six loose fragments.
String evolutionStatsLabel({
  required int questsDone,
  required int coinsGrown,
  required int stage,
}) => '$questsDone quests done, $coinsGrown coins grown, stage $stage of 4';
