import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart' as domain;
import 'package:nestling/features/quests/domain/quests_repository.dart';

/// Drift-backed [QuestsRepository].
class QuestsRepositoryImpl implements QuestsRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<domain.Quest>> getItems() => watchItems().first;

  @override
  Stream<List<domain.Quest>> watchItems() {
    return _db.watchActiveQuests(Seed.familyId).map(_toEntities);
  }

  @override
  List<domain.Quest> ideas() => _ideas;

  @override
  Future<domain.Quest?> getQuest(String id) async {
    final row = await (_db.select(
      _db.quests,
    )..where((q) => q.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> createQuest(domain.Quest quest) {
    return _db
        .into(_db.quests)
        .insert(
          QuestsCompanion.insert(
            id: quest.id,
            familyId: Seed.familyId,
            title: quest.title,
            icon: Value(quest.icon),
            coins: Value(quest.coins),
            repeatRule: Value(quest.repeatRule),
            days: Value(quest.days),
            dueLabel: Value(quest.dueLabel),
            needsApproval: Value(quest.needsApproval),
            assigneeChildId: Value(quest.assigneeChildId),
            active: const Value(true),
          ),
        );
  }

  @override
  Future<void> updateQuest(domain.Quest quest) {
    return (_db.update(_db.quests)..where((q) => q.id.equals(quest.id))).write(
      QuestsCompanion(
        title: Value(quest.title),
        icon: Value(quest.icon),
        coins: Value(quest.coins),
        repeatRule: Value(quest.repeatRule),
        days: Value(quest.days),
        dueLabel: Value(quest.dueLabel),
        needsApproval: Value(quest.needsApproval),
        assigneeChildId: Value(quest.assigneeChildId),
        active: Value(quest.active),
      ),
    );
  }

  @override
  Future<void> deleteQuest(String id) {
    return (_db.delete(_db.quests)..where((q) => q.id.equals(id))).go();
  }

  List<domain.Quest> _toEntities(List<Quest> rows) =>
      rows.map(_toEntity).toList();

  domain.Quest _toEntity(Quest row) {
    return domain.Quest(
      id: row.id,
      title: row.title,
      detail: _detail(row),
      icon: row.icon,
      coins: row.coins,
      repeatRule: row.repeatRule,
      days: row.days,
      dueLabel: row.dueLabel,
      needsApproval: row.needsApproval,
      assigneeChildId: row.assigneeChildId,
      active: row.active,
    );
  }

  static String _detail(Quest row) {
    final repeat = switch (row.repeatRule) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      _ => 'Once',
    };
    return '$repeat · ${row.coins} coins';
  }

  /// P10 "Ideas" templates: name, icon, suggested coins, suggested age band.
  static const List<domain.Quest> _ideas = <domain.Quest>[
    domain.Quest(
      id: 'idea-bed',
      title: 'Make your bed',
      detail: '5 coins · age 4+',
      icon: 'bed',
      coins: 5,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-table',
      title: 'Lay the table',
      detail: '10 coins · age 5+',
      icon: 'plate',
      coins: 10,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-bins',
      title: 'Put the bins out',
      detail: '15 coins · age 8+',
      icon: 'bins',
      coins: 15,
      repeatRule: 'weekly',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-dishwasher',
      title: 'Empty the dishwasher',
      detail: '15 coins · age 7+',
      icon: 'dishwasher',
      coins: 15,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-hoover',
      title: 'Hoover the stairs',
      detail: '20 coins · age 9+',
      icon: 'hoover',
      coins: 20,
      repeatRule: 'weekly',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-pet',
      title: 'Feed the pet',
      detail: '5 coins · age 4+',
      icon: 'paw',
      coins: 5,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-bag',
      title: 'Pack school bag',
      detail: '5 coins · age 5+',
      icon: 'bag',
      coins: 5,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-plants',
      title: 'Water the plants',
      detail: '10 coins · age 5+',
      icon: 'leaf',
      coins: 10,
      repeatRule: 'weekly',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-washing',
      title: 'Help with the washing',
      detail: '15 coins · age 7+',
      icon: 'shirt',
      coins: 15,
      repeatRule: 'weekly',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
    domain.Quest(
      id: 'idea-reading',
      title: 'Read for 20 minutes',
      detail: '10 coins · age 5+',
      icon: 'book',
      coins: 10,
      repeatRule: 'daily',
      days: '',
      dueLabel: null,
      needsApproval: true,
      assigneeChildId: null,
      active: false,
    ),
  ];
}
