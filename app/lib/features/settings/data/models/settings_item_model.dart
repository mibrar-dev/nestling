import 'package:nestling/features/settings/domain/entities/settings_item.dart';

class SettingsItemModel extends SettingsItem {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.enabled,
  });

  factory SettingsItemModel.fromJson(Map<String, dynamic> json) {
    return SettingsItemModel(
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
