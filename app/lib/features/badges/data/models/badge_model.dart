import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;

class BadgeModel extends domain.Badge {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.icon,
    required super.description,
    required super.earned,
    required super.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      earned: json['earned'] as bool,
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'icon': icon,
      'description': description,
      'earned': earned,
      'earnedAt': earnedAt?.toIso8601String(),
    };
  }
}
