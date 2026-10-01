import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

class PipStageModel extends PipStage {
  const new({required super.id, required super.title, required super.detail});

  factory fromJson(Map<String, dynamic> json) {
    return PipStageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
