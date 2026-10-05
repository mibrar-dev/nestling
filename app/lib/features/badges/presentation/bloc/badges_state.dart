import 'package:equatable/equatable.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';

enum BadgesStatus { initial, loading, loaded, failure }

final class BadgesState extends Equatable {
  const BadgesState({
    this.status = BadgesStatus.initial,
    this.childId = '',
    this.items = const <Badge>[],
    this.happyDays = 0,
    this.errorMessage,
  });

  final BadgesStatus status;

  /// The active child the shelf is showing ('' until the first stream
  /// emission, so nothing can act without a resolved child).
  final String childId;

  /// Badges in DB insertion order (the K11 grid order, never sorted).
  final List<Badge> items;

  /// Happy days this week (0..7), framed positively — never a lost streak.
  final int happyDays;

  final String? errorMessage;

  bool get isLoaded => status == BadgesStatus.loaded;

  BadgesState copyWith({
    BadgesStatus? status,
    String? childId,
    List<Badge>? items,
    int? happyDays,
    String? errorMessage,
  }) {
    return BadgesState(
      status: status ?? this.status,
      childId: childId ?? this.childId,
      items: items ?? this.items,
      happyDays: happyDays ?? this.happyDays,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Loading emission for a (re)load. Built explicitly so a retry starts
  /// clean: a stale load error never rides into the spinner (review
  /// finding 4). The last known child/shelf/count ride through untouched;
  /// only failure-path behaviour is unchanged.
  BadgesState copyWithLoading() {
    return BadgesState(
      status: BadgesStatus.loading,
      childId: childId,
      items: items,
      happyDays: happyDays,
    );
  }

  /// Loaded emission from the badges stream. Built explicitly so a healthy
  /// emission also clears a stale load error. (No request actions exist on
  /// this screen, so there is nothing else to ride through.)
  BadgesState copyWithLoaded({
    required String childId,
    required List<Badge> items,
    required int happyDays,
  }) {
    return BadgesState(
      status: BadgesStatus.loaded,
      childId: childId,
      items: items,
      happyDays: happyDays,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    childId,
    items,
    happyDays,
    errorMessage,
  ];
}
