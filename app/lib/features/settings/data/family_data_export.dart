// Nestling — "Download our data" local export (shared/release_prep).
//
// Builds the family's data as a JSON-ready map (P16 Settings row), writes
// it to a temp `nestling-export-<date>.json` file and opens the OS share
// sheet (`share_plus`). Everything stays on-device; no backend.
//
// PIN hashes are never exported: the child's `pinHash` column is dropped.
// Timestamps render as UTC ISO-8601 strings alongside the family zone id so
// the file is self-describing.
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Builds the export document for [familyId]: family, members, children
/// (without PIN hashes), quests, completions, ledger, goals, rewards, badges
/// earned and settings — plus the family zone and ISO timestamps.
Future<Map<String, dynamic>> buildFamilyExport(
  AppDatabase db, [
  String familyId = CurrentFamily.fallbackId,
]) async {
  String iso(DateTime instant) => instant.toUtc().toIso8601String();
  String? isoOrNull(DateTime? instant) => instant?.toUtc().toIso8601String();

  final zone = await db.familyZoneId(familyId);
  final family = await (db.select(
    db.families,
  )..where((f) => f.id.equals(familyId))).getSingleOrNull();
  final members = await (db.select(
    db.members,
  )..where((m) => m.familyId.equals(familyId))).get();
  final children = await (db.select(
    db.children,
  )..where((c) => c.familyId.equals(familyId))).get();
  final quests = await (db.select(
    db.quests,
  )..where((q) => q.familyId.equals(familyId))).get();
  final completions = await (db.select(
    db.questCompletions,
  )..where((c) => c.familyId.equals(familyId))).get();
  final ledger = await (db.select(
    db.ledgerEntries,
  )..where((l) => l.familyId.equals(familyId))).get();
  final goals = await (db.select(
    db.savingsGoals,
  )..where((g) => g.familyId.equals(familyId))).get();
  final rewards = await (db.select(
    db.rewards,
  )..where((r) => r.familyId.equals(familyId))).get();
  final earned = await (db.select(
    db.earnedBadges,
  )..where((e) => e.familyId.equals(familyId))).get();
  final badges = await db.select(db.badges).get();
  final settings = await (db.select(
    db.settings,
  )..where((s) => s.familyId.equals(familyId))).getSingleOrNull();
  final badgeById = <String, Badge>{for (final b in badges) b.id: b};

  return <String, dynamic>{
    'meta': <String, dynamic>{
      'exportedAt': iso(clock.now().toUtc()),
      'familyZone': normalizeZoneId(zone),
      'app': 'nestling',
    },
    'family': family == null
        ? null
        : <String, dynamic>{
            'id': family.id,
            'name': family.name,
            'payoutDay': family.payoutDay,
            'coinValuePencePerCoin': family.coinValuePencePerCoin,
            'pocketMoneyMode': family.pocketMoneyMode,
            'timeZone': family.timeZone,
            'updatedAt': isoOrNull(family.updatedAt),
            'updatedAtTz': family.updatedAtTz,
          },
    'members': <Map<String, dynamic>>[
      for (final m in members)
        <String, dynamic>{
          'id': m.id,
          'name': m.name,
          'role': m.role,
          'inviteStatus': m.inviteStatus,
          'email': m.email,
        },
    ],
    // No PIN hashes: `pinHash` is deliberately dropped (P16 export rule).
    'children': <Map<String, dynamic>>[
      for (final c in children)
        <String, dynamic>{
          'id': c.id,
          'nickname': c.nickname,
          'ageBand': c.ageBand,
          'ageYears': c.ageYears,
          'avatarColour': c.avatarColour,
          'pipStyle': c.pipStyle,
          'pipSkin': c.pipSkin,
          'pipAccessory': c.pipAccessory,
          'pipStage': c.pipStage,
          'pipTotalCoins': c.pipTotalCoins,
          'coins': c.coins,
          'happiness': c.happiness,
          'happyDays': c.happyDays,
          'weeklyBasePence': c.weeklyBasePence,
          'createdAt': iso(c.createdAt),
          'createdAtTz': c.createdAtTz,
        },
    ],
    'quests': <Map<String, dynamic>>[
      for (final q in quests)
        <String, dynamic>{
          'id': q.id,
          'title': q.title,
          'icon': q.icon,
          'coins': q.coins,
          'repeatRule': q.repeatRule,
          'days': q.days,
          'dueLabel': q.dueLabel,
          'dueTimeLocal': q.dueTimeLocal,
          'needsApproval': q.needsApproval,
          'assigneeChildId': q.assigneeChildId,
          'active': q.active,
          'createdAt': iso(q.createdAt),
          'createdAtTz': q.createdAtTz,
        },
    ],
    'completions': <Map<String, dynamic>>[
      for (final c in completions)
        <String, dynamic>{
          'id': c.id,
          'questId': c.questId,
          'childId': c.childId,
          'status': c.status,
          'coins': c.coins,
          'createdAt': iso(c.createdAt),
          'createdAtTz': c.createdAtTz,
          'decidedAt': isoOrNull(c.decidedAt),
          'decidedAtTz': c.decidedAtTz,
          'kidNote': c.kidNote,
        },
    ],
    'ledger': <Map<String, dynamic>>[
      for (final l in ledger)
        <String, dynamic>{
          'id': l.id,
          'childId': l.childId,
          'type': l.type,
          'amountPence': l.amountPence,
          'note': l.note,
          'date': iso(l.date),
          'dateTz': l.dateTz,
        },
    ],
    'goals': <Map<String, dynamic>>[
      for (final g in goals)
        <String, dynamic>{
          'id': g.id,
          'childId': g.childId,
          'title': g.title,
          'targetPence': g.targetPence,
          'savedPence': g.savedPence,
        },
    ],
    'rewards': <Map<String, dynamic>>[
      for (final r in rewards)
        <String, dynamic>{
          'id': r.id,
          'title': r.title,
          'icon': r.icon,
          'coinPrice': r.coinPrice,
          'needsOk': r.needsOk,
          'createdAt': iso(r.createdAt),
          'createdAtTz': r.createdAtTz,
        },
    ],
    'badgesEarned': <Map<String, dynamic>>[
      for (final e in earned)
        <String, dynamic>{
          'id': e.id,
          'badgeId': e.badgeId,
          'badgeTitle': badgeById[e.badgeId]?.title,
          'childId': e.childId,
          'earnedAt': iso(e.earnedAt),
          'earnedAtTz': e.earnedAtTz,
        },
    ],
    'settings': settings == null
        ? null
        : <String, dynamic>{
            'pocketMoneyMode': settings.pocketMoneyMode,
            'payoutDay': settings.payoutDay,
            'coinValuePencePerCoin': settings.coinValuePencePerCoin,
            'notifApprovals': settings.notifApprovals,
            'notifPayout': settings.notifPayout,
            'notifSummary': settings.notifSummary,
            'crashReportConsent': settings.crashReportConsent,
            'kidGateEnabled': settings.kidGateEnabled,
            'timeZone': settings.timeZone,
            'updatedAt': isoOrNull(settings.updatedAt),
            'updatedAtTz': settings.updatedAtTz,
          },
  };
}

/// Temp-file name for the export, e.g. `nestling-export-2026-10-03.json` —
/// the date (not the clock time) keeps the name stable and id-derived ids
/// never appear in it (IDS rule).
String exportFileName(DateTime nowUtc) {
  final day = nowUtc.toUtc();
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return 'nestling-export-$y-$m-$d.json';
}

/// Writes [document] as pretty JSON to a temp file and returns it.
Future<File> writeExportToTempFile(Map<String, dynamic> document) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${exportFileName(clock.now().toUtc())}');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(document),
  );
  return file;
}

/// Test seam for opening the OS share sheet: product code passes nothing
/// (→ `SharePlus.instance.share`); tests inject a recorder and assert the
/// shared file without opening a sheet.
typedef ShareExportFn = Future<void> Function(XFile file);

/// Opens the OS share sheet for the given file (see [ShareExportFn]).
Future<void> shareExportFile(File file, {ShareExportFn? shareFn}) {
  final share =
      shareFn ??
      (XFile f) async {
        await SharePlus.instance.share(ShareParams(files: <XFile>[f]));
      };
  return share(XFile(file.path));
}
