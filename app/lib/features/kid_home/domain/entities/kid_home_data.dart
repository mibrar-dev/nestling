import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

// One emission of the kid-home screen (K01–K05 share the bloc): the active
// child plus their quests, delivered in a single stream so the bloc watches
// the child row exactly once per load (review finding 4, iteration 5).
class KidHomeData extends Equatable {
  const new({required this.child, this.items = const <KidQuest>[]});

  /// Null when kid mode has no active child (empty picker state).
  final KidChild? child;
  final List<KidQuest> items;

  @override
  List<Object?> get props => <Object?>[child, items];
}
