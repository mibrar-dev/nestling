import 'package:equatable/equatable.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

enum ApprovalsStatus { initial, loading, loaded, failure }

final class ApprovalsState extends Equatable {
  const new({
    this.status = ApprovalsStatus.initial,
    this.items = const <Approval>[],
    this.errorMessage,
  });

  final ApprovalsStatus status;
  final List<Approval> items;
  final String? errorMessage;

  ApprovalsState copyWith({
    ApprovalsStatus? status,
    List<Approval>? items,
    String? errorMessage,
  }) {
    return ApprovalsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
