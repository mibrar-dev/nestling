import 'package:nestling/features/approvals/domain/entities/approval.dart';

class ApprovalModel extends Approval {
  const new({required super.id, required super.title, required super.detail});

  factory fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
