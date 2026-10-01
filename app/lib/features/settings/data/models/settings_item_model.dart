import 'package:nestling/features/settings/domain/entities/settings_item.dart';

class SettingsItemModel extends SettingsItem {
  const new({required super.id, required super.title, required super.detail});

  factory fromJson(Map<String, dynamic> json) {
    return SettingsItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
