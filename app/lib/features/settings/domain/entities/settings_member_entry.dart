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
  });

  final String id;
  final String name;

  /// `owner` | `co-parent`.
  final String role;

  /// `active` | `invited`.
  final String inviteStatus;

  @override
  List<Object?> get props => <Object?>[id, name, role, inviteStatus];
}
