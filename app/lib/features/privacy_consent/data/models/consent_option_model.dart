import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

class ConsentOptionModel extends ConsentOption {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.enabled,
  });

  factory ConsentOptionModel.fromJson(Map<String, dynamic> json) {
    return ConsentOptionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      enabled: json['enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'enabled': enabled,
    };
  }
}
