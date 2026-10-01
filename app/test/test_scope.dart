// Shared widget-test scope for foundation tests.
//
// Opens an in-memory Drift database, registers it (plus every feature) in
// GetIt and optionally seeds `Seed.demo()`. Call in `setUp`; call
// `GetIt.instance.reset()` in the NEXT `setUp` before reusing.
//
// Databases are deliberately NOT closed: [AppSession] keeps a live watch
// subscription, and closing its database would surface stream errors after
// the test ends. In-memory databases die with the test process.

import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';

Future<AppDatabase> setUpTestScope({bool seedDemo = true}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  if (seedDemo) {
    await Seed.demo(db);
    await GetIt.instance<AppSession>().refresh();
  }
  return db;
}
