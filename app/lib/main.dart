import 'package:flutter/material.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/app/launch.dart';
import 'package:nestling/core/data/family_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IANA tz database (`latest_10y`) for family-zone math (periods, history
  // labels). Pure-Dart load; safe before DI.
  initFamilyTime();
  await configureDependencies();
  final initialRoute = await applyLaunchFlags();
  runApp(NestlingApp(initialRoute: initialRoute));
}
