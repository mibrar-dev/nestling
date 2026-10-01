import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

enum PipStatus { initial, loading, loaded, failure }

final class PipState extends Equatable {
  const new({
    this.status = PipStatus.initial,
    this.items = const <PipStage>[],
    this.errorMessage,
  });

  final PipStatus status;
  final List<PipStage> items;
  final String? errorMessage;

  PipState copyWith({
    PipStatus? status,
    List<PipStage>? items,
    String? errorMessage,
  }) {
    return PipState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
