import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

class PipStageModel extends PipStage {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.owned,
    required super.priceCoins,
  });

  factory PipStageModel.fromJson(Map<String, dynamic> json) {
    return PipStageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      owned: json['owned'] as bool,
      priceCoins: json['priceCoins'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'owned': owned,
      'priceCoins': priceCoins,
    };
  }
}
