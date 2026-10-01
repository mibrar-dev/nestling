import 'package:equatable/equatable.dart';

// The family account (P03). Local-only: children never need an email;
// the grown-up's member row is the account.
class AuthAccount extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.name,
    required this.role,
  });

  final String id;

  /// Display name.
  final String title;

  /// "Owner" / "Co-parent" style subtitle.
  final String detail;
  final String name;
  final String role;

  @override
  List<Object?> get props => <Object?>[id, title, detail, name, role];
}
