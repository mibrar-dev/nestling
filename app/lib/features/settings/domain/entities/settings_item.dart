import 'package:equatable/equatable.dart';

// One settings row (P16). `detail` carries the live value
// ("Nestling Annual · renews 18 Oct 2027", "On", …).
class SettingsItem extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.enabled,
  });

  final String id;
  final String title;
  final String detail;

  /// Toggle state for switch rows; true for plain navigation rows.
  final bool enabled;

  @override
  List<Object?> get props => <Object?>[id, title, detail, enabled];
}
