import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';

/// Parental gate (P17), backed by Drift for the on/off switch in `settings`.
/// The challenge itself is derived from the date (stable all day).
abstract class ParentalGateRepository {
  Future<List<ParentalGateChallenge>> getItems();
  Stream<List<ParentalGateChallenge>> watchItems();

  Stream<bool> watchGateEnabled();
  Future<void> setGateEnabled({required bool enabled});

  /// Today's challenge. Tests pass an explicit date.
  ParentalGateChallenge challengeFor(DateTime utc);
}
