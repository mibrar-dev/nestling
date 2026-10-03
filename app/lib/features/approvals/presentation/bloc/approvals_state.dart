import 'package:equatable/equatable.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

enum ApprovalsStatus { initial, loading, loaded, failure }

final class ApprovalsState extends Equatable {
  const new({
    this.status = ApprovalsStatus.initial,
    this.items = const <Approval>[],
    this.errorMessage,
    this.busyIds = const <int>{},
    this.approveAllBusy = false,
    this.actionError,
  });

  final ApprovalsStatus status;
  final List<Approval> items;
  final String? errorMessage;

  /// Completion ids with an approve / not-yet write in flight. The card
  /// buttons for these ids render loading + disabled.
  final Set<int> busyIds;

  /// True while an approve-all write is in flight (bottom CTA loading).
  final bool approveAllBusy;

  /// Last action (approve / not-yet / approve-all) failure. The view shows
  /// it once in a SnackBar, then adds ApprovalsActionErrorConsumed.
  /// Cleared with `clearActionError: true` because `actionError: null`
  /// means "leave unchanged".
  final String? actionError;

  ApprovalsState copyWith({
    ApprovalsStatus? status,
    List<Approval>? items,
    String? errorMessage,
    Set<int>? busyIds,
    bool? approveAllBusy,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ApprovalsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      busyIds: busyIds ?? this.busyIds,
      approveAllBusy: approveAllBusy ?? this.approveAllBusy,
      actionError: clearActionError ? null : actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    errorMessage,
    busyIds,
    approveAllBusy,
    actionError,
  ];
}
