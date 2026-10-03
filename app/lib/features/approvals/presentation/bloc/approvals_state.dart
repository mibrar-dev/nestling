import 'package:equatable/equatable.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

enum ApprovalsStatus { initial, loading, loaded, failure }

/// Which per-card decision is in flight for one completion id (BUG-P11-4:
/// plan §1 says `loading: true` only on the tapped button, so the state
/// must remember WHICH button was tapped, not just that the card is busy).
enum ApprovalsDecision { approve, notYet }

final class ApprovalsState extends Equatable {
  const new({
    this.status = ApprovalsStatus.initial,
    this.items = const <Approval>[],
    this.errorMessage,
    this.busyIds = const <int>{},
    this.busyActions = const <int, ApprovalsDecision>{},
    this.approveAllBusy = false,
    this.actionError,
  });

  final ApprovalsStatus status;
  final List<Approval> items;
  final String? errorMessage;

  /// Completion ids with an approve / not-yet write in flight. Kept equal
  /// to `busyActions.keys` (the bloc updates both together); retained so
  /// existing readers keep compiling while the card migrates to
  /// per-button loading via [busyActions].
  final Set<int> busyIds;

  /// In-flight per-card decision by completion id. The card renders
  /// `loading: true` (and disabled) only on the tapped button:
  /// `busyActions[id] == ApprovalsDecision.approve` spins Approve,
  /// `== ApprovalsDecision.notYet` spins Not yet.
  final Map<int, ApprovalsDecision> busyActions;

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
    Map<int, ApprovalsDecision>? busyActions,
    bool? approveAllBusy,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ApprovalsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      busyIds: busyIds ?? this.busyIds,
      busyActions: busyActions ?? this.busyActions,
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
    busyActions,
    approveAllBusy,
    actionError,
  ];
}
