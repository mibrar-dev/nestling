import 'package:equatable/equatable.dart';

// A quest card in kid mode (K03, K04): big icon, coin reward and the child's
// progress state. Only coins are shown — never £.
class KidQuest extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.questId,
    required this.icon,
    required this.coins,
    required this.status,
    this.needsApproval = true,
  });

  final String id;
  final String title;
  final String detail;
  final String questId;
  final String icon;
  final int coins;

  /// `to_do | done_pending | approved | not_yet`.
  final String status;

  /// ROW META (orchestrator ruling 04:52): whether a done quest needs a
  /// parent's thumbs-up. Waiting + needs approval → `Waiting for Mum`;
  /// approved + needed approval → `Mum said yes!`; done + no approval →
  /// the `+N` coin chip. Mirrors `quests.needs_approval` (DB default true,
  /// same default here so existing constructions keep their meaning).
  final bool needsApproval;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    questId,
    icon,
    coins,
    status,
    needsApproval,
  ];
}
