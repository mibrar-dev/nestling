import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

enum KidHomeStatus { initial, loading, loaded, failure }

final class KidHomeState extends Equatable {
  const new({
    this.status = KidHomeStatus.initial,
    this.child,
    this.items = const <KidQuest>[],
    this.errorMessage,
    this.actionError,
  });

  final KidHomeStatus status;

  /// The child currently playing (null when no active child in kid mode).
  final KidChild? child;
  final List<KidQuest> items;
  final String? errorMessage;

  /// Last `completeQuest` failure; the list stays visible and a SnackBar
  /// explains it. Never used for the load failure path.
  final String? actionError;

  /// Done = `approved` + `done_pending` (live counts from the DB).
  int get doneCount => items
      .where((q) => q.status == 'approved' || q.status == 'done_pending')
      .length;

  int get totalCount => items.length;

  double get fraction => totalCount == 0 ? 0 : doneCount / totalCount;

  KidHomeState copyWith({
    KidHomeStatus? status,
    List<KidQuest>? items,
    String? errorMessage,
    String? actionError,
  }) {
    return KidHomeState(
      status: status ?? this.status,
      child: child,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      actionError: actionError ?? this.actionError,
    );
  }

  /// Loaded emission from the combined child + items streams. Built
  /// explicitly (not via [copyWith]) so a null child clears the previous one.
  KidHomeState copyWithLoaded({
    required KidChild? child,
    required List<KidQuest> items,
  }) {
    return KidHomeState(
      status: KidHomeStatus.loaded,
      child: child,
      items: items,
      errorMessage: errorMessage,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    child,
    items,
    errorMessage,
    actionError,
  ];
}
