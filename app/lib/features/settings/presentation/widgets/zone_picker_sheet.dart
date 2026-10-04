import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/widgets/settings_rows.dart';

/// Curated zone list from ORCHESTRATOR_NOTES. Raw IANA ids appear only in
/// the picker's row subtitles — never on the settings list itself.
const List<String> kSettingsZoneChoices = <String>[
  'Europe/London',
  'Europe/Paris',
  'America/New_York',
  'Asia/Dubai',
  'Asia/Karachi',
  'Australia/Sydney',
];

/// `{short label} ({GMT±n})` for the Time zone row, e.g. `London (GMT+1)`.
String settingsZoneSummary(String zoneId, DateTime nowUtc) =>
    '${shortZoneLabel(zoneId)} (${gmtOffsetLabel(zoneId, nowUtc)})';

/// Opens the time-zone picker sheet (no route — the picker is in-place).
Future<void> openZonePickerSheet(BuildContext context) {
  final bloc = context.read<SettingsBloc>();
  return showNestBottomSheet<void>(
    context,
    title: 'Time zone',
    child: BlocProvider<SettingsBloc>.value(
      value: bloc,
      child: const _ZonePickerList(),
    ),
  );
}

class _ZonePickerList extends StatelessWidget {
  const _ZonePickerList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsBloc>().state;
    final familyZone = state.familyZoneId;
    // Device zone comes from its own field (kept after a banner dismissal);
    // `pendingZone` is the banner-only input and is null once dismissed.
    final device = state.deviceZoneId;
    final rows = <String>[
      if (device != null && device != familyZone) device,
      for (final id in kSettingsZoneChoices)
        if (id != device || id == familyZone) id,
    ];
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final id in rows)
              _ZoneRow(
                zoneId: id,
                isDevice: id == device && id != familyZone,
                isCurrent: id == familyZone,
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zoneId,
    required this.isDevice,
    required this.isCurrent,
  });

  final String zoneId;
  final bool isDevice;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final subtitle = isDevice
        ? '$zoneId · Current location'
        : '$zoneId · ${gmtOffsetLabel(zoneId, appNowUtc())}';
    return SettingsRow(
      title: shortZoneLabel(zoneId),
      subtitle: subtitle,
      trailing: isCurrent
          ? NestIcon(NestIcons.check, color: tokens.leaf)
          : null,
      onTap: () {
        context.read<SettingsBloc>().add(SettingsTimeZonePicked(zoneId));
        Navigator.of(context).pop();
      },
    );
  }
}
