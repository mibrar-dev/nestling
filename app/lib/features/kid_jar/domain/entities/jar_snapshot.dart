import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';

/// One atomic K09 snapshot: the active child's money-in list plus the jar
/// summary (owed figure, savings goal, payout weekday). The bloc renders a
/// single [JarSnapshot] emission so the list and the hero amount can never
/// disagree mid-frame.
class JarSnapshot extends Equatable {
  const new({
    required this.childId,
    required this.items,
    required this.summary,
  });

  final String childId;

  /// Money-in rows only (`weekly_base`, `quest_bonus`, `gift`), newest first.
  final List<JarEntry> items;
  final JarSummary summary;

  @override
  List<Object?> get props => <Object?>[childId, items, summary];
}

/// K09 history value: positive amounts read `+£3.80` at/above £1 and `+12p`
/// below it. Negatives never reach the K09 list (only money-in rows do); the
/// U+2212 minus branch (`−£2.00`) exists so a future caller cannot render a
/// hyphen-minus amount by accident.
String formatJarAmount(int pence) {
  final sign = pence < 0 ? '−' : '+';
  final abs = pence.abs();
  if (abs >= 100) {
    return '$sign£${(abs / 100).toStringAsFixed(2)}';
  }
  return '$sign${abs}p';
}
