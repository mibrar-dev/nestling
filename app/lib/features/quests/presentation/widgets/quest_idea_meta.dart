import 'package:flutter/foundation.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

/// "All" chip value — matches every category.
const String kAllQuestCategories = 'All';

/// Filter chip row, in design order (`P10 .chipscroll` copy).
const List<String> kQuestCategories = <String>[
  kAllQuestCategories,
  'Bedroom',
  'Kitchen',
  'Outdoors',
  'Pets',
  'School',
  'Kindness',
];

/// Category / minimum age / icon-tile tint / icon asset for one idea
/// template.
///
/// The `quests` table has no category column and the schema is shared
/// (RULES §1 — never add one), so this presentation-side map is the single
/// source for the filter chips, the icon tile and the `· Ages N+ ·` meta
/// line. [Quest.detail] is deliberately NOT used for ideas: the repository
/// formats it as `'5 coins · age 4+'` (lowercase `age`, no category).
@immutable
class QuestIdeaMeta {
  const QuestIdeaMeta({
    required this.category,
    required this.minAge,
    required this.tint,
    required this.iconAsset,
  });

  final String category;

  /// Lower bound of the suggested age band (`4+` ⇒ 4).
  final int minAge;
  final NestTileTint tint;
  final String iconAsset;

  /// `.trow .mt` — `5 coins · Ages 4+ · Bedroom` (middot U+00B7).
  String metaFor(int coins) => '$coins coins · Ages $minAge+ · $category';
}

/// `ideas()` id → metadata. Keys match `QuestsRepositoryImpl._ideas`.
const Map<String, QuestIdeaMeta> kQuestIdeaMeta = <String, QuestIdeaMeta>{
  'idea-bed': QuestIdeaMeta(
    category: 'Bedroom',
    minAge: 4,
    tint: NestTileTint.peach,
    iconAsset: NestIcons.bed,
  ),
  'idea-table': QuestIdeaMeta(
    category: 'Kitchen',
    minAge: 5,
    tint: NestTileTint.sky,
    iconAsset: NestIcons.table,
  ),
  'idea-bins': QuestIdeaMeta(
    category: 'Outdoors',
    minAge: 8,
    tint: NestTileTint.leaf,
    iconAsset: NestIcons.bin,
  ),
  'idea-dishwasher': QuestIdeaMeta(
    category: 'Kitchen',
    minAge: 7,
    tint: NestTileTint.sky,
    iconAsset: NestIcons.dishwasher,
  ),
  'idea-hoover': QuestIdeaMeta(
    category: 'Bedroom',
    minAge: 9,
    tint: NestTileTint.lilac,
    iconAsset: NestIcons.hoover,
  ),
  'idea-pet': QuestIdeaMeta(
    category: 'Pets',
    minAge: 4,
    tint: NestTileTint.coin,
    iconAsset: NestIcons.paw,
  ),
  'idea-bag': QuestIdeaMeta(
    category: 'School',
    minAge: 5,
    tint: NestTileTint.sky,
    iconAsset: NestIcons.schoolBag,
  ),
  'idea-plants': QuestIdeaMeta(
    category: 'Outdoors',
    minAge: 5,
    tint: NestTileTint.leaf,
    iconAsset: NestIcons.sprout,
  ),
  'idea-washing': QuestIdeaMeta(
    category: 'Bedroom',
    minAge: 7,
    tint: NestTileTint.peach,
    iconAsset: NestIcons.washingMachine,
  ),
  'idea-reading': QuestIdeaMeta(
    category: 'School',
    minAge: 5,
    tint: NestTileTint.lilac,
    iconAsset: NestIcons.book,
  ),
};

/// Metadata for an idea template, or `null` for an unknown id.
QuestIdeaMeta? questIdeaMetaFor(String id) => kQuestIdeaMeta[id];

/// Pure search + category filter for the Ideas tab. Both filters combine
/// (AND); the query is a case-insensitive substring of the title.
List<Quest> filterQuestIdeas(
  List<Quest> ideas, {
  String query = '',
  String category = kAllQuestCategories,
}) {
  final needle = query.trim().toLowerCase();
  final all = category == kAllQuestCategories;
  return ideas
      .where((idea) {
        if (!all && questIdeaMetaFor(idea.id)?.category != category) {
          return false;
        }
        if (needle.isEmpty) return true;
        return idea.title.toLowerCase().contains(needle);
      })
      .toList(growable: false);
}

/// Seed `quests.icon` → [NestIcons] asset, for the Active tab rows.
///
/// The repository idea keys (`plate`, `bins`, `bag`, …) do not map 1:1 onto
/// asset names, so both the ideas map ([kQuestIdeaMeta]) and the live-quest
/// rows resolve through a key switch.
String questIconAsset(String icon) {
  switch (icon) {
    case 'dishwasher':
      return NestIcons.dishwasher;
    case 'book':
    case 'reading':
      return NestIcons.book;
    case 'bins':
    case 'bin':
      return NestIcons.bin;
    case 'bed':
      return NestIcons.bed;
    case 'hoover':
      return NestIcons.hoover;
    case 'paw':
    case 'pet':
      return NestIcons.paw;
    case 'bag':
    case 'schoolBag':
      return NestIcons.schoolBag;
    case 'leaf':
    case 'plants':
      return NestIcons.sprout;
    case 'shirt':
    case 'washing':
      return NestIcons.washingMachine;
    case 'plate':
    case 'table':
      return NestIcons.table;
    default:
      return NestIcons.questCard;
  }
}

/// `.icon-tile` tint for a live quest's icon key.
///
/// Every seed key is mapped, so no quest falls through to the grey
/// `NestTileTint.neutral`, and the tints agree with [kQuestIdeaMeta] for
/// every title that appears on both tabs (e.g. `plate` is `sky`, like
/// `idea-table`): switching tabs must not change a row's colour.
///
/// Note: P08's `todayTintFor` still paints `plate` lilac (see
/// `docs/screens/P10/SHARED_REQUEST.md` §2) — a cross-screen disagreement the
/// orchestrator owns, not a P10 edit.
NestTileTint questTileTintFor(String icon) {
  switch (icon) {
    case 'dishwasher':
    // `idea-table` is sky on the Ideas tab: the same title keeps its tint.
    case 'plate':
    case 'table':
    // `idea-bag` ("Pack school bag") is sky too.
    case 'bag':
      return NestTileTint.sky;
    case 'book':
    case 'reading':
    case 'hoover':
    // `q-living` — "Tidy the living room". Lilac: the living-room ideas read
    // as a lilac family on P08's today rows.
    case 'sofa':
      return NestTileTint.lilac;
    case 'bins':
    case 'bin':
    case 'leaf':
    case 'plants':
      return NestTileTint.leaf;
    case 'paw':
    case 'pet':
      return NestTileTint.coin;
    case 'bed':
    case 'shirt':
    case 'washing':
      return NestTileTint.peach;
    // An unknown key is not a real quest: it keeps the neutral tile rather
    // than borrowing another family's colour. Every seed key is mapped above,
    // so no seeded quest can reach this branch.
    default:
      return NestTileTint.neutral;
  }
}
