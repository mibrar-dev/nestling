import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

abstract class KidHomeRepository {
  Future<List<KidQuest>> getItems();
}
