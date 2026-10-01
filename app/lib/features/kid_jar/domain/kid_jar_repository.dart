import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';

abstract class KidJarRepository {
  Future<List<JarEntry>> getItems();
}
