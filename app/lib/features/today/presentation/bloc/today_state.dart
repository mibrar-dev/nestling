import 'package:equatable/equatable.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';

enum TodayStatus { initial, loading, loaded, failure }

final class TodayState extends Equatable {
  const new({
    this.status = TodayStatus.initial,
    this.items = const <TodayItem>[],
    this.errorMessage,
  });

  final TodayStatus status;
  final List<TodayItem> items;
  final String? errorMessage;

  TodayState copyWith({
    TodayStatus? status,
    List<TodayItem>? items,
    String? errorMessage,
  }) {
    return TodayState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
