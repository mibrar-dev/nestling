import 'package:nestling/features/design_system_gallery/domain/entities/design_system_item.dart';

class DesignSystemItemModel extends DesignSystemItem {
  const new({required super.id, required super.title, required super.detail});

  factory fromJson(Map<String, dynamic> json) {
    return DesignSystemItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
