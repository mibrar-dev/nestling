import 'package:equatable/equatable.dart';

// One family row for P16 Settings (Family section): the raw `members` row in
// insertion order (Sarah then James). Display copy ("Sarah — you",
// "Invited · awaiting reply") is the view's job.
class SettingsMemberEntry extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.role,
    required this.inviteStatus,
    this.email,
  });

  final String id;
  final String name;

  /// `owner` | `co-parent`.
  final String role;

  /// `active` | `invited`.
  final String inviteStatus;

  /// `members.email` (schema v7, nullable). Null for an invited co-parent,
  /// which shows its invite status instead — DATA OVER MOCKS: the owner row
  /// subtitle is read from the database, never hard-coded.
  final String? email;

  @override
  List<Object?> get props => <Object?>[id, name, role, inviteStatus, email];
}
