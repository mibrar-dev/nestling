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
