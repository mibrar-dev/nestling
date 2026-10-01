import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

abstract class PipRepository {
  Future<List<PipStage>> getItems();
}
