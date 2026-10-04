import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';

class JarEntryModel extends JarEntry {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.type,
    required super.amountPence,
    required super.date,
    super.iconKey = '',
  });

  factory JarEntryModel.fromJson(Map<String, dynamic> json) {
    return JarEntryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      type: json['type'] as String,
      amountPence: json['amountPence'] as int,
      date: DateTime.parse(json['date'] as String),
      iconKey: json['iconKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'type': type,
      'amountPence': amountPence,
      'date': date.toIso8601String(),
      'iconKey': iconKey,
    };
  }
}
