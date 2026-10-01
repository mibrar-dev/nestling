import 'package:equatable/equatable.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';

enum PaywallStatus { initial, loading, loaded, failure }

final class PaywallState extends Equatable {
  const new({
    this.status = PaywallStatus.initial,
    this.items = const <PaywallPlan>[],
    this.errorMessage,
  });

  final PaywallStatus status;
  final List<PaywallPlan> items;
  final String? errorMessage;

  PaywallState copyWith({
    PaywallStatus? status,
    List<PaywallPlan>? items,
    String? errorMessage,
  }) {
    return PaywallState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
