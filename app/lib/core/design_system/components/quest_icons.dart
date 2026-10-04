import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';

/// Shared quest glyphs — the single source for `quests.icon` keys.
///
/// Each screen matches its OWN design (orchestrator audience ruling):
///
/// * parent (`NestAudience.parent`): exact `P09-quest-editor.html` /
///   `P10-quest-library.html` / `P08-today.html` glyphs. The four P09-exact
///   assets stay canonical (`questBed` flat frame, `questDishes` handled
///   basket, `questHoover` angular canister + legs, `questBins` handled
///   case + clasp) — P10 omits the bins clasp and hoover legs and P08
///   draws the bed WITH the headboard arc, but those deltas are ≤ raster
///   and the P09 exact is kept (batch-5 follow-up). `book` (closed) and
///   `paw` (4-dot) were already byte-identical to P09. `table`,
///   `schoolBag`, `sprout` and `washingMachine` are the long-standing
///   parent look-alikes P10 Ideas already renders (no P09 tile exists for
///   them); they are kept as the parent canonical rather than adding four
///   more near-duplicate files.
/// * kid (`NestAudience.kid`): exact `K03-kid-home.html` /
///   `K04-quest-detail.html` glyphs where the kid designs draw the quest —
///   `questBedKid` (K04 hero `M2 18v-7 / M2 14h20v4 / …h-9v3 /
///   M6 11V8h4v3`), `questDishesKid` (K03 dishwasher
///   `rect 3/4/18/16 + M3 10h18 + circle 8/14.5`),
///   `questReadingKid` (K03 open book `M12 6v14 + M3 4.6… + M21 4.6…`),
///   `questBinsKid` (K09 lidded bin `M6 3h12l-2 5H8Z` +
///   `M8 8v10a2 2 0 0 0 8 0V8` — the kid designs disagree: K03/K04 draw
///   no bins row so the kid set fell back to the parent `questBins`;
///   K09 is where bins appears most prominently, so the kid set now uses
///   the K09-exact glyph).
///
/// Where a key has only ONE design source, BOTH audiences use it:
///
/// * `hoover`, `paw`/`pet`: only parent draws them
///   (K03/K04 show no hoover/paw rows) — both use the parent glyph.
/// * `bins`/`bin`: parent uses the P09-exact `questBins`; kid uses the
///   K09-exact `questBinsKid` (see above).
/// * `plate`/`table`, `bag`/`schoolBag`, `leaf`/`plants`, `shirt`/`washing`:
///   only P10 draws them — both use the parent look-alike.
/// * `sofa` (seed `q-living` Tidy the living room): NO design draws it —
///   both fall back to the `questCard` glyph, exactly as `questIconAsset`
///   and `todayIconFor` always have.
///
/// Aliases mirror the historical `questIconAsset`/`todayIconFor` switches
/// so existing stored spellings keep resolving: `reading` → book/reading,
/// `bin` → bins, `table` → plate, `schoolBag` → bag, `plants` → leaf,
/// `washing` → shirt, `pet` → paw. Unknown keys fall back to `questCard`.
String questIconFor(String key, {required NestAudience audience}) {
  if (audience == NestAudience.kid) {
    return switch (key) {
      'bed' => NestIcons.questBedKid,
      'dishwasher' => NestIcons.questDishesKid,
      'book' || 'reading' => NestIcons.questReadingKid,
      'bins' || 'bin' => NestIcons.questBinsKid,
      'hoover' => NestIcons.questHoover,
      'paw' || 'pet' => NestIcons.paw,
      'bag' || 'schoolBag' => NestIcons.schoolBag,
      'leaf' || 'plants' => NestIcons.sprout,
      'shirt' || 'washing' => NestIcons.washingMachine,
      'plate' || 'table' => NestIcons.table,
      _ => NestIcons.questCard,
    };
  }
  return switch (key) {
    'bed' => NestIcons.questBed,
    'dishwasher' => NestIcons.questDishes,
    'hoover' => NestIcons.questHoover,
    'bins' || 'bin' => NestIcons.questBins,
    'book' || 'reading' => NestIcons.book,
    'paw' || 'pet' => NestIcons.paw,
    'bag' || 'schoolBag' => NestIcons.schoolBag,
    'leaf' || 'plants' => NestIcons.sprout,
    'shirt' || 'washing' => NestIcons.washingMachine,
    'plate' || 'table' => NestIcons.table,
    _ => NestIcons.questCard,
  };
}

/// Every `quests.icon` key the demo seed writes (`core/data/seed.dart`
/// `_questsDemo`).
const Set<String> questIconKeys = <String>{
  'dishwasher',
  'book',
  'bins',
  'bed',
  'hoover',
  'plate',
  'paw',
  'bag',
  'leaf',
  'shirt',
  'sofa',
};
