import 'package:equatable/equatable.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';

enum BadgesStatus { initial, loading, loaded, failure }

final class BadgesState extends Equatable {
  const new({
    this.status = BadgesStatus.initial,
    this.items = const <Badge>[],
    this.errorMessage,
  });

  final BadgesStatus status;
  final List<Badge> items;
  final String? errorMessage;

  BadgesState copyWith({
    BadgesStatus? status,
    List<Badge>? items,
    String? errorMessage,
  }) {
    return BadgesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
