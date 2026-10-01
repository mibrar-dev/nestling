import 'package:equatable/equatable.dart';

// A grown-up on the family account: owner (Sarah) or invited co-parent.
class FamilyMember extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.name,
    required this.role,
    required this.inviteStatus,
  });

  final String id;

  /// Display name.
  final String title;

  /// "You" / "Co-parent · invited" style subtitle.
  final String detail;
  final String name;

  /// `owner | co-parent`.
  final String role;

  /// `active | invited`.
  final String inviteStatus;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    name,
    role,
    inviteStatus,
  ];
}
