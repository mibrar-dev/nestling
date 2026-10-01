import 'package:nestling/features/parental_gate/data/models/parental_gate_challenge_model.dart';

class ParentalGateFakeDataSource {
  const new();

  List<ParentalGateChallengeModel> getItems() {
    return const <ParentalGateChallengeModel>[
      ParentalGateChallengeModel(
        id: 'challenge-1',
        title: 'Seven times six',
        detail: 'Answer 42',
      ),
      ParentalGateChallengeModel(
        id: 'challenge-2',
        title: 'Nine plus eight',
        detail: 'Answer 17',
      ),
    ];
  }
}
