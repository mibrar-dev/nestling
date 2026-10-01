import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';

class PaywallPlanModel extends PaywallPlan {
  const new({required super.id, required super.title, required super.detail});

  factory PaywallPlanModel.fromJson(Map<String, dynamic> json) {
    return PaywallPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
