import 'package:equatable/equatable.dart';

// One privacy promise row (P04). The crash-reports row carries the live
// toggle state; the rest are static reassurances.
class ConsentOption extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.enabled,
  });

  final String id;
  final String title;
  final String detail;
  final bool enabled;

  @override
  List<Object?> get props => <Object?>[id, title, detail, enabled];
}

/// Row ids for the consent options. The bloc finds the live crash row by
/// [crash]; a shared const keeps that dependency from silently rotting.
abstract final class ConsentOptionIds {
  const new _();

  static const String crash = 'crash';
}
