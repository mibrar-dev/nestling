import 'package:nestling/features/approvals/data/models/approval_model.dart';

class ApprovalsFakeDataSource {
  const new();

  List<ApprovalModel> getItems() {
    return const <ApprovalModel>[
      ApprovalModel(
        id: 'approval-1',
        title: 'Empty the dishwasher',
        detail: 'Maya, 15 coins, today 8:12am',
      ),
      ApprovalModel(
        id: 'approval-2',
        title: 'Make your bed',
        detail: 'Leo, 5 coins',
      ),
      ApprovalModel(
        id: 'approval-3',
        title: 'Feed Biscuit the cat',
        detail: 'Leo, 5 coins',
      ),
    ];
  }
}
