import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';

abstract class ParentalGateRepository {
  Future<List<ParentalGateChallenge>> getItems();
}
