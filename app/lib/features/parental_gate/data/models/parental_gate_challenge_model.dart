import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';

class ParentalGateChallengeModel extends ParentalGateChallenge {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.a,
    required super.b,
  });

  factory ParentalGateChallengeModel.fromJson(Map<String, dynamic> json) {
    return ParentalGateChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      a: json['a'] as int,
      b: json['b'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'a': a,
      'b': b,
    };
  }
}
