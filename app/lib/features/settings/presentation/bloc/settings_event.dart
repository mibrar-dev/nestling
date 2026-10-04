import 'package:equatable/equatable.dart';

sealed class SettingsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class SettingsLoadRequested extends SettingsEvent {
  const new();
}

/// One of the three P16 notification toggles flipped. Null fields keep
/// their stored value; the `watchSettings` stream re-emits after the write
/// and the loaded state follows (house pattern: no state emission here).
final class SettingsNotificationsChanged extends SettingsEvent {
  const new({this.approvals, this.payout, this.summary});

  final bool? approvals;
  final bool? payout;
  final bool? summary;

  @override
  List<Object?> get props => <Object?>[approvals, payout, summary];
}

/// A time-zone picker choice. Unknown ids are ignored by the service (no
/// stream change, no state change); a valid id mirrors into
/// `settings.time_zone` and the zone streams re-emit.
final class SettingsTimeZonePicked extends SettingsEvent {
  const new(this.zoneId);

  final String zoneId;

  @override
  List<Object?> get props => <Object?>[zoneId];
}

/// The move banner's "Switch": stores the device zone as the family zone.
/// History keeps its stored zones; future periods follow the new zone. The
/// zone streams re-emit and the banner clears itself.
final class SettingsMoveConfirmed extends SettingsEvent {
  const new();
}

/// The move banner's "Not now": session-local dismissal for [zone] (bloc
/// state only, never the database). The banner stays hidden for that zone
/// until the route is rebuilt.
final class SettingsMoveDismissed extends SettingsEvent {
  const new(this.zone);

  final String zone;

  @override
  List<Object?> get props => <Object?>[zone];
}
