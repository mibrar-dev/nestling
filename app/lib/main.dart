import 'package:flutter/material.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/app/launch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final initialRoute = await applyLaunchFlags();
  runApp(NestlingApp(initialRoute: initialRoute));
}
