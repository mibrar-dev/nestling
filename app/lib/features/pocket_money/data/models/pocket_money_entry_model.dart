import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';

class PocketMoneyEntryModel extends PocketMoneyEntry {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.childId,
    required super.type,
    required super.amountPence,
    required super.note,
    required super.date,
    super.dateTz,
  });

  factory PocketMoneyEntryModel.fromJson(Map<String, dynamic> json) {
    return PocketMoneyEntryModel(
      id: json['id'] as int,
      title: json['title'] as String,
      detail: json['detail'] as String,
      childId: json['childId'] as String,
      type: json['type'] as String,
      amountPence: json['amountPence'] as int,
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
      dateTz: json['dateTz'] as String? ?? 'Europe/London',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'childId': childId,
      'type': type,
      'amountPence': amountPence,
      'note': note,
      'date': date.toIso8601String(),
      'dateTz': dateTz,
    };
  }
}
