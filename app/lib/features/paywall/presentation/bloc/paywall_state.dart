import 'package:equatable/equatable.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';

enum PaywallStatus { initial, loading, loaded, failure }

/// The trial/restore action state. `status` drives the scroll body;
/// `action` drives only the CTA button and the one-shot navigation.
enum PaywallAction { idle, working, success, failure }

/// Which request the current [PaywallAction] belongs to. Trial and restore
/// need different session writes (restore must never call `startTrialNow()`,
/// which would regress an `active` subscription back to `trial`), so the
/// view reads this alongside `action` on success.
enum PaywallRequest { none, trial, restore }

final class PaywallState extends Equatable {
  const new({
    this.status = PaywallStatus.initial,
    this.items = const <PaywallPlan>[],
    this.errorMessage,
    this.action = PaywallAction.idle,
    this.request = PaywallRequest.none,
    this.coParentName,
  });

  final PaywallStatus status;
  final List<PaywallPlan> items;
  final String? errorMessage;
  final PaywallAction action;
  final PaywallRequest request;

  /// Display name of the family's co-parent for benefit 4, read one-shot
  /// at load (shared_batch3). Null → the "everyone sees the same" fallback.
  final String? coParentName;

  PaywallState copyWith({
    PaywallStatus? status,
    List<PaywallPlan>? items,
    String? errorMessage,
    PaywallAction? action,
    PaywallRequest? request,
    String? coParentName,
    bool clearError = false,
    bool clearCoParent = false,
  }) {
    return PaywallState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      action: action ?? this.action,
      request: request ?? this.request,
      // Like [clearError]: a fresh load replaces the name (possibly with
      // null) instead of keeping a stale one across a retry.
      coParentName: clearCoParent
          ? coParentName
          : (coParentName ?? this.coParentName),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    errorMessage,
    action,
    request,
    coParentName,
  ];
}
