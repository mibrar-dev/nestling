import 'package:equatable/equatable.dart';

// A badge on the K11 shelf: earned badges are colourful, unearned ones are
// soft outlines with "Keep going!" — never framed as locked.
class Badge extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.description,
    required this.earned,
    required this.earnedAt,
  });

  final String id;
  final String title;
  final String detail;
  final String icon;
  final String description;
  final bool earned;
  final DateTime? earnedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    icon,
    description,
    earned,
    earnedAt,
  ];
}
